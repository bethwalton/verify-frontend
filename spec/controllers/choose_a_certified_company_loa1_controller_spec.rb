require "rails_helper"
require "controller_helper"
require "api_test_helper"
require "piwik_test_helper"

describe ChooseACertifiedCompanyLoa1Controller do
  let(:stub_idp_loa1) {
    {
      simpleId: "stub-idp-loa1",
      entityId: "http://idcorp-loa1.com",
      levelsOfAssurance: %w(LEVEL_1 LEVEL_2),
    }.freeze
  }

  context "#index" do
    before :each do
      stub_api_idp_list_for_registration([stub_idp_loa1], loa: "LEVEL_1")
    end

    it "renders IDP list" do
      set_session_and_cookies_with_loa("LEVEL_1", "test-rp")

      expect(IDENTITY_PROVIDER_DISPLAY_DECORATOR).to receive(:decorate_collection).once do |idps|
        idps.each { |idp| expect(idp.levels_of_assurance).to include "LEVEL_1" }
      end

      get :index, params: { locale: "en" }

      expect(subject).to render_template(:choose_a_certified_company)
    end
  end

  context "#select_idp" do
    before :each do
      stub_api_select_idp
      set_session_and_cookies_with_loa("LEVEL_1")
      stub_api_idp_list_for_sign_in
      stub_api_idp_list_for_registration(loa: "LEVEL_1")
    end

    it "sets selected IDP in user session" do
      post :select_idp, params: { locale: "en", entity_id: "http://idcorp-loa1.com" }

      expect(session[:selected_provider].entity_id).to eql("http://idcorp-loa1.com")
    end

    it "redirects to IDP warning page by default" do
      post :select_idp, params: { locale: "en", entity_id: "http://idcorp-two.com" }

      expect(subject).to redirect_to redirect_to_idp_register_path
    end

    it "returns 404 page if IDP is non-existent" do
      post :select_idp, params: { locale: "en", entity_id: "http://notanidp.com" }

      expect(response).to have_http_status :not_found
    end

    it "returns 400 if `entity_id` param is not present" do
      post :select_idp, params: { locale: "en" }

      expect(subject).to render_template "errors/something_went_wrong"
      expect(response).to have_http_status :bad_request
    end
  end

  context "#about" do
    it "returns 404 page if no display data exists for IDP" do
      set_session_and_cookies_with_loa("LEVEL_1")
      stub_api_idp_list_for_registration(loa: "LEVEL_1")

      get :about, params: { locale: "en", company: "unknown-idp" }

      expect(subject).to render_template "errors/404"
      expect(response).to have_http_status :not_found
    end
  end
end
