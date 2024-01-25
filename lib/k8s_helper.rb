def kubeconfig
  if %w[miceportal-production miceportal-beta].include?(k8s_namespace)
    "/Users/michaeldeimel/entwicklung/miceportal/composator/config/kubeconfig_bcp-miceportal-prod.yaml"
  else
    "/Users/michaeldeimel/entwicklung/miceportal/composator/config/kubeconfig_miceportal-staging.yaml"
  end
end

def checking_namespace(programm)
  if @namespace.nil?
    puts "Usage: #{programm} <namespace>"
    exit 1
  end
end

def alias_namespace(namespace)
  {
    prod: 'miceportal-production',
    production: 'miceportal-production',
    beta: 'miceportal-beta',
    alpha: 'miceportal-alpha',
  }[namespace.to_sym] || namespace
end

def k8s_namespace
  alias_namespace(@namespace)
end

def run_kubectl(cmd)
  cmd = "KUBECONFIG=#{kubeconfig} kubectl #{cmd} -n #{k8s_namespace}"
  puts cmd
  puts `#{cmd}`.strip
end
