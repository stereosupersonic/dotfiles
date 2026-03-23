# Webhooks

Secure webhook delivery with SSRF protection, state machine lifecycle, intelligent retry, and automatic cleanup.

## SSRF Protection

Always resolve and validate the target IP before making outbound requests. Block private/loopback ranges.

```ruby
# app/models/webhook/safe_resolver.rb
class Webhook::SafeResolver
  BLOCKED_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7")
  ].freeze

  def self.resolve(url)
    uri = URI.parse(url)
    addresses = Resolv.getaddresses(uri.host)

    addresses.each do |addr|
      ip = IPAddr.new(addr)
      raise SecurityError, "Blocked IP range" if BLOCKED_RANGES.any? { |range| range.include?(ip) }
    end

    { uri: uri, resolved_ip: addresses.first }
  end
end
```

---

## Webhook Model

```ruby
# app/models/webhook.rb
class Webhook < ApplicationRecord
  belongs_to :account
  has_many :deliveries, class_name: "Webhook::Delivery"

  encrypts :secret

  before_create { self.secret = SecureRandom.hex(32) }

  enum :status, { active: 0, disabled: 1 }

  FAILURE_THRESHOLD = 10
  FAILURE_WINDOW = 1.hour

  def signature_for(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
  end

  def record_failure!
    increment!(:consecutive_failures)
    update!(last_failure_at: Time.current)

    if consecutive_failures >= FAILURE_THRESHOLD &&
       last_failure_at > FAILURE_WINDOW.ago
      disabled!
    end
  end

  def record_success!
    update!(consecutive_failures: 0) if consecutive_failures > 0
  end
end
```

---

## Delivery Lifecycle

```ruby
# app/models/webhook/delivery.rb
class Webhook::Delivery < ApplicationRecord
  belongs_to :webhook

  enum :status, { pending: 0, in_progress: 1, completed: 2, errored: 3 }

  def execute!
    in_progress!

    resolved = Webhook::SafeResolver.resolve(webhook.url)
    payload = event_payload.to_json

    response = HTTP
      .headers(
        "Content-Type" => "application/json",
        "X-Webhook-Signature" => webhook.signature_for(payload)
      )
      .timeout(connect: 5, write: 5, read: 10)
      .post(resolved[:uri], body: payload)

    update!(
      status: response.status.success? ? :completed : :errored,
      response_code: response.status.code,
      response_body: response.body.to_s.truncate(10_000)
    )
  rescue => e
    update!(status: :errored, error_message: e.message)
  end
end
```

---

## Two-Stage Dispatch

Separate event dispatch (fan-out to all webhooks) from individual delivery execution.

```ruby
# app/jobs/webhook/dispatch_job.rb
class Webhook::DispatchJob < ApplicationJob
  def perform(event_type, payload)
    Current.account.webhooks.active.each do |webhook|
      delivery = webhook.deliveries.create!(
        event_type: event_type,
        event_payload: payload
      )
      Webhook::DeliveryJob.perform_later(delivery)
    end
  end
end

# app/jobs/webhook/delivery_job.rb
class Webhook::DeliveryJob < ApplicationJob
  retry_on HTTP::TimeoutError, wait: :polynomially_longer, attempts: 3

  def perform(delivery)
    delivery.execute!
    delivery.webhook.record_success!
  rescue => e
    delivery.webhook.record_failure!
    raise
  end
end
```

---

## Signature Verification (Receiving Side)

```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = request.raw_post
    signature = request.headers["X-Webhook-Signature"]

    unless ActiveSupport::SecurityUtils.secure_compare(
      OpenSSL::HMAC.hexdigest("SHA256", ENV["WEBHOOK_SECRET"], payload),
      signature.to_s
    )
      head :unauthorized
      return
    end

    process_event(JSON.parse(payload))
    head :ok
  end
end
```

Always use `ActiveSupport::SecurityUtils.secure_compare` — never `==` — to prevent timing attacks.

---

## Automatic Cleanup

```ruby
# app/jobs/webhook/cleanup_job.rb
class Webhook::CleanupJob < ApplicationJob
  def perform
    Webhook::Delivery
      .where("created_at < ?", 7.days.ago)
      .in_batches
      .delete_all
  end
end
```

```yaml
# config/recurring.yml
cleanup_webhook_deliveries:
  class: Webhook::CleanupJob
  schedule: every 4 hours
```
