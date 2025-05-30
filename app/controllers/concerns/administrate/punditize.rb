module Administrate
  module Punditize
    if Object.const_defined?(:Pundit)
      extend ActiveSupport::Concern

      if Pundit.const_defined?(:Authorization)
        include Pundit::Authorization
      else
        include Pundit
      end

      private

      def policy_namespace
        []
      end

      def scoped_resource
        namespaced_scope = policy_namespace + [super]
        policy_scope!(pundit_user, namespaced_scope)
      end

      def authorize_resource(resource)
        namespaced_resource = policy_namespace + [resource]
        authorize namespaced_resource
      end

      def authorized_action?(resource, action)
        namespaced_resource = policy_namespace + [resource]
        policy = Pundit.policy!(pundit_user, namespaced_resource)
        policy.send(:"#{action}?")
      end

      def policy_scope!(user, scope)
        policy_scope_class = Pundit::PolicyFinder.new(scope).scope!

        begin
          policy_scope = policy_scope_class.new(user, pundit_model(scope))
        rescue ArgumentError
          raise(Pundit::InvalidConstructorError,
            "Invalid #<#{policy_scope_class}> constructor is called")
        end

        policy_scope.resolve
      end

      def pundit_model(record)
        record.is_a?(Array) ? record.last : record
      end
    end
  end
end
