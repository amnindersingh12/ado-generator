# frozen_string_literal: true

require 'test_helper'

class CalendarControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test 'should get index' do
    get history_calendar_url
    assert_response :success
  end

  test 'should get a day' do
    today = Time.zone.today
    get calendar_day_url(year: today.year, month: today.month, day: today.day)
    assert_response :success
  end

  test 'redirects to sign in when logged out' do
    sign_out :user
    get history_calendar_url
    assert_redirected_to new_user_session_url
  end
end
