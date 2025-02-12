# frozen_string_literal: true

require "spec_helper"

module Decidim::ParticipatoryProcesses
  describe Admin::DestroyParticipatoryProcessAdmin, versioning: true do
    subject { described_class.new(role, current_user) }

    let(:my_process) { create :participatory_process }
    let(:role) { create :participatory_process_user_role, user:, participatory_process: my_process, role: :admin }
    let!(:current_user) { create :user, email: "some_email@example.org", organization: my_process.organization }
    let!(:user) { create :user, :confirmed, organization: my_process.organization }

    context "when everything is ok" do
      let(:log_info) do
        {
          resource: {
            title: role.user.name
          }
        }
      end

      it "deletes the user role" do
        subject.call
        expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fires an event" do
        expect(ActiveSupport::Notifications).to receive(:publish).with(
          "decidim.system.participatory_space.admin.destroyed",
          "Decidim::ParticipatoryProcessUserRole",
          role.id
        )

        subject.call
      end

      it "traces the action" do
        expect(Decidim.traceability)
          .to receive(:perform_action!)
          .with("delete", role, current_user, log_info)
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "destroy"
      end
    end
  end
end
