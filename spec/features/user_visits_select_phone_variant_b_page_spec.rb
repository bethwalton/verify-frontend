require 'feature_helper'
require 'api_test_helper'
require 'uri'

RSpec.describe 'When the user visits the select phone page' do
  let(:selected_answers) {
    {
      documents: { passport: true, driving_licence: true },
      device_type: { device_type_other: true }
    }
  }
  let(:given_a_session_with_document_evidence) {
    set_selected_idp_in_session(entity_id: 'http://idcorp.com', simple_id: 'stub-idp-one')
    page.set_rack_session(
      selected_idp_was_recommended: true,
      selected_answers: selected_answers,
    )
  }
  stub_idp_one = {
    'simpleId' => 'stub-idp-one',
    'entityId' => 'http://idcorp.com',
    'levelsOfAssurance' => %w(LEVEL_2)
  }
  stub_idp_two = {
    'simpleId' => 'stub-idp-one',
    'entityId' => 'http://idcorp.com',
    'levelsOfAssurance' => %w(LEVEL_2)
  }
  stub_idp_three = {
    'simpleId' => 'stub-idp-one',
    'entityId' => 'http://idcorp.com',
    'levelsOfAssurance' => %w(LEVEL_2)
  }

  before(:each) do
    experiment = { "short_hub_2019_q3-preview" => "short_hub_2019_q3-preview_variant_b_2_idp" }
    set_session_and_ab_session_cookies!(experiment)
    stub_api_idp_list_for_loa([stub_idp_one, stub_idp_two, stub_idp_three])
  end

  context 'with javascript disabled' do
    it 'allows you to overwrite the values of your selected evidence' do
      page.set_rack_session(transaction_simple_id: 'test-rp')
      given_a_session_with_document_evidence

      visit '/select-phone'

      choose 'select_phone_form_mobile_phone_true', allow_label_click: true
      choose 'select_phone_form_smart_phone_true', allow_label_click: true
      click_button t('navigation.continue')

      visit '/select-phone'
      choose 'select_phone_form_mobile_phone_false', allow_label_click: true
      click_button t('navigation.continue')

      expect(page.get_rack_session['selected_answers']).to eql(
        'device_type' => { 'device_type_other' => true },
        'phone' => { 'mobile_phone' => false },
        'documents' => { 'passport' => true, 'driving_licence' => true },
      )
    end

    it 'shows an error message when no selections are made' do
      visit '/select-phone'
      click_button t('navigation.continue')

      expect(page).to have_css '.validation-message', text: 'Please answer all the questions'
      expect(page).to have_css '.form-group-error'
    end
  end

  context 'with javascript enabled', js: true do
    it 'redirects to the idp picker page when user has a phone' do
      given_a_session_with_document_evidence

      visit '/select-phone'

      choose 'select_phone_form_mobile_phone_true', allow_label_click: true
      choose 'select_phone_form_smart_phone_true', allow_label_click: true
      click_button t('navigation.continue')

      expect(page).to have_current_path(choose_a_certified_company_path)
      expect(page.get_rack_session['selected_answers']).to eql(
        'device_type' => { 'device_type_other' => true },
        'phone' => { 'mobile_phone' => true, 'smart_phone' => true },
        'documents' => { 'passport' => true, 'driving_licence' => true }
      )
    end

    it 'should display a validation message when user does not answer mobile phone question' do
      visit '/select-phone'

      click_button t('navigation.continue')

      expect(page).to have_current_path(select_phone_path)
      expect(page).to have_css '#validation-error-message-js', text: 'Please answer all the questions'
    end

    it 'redirects to the no mobile phone page when no idps can verify' do
      visit '/select-phone'

      choose 'select_phone_form_mobile_phone_false', allow_label_click: true
      click_button t('navigation.continue')

      expect(page).to have_current_path(verify_will_not_work_for_you_path)

      # expect(page.get_rack_session['selected_answers']).to eql(
      #  'device_type' => { 'device_type_other' => true },
      #  'phone' => { 'mobile_phone' => false }
      # )

      # TODO(HUH-234): why is this not correct? instead we see:
      # {"documents"=>{"driving_licence"=>false}, "device_type"=>{"device_type_other"=>true}, "phone"=>{"mobile_phone"=>false}}
    end
  end

  it 'includes the appropriate feedback source' do
    visit '/select-phone'

    expect_feedback_source_to_be(page, 'SELECT_PHONE_PAGE', '/select-phone')
  end

  it 'displays the page in Welsh' do
    visit 'dewis-ffon'
    expect(page).to have_title t('hub.select_phone.title', locale: :cy)
    expect(page).to have_css 'html[lang=cy]'
  end

  it 'does not report to Piwik when form is invalid' do
    stub_request(:get, INTERNAL_PIWIK.url).with(query: hash_including({}))
    piwik_request = { 'action_name' => 'Phone Next' }
    visit '/select-phone'

    click_button t('navigation.continue')

    expect(a_request(:get, INTERNAL_PIWIK.url).with(query: hash_including(piwik_request))).to_not have_been_made
  end
end
