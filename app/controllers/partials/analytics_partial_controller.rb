module AnalyticsPartialController
  def public_piwik
    PUBLIC_PIWIK
  end

  def report_to_analytics(action_name)
    FEDERATION_REPORTER.report_action(current_transaction, request, action_name)
  end

  def set_piwik_custom_variables
    custom_variables_for_js
    custom_variables_for_img_tracker
  end

  def delete_new_visit_flag
    http_redirect = 302
    http_see_other = 303
    session.delete(:new_visit) unless [http_redirect, http_see_other].include?(self.status)
  end

private

  def custom_variables_for_js
    @piwik_custom_variables = [
      Analytics::CustomVariable.build_for_js_client(:rp, current_transaction.analytics_description),
      Analytics::CustomVariable.build_for_js_client(:loa_requested, session[:requested_loa])
    ]
  end

  def custom_variables_for_img_tracker
    current_transaction_custom_variable = Analytics::CustomVariable.build(:rp, current_transaction.analytics_description)
    loa_requested_custom_variable = Analytics::CustomVariable.build(:loa_requested, session[:requested_loa])
    @piwik_custom_variables_img_tracker =
      current_transaction_custom_variable.merge(loa_requested_custom_variable)
  end

  def report_user_outcome_to_piwik(response_status)
    FEDERATION_REPORTER.report_user_idp_outcome(
      current_transaction: current_transaction,
      request: request,
      idp_name: session[:selected_idp_name],
      user_segments: session[:user_segments],
      transaction_simple_id: session[:transaction_simple_id],
      attempt_number: session[:attempt_number],
      journey_type: session[:journey_type],
      hint_followed: session[:user_followed_journey_hint],
      response_status: response_status
    )
  end
end
