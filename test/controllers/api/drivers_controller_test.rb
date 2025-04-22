require "test_helper"

class Api::DriversControllerTest < ActionDispatch::IntegrationTest
  test "should get rides for a driver" do
    driver = drivers(:one)
    get rides_api_driver_url(driver)

    assert_response :success
  end
end
