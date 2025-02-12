# frozen_string_literal: true

module Decidim
  module Assemblies
    module Admin
      # A command with all the business logic when destroying an assembly
      # admin in the system.
      class DestroyAssemblyAdmin < Decidim::Command
        # Public: Initializes the command.
        #
        # role - the AssemblyUserRole to destroy
        # current_user - the user performing this action
        def initialize(role, current_user)
          @role = role
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form was not valid and we could not proceed.
        #
        # Returns nothing.
        def call
          destroy_role!
          dispatch_system_event
          broadcast(:ok)
        end

        private

        attr_reader :role, :current_user

        def dispatch_system_event
          ActiveSupport::Notifications.publish("decidim.system.participatory_space.admin.destroyed", role.class.name, role.id)
        end

        def destroy_role!
          extra_info = {
            resource: {
              title: role.user.name
            }
          }

          Decidim.traceability.perform_action!(
            "delete",
            role,
            current_user,
            extra_info
          ) do
            role.destroy!
            role
          end
        end
      end
    end
  end
end
