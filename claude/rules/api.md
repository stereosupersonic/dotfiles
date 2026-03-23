# API Development

## Core Responsibility

1. RESTful Design: Implement clean, consistent REST APIs
2. Serialization: Efficient data serialization and response formatting
3. Versioning: API versioning strategies and implementation
4. Authentication: Token-based auth, JWT, OAuth implementation
5. Documentation: Clear API documentation and examples

## API Structure

- Version APIs from day one (`/api/v1/`)
- Use consistent JSON structure
- Return appropriate HTTP status codes
- Use serializers for consistent output wiht Jbuilder
- Handle errors consistently
- Document API endpoints

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      respond_to :json

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found(exception)
        render json: {
          error: "Resource not found",
          message: exception.message
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "Validation failed",
          details: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          error: "Bad request",
          message: exception.message
        }, status: :bad_request
      end
    end
  end
end

# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      def index
        @users = User.active
      end

      def show
        @user = User.find(params[:id])
      end

      def create
        result = Users::CreateUser.new(user_params).call

        if result.success?
          head :no_content
        else
          unprocessable_entity(result)
        end
      end

      private

      def user_params
        params.expect(user: [:email, :name])
      end
    end
  end
end

# app/views/api/v1/users/index.json.jbuilder
json.array! @users do |user|
  json.extract! user, :id, :name, :email
end

# app/views/api/v1/users/show.json.jbuilder
json.extract! @user
              :id,
              :name,
              :email

```
