require 'select_phone_form_mapper'
require 'evidence_query_string_parser'
require 'evidence_query_string_builder'

class SelectPhoneController < ApplicationController
  protect_from_forgery except: :select_phone

  def index
    @form = SelectPhoneForm.new({})
  end

  def select_phone
    ANALYTICS_REPORTER.report(request, 'Phone Next')
    @form = SelectPhoneForm.new(SelectPhoneFormMapper.map(params))
    if @form.valid?
      selected_evidence = @form.selected_evidence.concat EvidenceQueryStringParser.parse(request.query_string)
      if IDP_ELIGIBILITY_CHECKER.any?(selected_evidence, available_idps)
        uri = URI(will_it_work_for_me_path)
        uri.query = EvidenceQueryStringBuilder.build(selected_evidence)
        redirect_to uri.to_s
      else
        redirect_to no_mobile_phone_path
      end
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :index
    end
  end

private

  def available_idps
    SESSION_PROXY.federation_info_for_session(cookies).idps.collect { |idp| idp['simpleId'] }
  end
end
