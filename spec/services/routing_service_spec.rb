require "rails_helper"

RSpec.describe RoutingService do
  describe ".calculate_route_metrics" do
    let(:origin) { "123 Main St" }
    let(:destination) { "456 Oak Ave" }
    let(:origin_coords) { [ 40.7128, -74.0060 ] }
    let(:destination_coords) { [ 40.7128, -74.0060 ] }
    let(:route_data) { { distance: 5.0, duration: 0.5 } }

    before do
      allow(described_class).to receive(:geocode).with(origin).and_return(origin_coords)
      allow(described_class).to receive(:geocode).with(destination).and_return(destination_coords)
      allow(described_class).to receive(:fetch_route_data).with(origin_coords, destination_coords).and_return(route_data)
    end

    it "returns route metrics when successful" do
      expect(described_class.calculate_route_metrics(origin: origin, destination: destination)).to eq(route_data)
    end

    context "when geocoding fails" do
      before do
        allow(described_class).to receive(:geocode).with(origin).and_return(nil)
      end

      it "raises InvalidAddressError for origin" do
        expect {
          described_class.calculate_route_metrics(origin: origin, destination: destination)
        }.to raise_error(RoutingService::InvalidAddressError, "Failed to geocode origin address: #{origin}")
      end
    end

    context "when route data fetching fails" do
      before do
        allow(described_class).to receive(:fetch_route_data).with(origin_coords, destination_coords).and_return(nil)
      end

      it "returns nil" do
        expect(described_class.calculate_route_metrics(origin: origin, destination: destination)).to be_nil
      end
    end

    context "when both geocoding and route data fetching fail" do
      before do
        allow(described_class).to receive(:geocode).with(origin).and_return(nil)
        allow(described_class).to receive(:geocode).with(destination).and_return(nil)
      end

      it "raises InvalidAddressError for origin" do
        expect {
          described_class.calculate_route_metrics(origin: origin, destination: destination)
        }.to raise_error(RoutingService::InvalidAddressError, "Failed to geocode origin address: #{origin}")
      end
    end
  end

  describe ".geocode" do
    let(:address) { "123 Main St" }
    let(:coordinates) { [ 40.7128, -74.0060 ] }
    let(:response) { instance_double(Faraday::Response) }
    let(:geocode_data) do
      {
        "features" => [
          {
            "geometry" => {
              "coordinates" => [ -74.0060, 40.7128 ]
            }
          }
        ]
      }
    end

    before do
      allow(Faraday).to receive(:get).and_return(response)
    end

    context "when geocoding is successful" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(geocode_data.to_json)
      end

      it "returns coordinates" do
        expect(described_class.geocode(address)).to eq(coordinates)
      end
    end

    context "when geocoding fails" do
      before do
        allow(response).to receive(:success?).and_return(false)
      end

      it "returns nil" do
        expect(described_class.geocode(address)).to be_nil
      end
    end

    context "when geocoding returns no results" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return({ "features" => [] }.to_json)
      end

      it "returns nil" do
        expect(described_class.geocode(address)).to be_nil
      end
    end

    context "when geocoding response is invalid JSON" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return("invalid json")
      end

      it "returns nil" do
        expect(described_class.geocode(address)).to be_nil
      end
    end
  end

  describe ".fetch_route_data" do
    let(:origin_coords) { [ 40.7128, -74.0060 ] }
    let(:destination_coords) { [ 40.7128, -74.0060 ] }
    let(:response) { instance_double(Faraday::Response) }
    let(:route_data) do
      {
        "routes" => [
          {
            "summary" => {
              "distance" => 10000,  # 10km = 6.21371 miles
              "duration" => 3600    # 1 hour
            }
          }
        ]
      }
    end

    before do
      allow(Faraday).to receive(:post).and_return(response)
    end

    context "when route data is successful" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(route_data.to_json)
      end

      it "returns route metrics" do
        expect(described_class.fetch_route_data(origin_coords, destination_coords)).to eq({
          distance: 6.21371,
          duration: 1.0
        })
      end
    end

    context "when route data fails" do
      before do
        allow(response).to receive(:success?).and_return(false)
      end

      it "returns nil" do
        expect(described_class.fetch_route_data(origin_coords, destination_coords)).to be_nil
      end
    end

    context "when route data has no routes" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return({ "routes" => [] }.to_json)
      end

      it "returns nil" do
        expect(described_class.fetch_route_data(origin_coords, destination_coords)).to be_nil
      end
    end

    context "when route data response is invalid JSON" do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return("invalid json")
      end

      it "returns nil" do
        expect(described_class.fetch_route_data(origin_coords, destination_coords)).to be_nil
      end
    end
  end
end
