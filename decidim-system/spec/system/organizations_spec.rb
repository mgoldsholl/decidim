# frozen_string_literal: true

require "spec_helper"

describe "Organizations", type: :system do
  let(:admin) { create(:admin) }

  shared_examples "form hiding advanced settings" do
    it "hides advanced settings" do
      expect(page).to have_content "Show advanced settings"
      expect(page).to have_no_content "SMTP settings"
      expect(page).to have_no_content "Omniauth settings"
      expect(page).to have_no_content "File upload settings"
    end
  end

  context "when an admin authenticated" do
    before do
      login_as admin, scope: :admin
      visit decidim_system.root_path
    end

    describe "creating an organization" do
      before do
        click_link "Organizations"
        click_link "New"
      end

      it_behaves_like "form hiding advanced settings"

      it "creates a new organization" do
        fill_in "Name", with: "Citizen Corp"
        fill_in "Host", with: "www.example.org"
        fill_in "Secondary hosts", with: "foo.example.org\n\rbar.example.org"
        fill_in "Reference prefix", with: "CCORP"
        fill_in "Organization admin name", with: "City Mayor"
        fill_in "Organization admin email", with: "mayor@example.org"
        check "organization_available_locales_en"
        choose "organization_default_locale_en"
        choose "Allow participants to register and login"
        check "Example authorization (Direct)"
        click_button "Create organization & invite admin"

        expect(page).to have_css("div.flash.success")
        expect(page).to have_content("Citizen Corp")
      end

      context "with invalid data" do
        it "does not create an organization" do
          fill_in "Name", with: "Bad"
          click_button "Create organization & invite admin"

          expect(page).to have_content("There is an error in this field")
        end
      end
    end

    describe "showing an organization with different locale than user" do
      let!(:organization) do
        create(:organization, name: "Citizen Corp", default_locale: :es, available_locales: ["es"], description: { es: "Un texto largo" })
      end

      before do
        click_link "Organizations"
        within "table tbody" do
          first("tr").click_link "Citizen Corp"
        end
      end

      it "shows the organization data" do
        expect(page).to have_content("Citizen Corp")
        expect(page).to have_content("Un texto largo")
      end
    end

    describe "editing an organization" do
      let!(:organization) { create(:organization, name: "Citizen Corp") }

      before do
        click_link "Organizations"
        within "table tbody" do
          first("tr").click_link "Edit"
        end
      end

      it_behaves_like "form hiding advanced settings"

      it "edits the data" do
        fill_in "Name", with: "Citizens Rule!"
        fill_in "Host", with: "www.example.org"
        fill_in "Secondary hosts", with: "foobar.example.org\n\rbar.example.org"
        choose "Do not allow participants to register, but allow existing participants to login"
        check "Example authorization (Direct)"

        click_button "Show advanced settings"
        check "organization_omniauth_settings_facebook_enabled"
        fill_in "organization_omniauth_settings_facebook_app_id", with: "facebook-app-id"
        fill_in "organization_omniauth_settings_facebook_app_secret", with: "facebook-app-secret"

        click_button "Save"

        expect(page).to have_css("div.flash.success")
        expect(page).to have_content("Citizens Rule!")
      end
    end

    describe "editing an organization with disabled OmniAuth provider" do
      let!(:organization) do
        create(:organization, name: "Citizen Corp", default_locale: :es, available_locales: ["es"], description: { es: "Un texto largo" })
      end

      before do
        secrets = Rails.application.secrets
        allow(Rails.application).to receive(:secrets).and_return(
          secrets.merge(
            omniauth: {
              facebook: {
                enabled: true,
                app_id: "fake-facebook-app-id",
                app_secret: "fake-facebook-app-secret"
              },
              twitter: {
                enabled: true,
                api_key: "fake-twitter-api-key",
                api_secret: "fake-twitter-api-secret"
              },
              google_oauth2: {
                enabled: true,
                client_id: "",
                client_secret: ""
              },
              developer: {
                enabled: false,
                icon: "phone"
              }
            }
          )
        )

        # Reload the UpdateOrganizationForm
        Decidim::System.send(:remove_const, :UpdateOrganizationForm)
        load "#{Decidim::System::Engine.root}/app/forms/decidim/system/update_organization_form.rb"

        click_link "Organizations"
        within "table tbody" do
          first("tr").click_link "Edit"
        end

        click_button "Show advanced settings"
      end

      after do
        # Reload the UpdateOrganizationForm
        Decidim::System.send(:remove_const, :UpdateOrganizationForm)
        load "#{Decidim::System::Engine.root}/app/forms/decidim/system/update_organization_form.rb"
      end

      it "displays all the available OmniAuth providers" do
        expect(page).to have_content("Developer")
      end
    end
  end
end
