module Api
  module V1
    class BaseController < ApplicationController
      before_action :set_json_format
      before_action :require_user

      respond_to :json

      rescue_from Trailblazer::NotAuthorizedError, with: :render_forbidden

      def unknown
        render_error(404, 'Not Found', 'Url not found')
      end

      protected

      def require_user
        render_error(401, 'Unauthorized', 'Need authorization') and return false unless user_signed_in?
      end

      def render_forbidden
        render_error(403, 'Forbidden', "You don't have permissions")
      end

      def render_error(status, title, detail, _path = request.path)
        render_errors(status, [Api::ErrorResponse.new(status, title, detail, request.path)])
      end

      def render_errors(status, errors)
        render status: status, json: { errors: errors }
      end

      def process_operation(klass, root_name, data: params[root_name] || {})
        op = klass.reject(data.merge(current_user: current_user, real_user: real_user)) do |op|
          render_errors(*Api::ValidationResponse.new(root_name, op.errors.messages).to_response)
          return
        end
        if root_name
          render json: { root_name => op }
        else
          render json: op, root: false
        end
      end

      def set_json_format
        request.format = :json
      end
    end
  end
end
