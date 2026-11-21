# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'new users default to the user role' do
    assert_predicate User.new(email: 'new@example.com', password: 'password123'), :user?
  end

  test 'fixtures load with roles' do
    assert_predicate users(:admin), :admin?
  end
end
