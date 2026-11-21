# frozen_string_literal: true

require 'test_helper'

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:one) }

  test 'should get index' do
    get records_url
    assert_response :success
  end

  test 'should get new' do
    get new_record_url
    assert_response :success
  end
end
