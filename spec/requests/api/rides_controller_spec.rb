require "rails_helper"

RSpec.describe Api::RidesController, type: :request do
  let(:driver) { create(:driver, home_address: "123 Main St") }
  let(:ride_params) do
    {
      ride: {
        start_address: "123 Main St",
        destination_address: "456 Oak Ave"
      }
    }
  end

  before do
    allow(Driver).to receive(:all).and_return([ driver ])
    allow(RoutingService).to receive(:calculate_route_metrics).and_return(
      {
        duration: 300, # 5 minutes in seconds
        distance: 5000 # 5 kilometers
      }
    )
  end

  describe "POST /api/rides" do
    context "with valid parameters" do
      it "creates a new ride" do
        expect {
          post api_rides_path, params: ride_params
        }.to change(Ride, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response).to have_key("id")
        expect(json_response).to have_key("driver_id")
        expect(json_response["start_address"]).to eq(ride_params[:ride][:start_address])
        expect(json_response["destination_address"]).to eq(ride_params[:ride][:destination_address])
      end
    end

    context "with missing parameters" do
      it "returns unprocessable entity when missing required parameters" do
        post api_rides_path, params: { ride: { start_address: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key("errors")
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity when addresses are invalid" do
        allow(RideCalculationService).to receive(:calculate_ride_metrics)
          .and_raise(RideCalculationService::RoutingCalculationError, "Failed to calculate route")

        post api_rides_path, params: ride_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include("error" => "Failed to calculate route")
      end
    end
  end
end
