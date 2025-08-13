require "rails_helper"

RSpec.describe Api::DriversController, type: :request do
  let(:driver) { create(:driver) }
  let(:rides_path) { "/api/drivers/#{driver.id}/rides" }

  describe "GET /api/drivers/:id/rides" do
    context "when parameters are valid" do
      it "returns first page of rides with default pagination" do
        create_list(:ride, 10, driver: driver)

        get rides_path

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).limit(5).as_json),
          "meta" => {
            "total" => 10,
            "page" => 1,
            "per_page" => 5,
            "total_pages" => 2
          }
        )
      end

      it "returns second page of rides with custom pagination" do
        create_list(:ride, 25, driver: driver)

        get rides_path, params: { page: 2, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).offset(10).limit(10).as_json),
          "meta" => {
            "total" => 25,
            "page" => 2,
            "per_page" => 10,
            "total_pages" => 3
          }
        )
      end

      it "handles large number of pages" do
        create_list(:ride, 100, driver: driver)

        get rides_path, params: { page: 10, per_page: 10 }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).offset(90).limit(10).as_json),
          "meta" => {
            "total" => 100,
            "page" => 10,
            "per_page" => 10,
            "total_pages" => 10
          }
        )
      end

      it "respects maximum per_page limit" do
        create_list(:ride, 100, driver: driver)

        get rides_path, params: { per_page: 100 }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).limit(50).as_json),
          "meta" => {
            "total" => 100,
            "page" => 1,
            "per_page" => 50,
            "total_pages" => 2
          }
        )
      end

      it "respects minimum per_page limit" do
        create_list(:ride, 10, driver: driver)

        get rides_path, params: { per_page: 0 }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).limit(5).as_json),
          "meta" => {
            "total" => 10,
            "page" => 1,
            "per_page" => 5,
            "total_pages" => 2
          }
        )
      end
    end

    context "when parameters are invalid" do
      it "returns 404 when driver not found" do
        get "/api/drivers/invalid_id/rides"

        expect(response).to have_http_status(:not_found)
        expect(json_response).to include("error" => "Driver not found")
      end

      it "defaults to first page when page number is invalid" do
        create_list(:ride, 10, driver: driver)

        get rides_path, params: { page: -1 }

        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          "rides" => match_array(Ride.where(driver: driver).order(score: :desc).limit(5).as_json),
          "meta" => {
            "total" => 10,
            "page" => 1,
            "per_page" => 5,
            "total_pages" => 2
          }
        )
      end
    end
  end
end
