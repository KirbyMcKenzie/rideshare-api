require "rails_helper"

RSpec.describe RideCalculationService do
  describe ".calculate_ride_metrics" do
    let(:driver) { instance_double(Driver, home_address: "123 Main St") }
    let(:ride) do
      instance_double(Ride,
        driver: driver,
        start_address: "456 Oak Ave",
        destination_address: "789 Pine St"
      )
    end
    let(:commute) { { distance: 5.0, duration: 0.5 } }
    let(:ride_route) { { distance: 10.0, duration: 1.0 } }

    before do
      allow(described_class).to receive(:calculate_commute_route).with(ride).and_return(commute)
      allow(described_class).to receive(:calculate_ride_route).with(ride).and_return(ride_route)
    end

    context "when both routes are successful" do
      it "returns correct metrics" do
        expect(described_class.calculate_ride_metrics(ride)).to include(
          commute_distance: 5.0,
          commute_duration_minutes: 30,
          ride_distance: 10.0,
          ride_duration_minutes: 60,
          earnings: 51.0,
          score: 34.0
        )
      end
    end

    context "when commute route fails" do
      before do
        allow(described_class).to receive(:calculate_commute_route).with(ride).and_return(nil)
      end

      it "raises RoutingCalculationError" do
        expect {
          described_class.calculate_ride_metrics(ride)
        }.to raise_error(RideCalculationService::RoutingCalculationError,
          "Failed to calculate commute route from 123 Main St to 456 Oak Ave")
      end
    end

    context "when ride route fails" do
      before do
        allow(described_class).to receive(:calculate_ride_route).with(ride).and_return(nil)
      end

      it "raises RoutingCalculationError" do
        expect {
          described_class.calculate_ride_metrics(ride)
        }.to raise_error(RideCalculationService::RoutingCalculationError,
          "Failed to calculate ride route from 456 Oak Ave to 789 Pine St")
      end
    end

    context "when both routes fail" do
      before do
        allow(described_class).to receive(:calculate_commute_route).with(ride).and_return(nil)
        allow(described_class).to receive(:calculate_ride_route).with(ride).and_return(nil)
      end

      it "raises RoutingCalculationError for commute route" do
        expect {
          described_class.calculate_ride_metrics(ride)
        }.to raise_error(RideCalculationService::RoutingCalculationError,
          "Failed to calculate commute route from 123 Main St to 456 Oak Ave")
      end
    end
  end

  describe ".calculate_metrics" do
    let(:commute) { { distance: 5.0, duration: 0.5 } }
    let(:ride_route) { { distance: 10.0, duration: 1.0 } }

    it "calculates earnings and score correctly" do
      result = described_class.calculate_metrics(commute, ride_route)
      expect(result).to include(
        earnings: 51.0,
        score: 34.0
      )
    end

    context "when ride is shorter than minimum paid miles" do
      let(:ride_route) { { distance: 3.0, duration: 1.0 } }

      it "uses minimum paid miles for distance pay" do
        expect(described_class.calculate_metrics(commute, ride_route)[:earnings]).to eq(43.5)
      end
    end

    context "when ride is shorter than minimum paid minutes" do
      let(:ride_route) { { distance: 10.0, duration: 0.2 } }

      it "uses minimum paid minutes for time pay" do
        expect(described_class.calculate_metrics(commute, ride_route)[:earnings]).to eq(19.5)
      end
    end
  end

  describe ".calculate_earnings" do
    it "calculates base pay correctly" do
      expect(described_class.calculate_earnings(0, 0)).to eq(12.0)
    end

    it "calculates distance pay correctly" do
      expect(described_class.calculate_earnings(0, 10.0)).to eq(19.5)
    end

    it "calculates time pay correctly" do
      expect(described_class.calculate_earnings(60, 0)).to eq(43.5)
    end

    it "calculates total earnings correctly" do
      expect(described_class.calculate_earnings(60, 10.0)).to eq(51.0)
    end

    context "when ride is shorter than minimum paid miles" do
      it "uses minimum paid miles for distance pay" do
        expect(described_class.calculate_earnings(60, 3.0)).to eq(43.5)
      end
    end

    context "when ride is shorter than minimum paid minutes" do
      it "uses minimum paid minutes for time pay" do
        expect(described_class.calculate_earnings(12, 10.0)).to eq(19.5)
      end
    end
  end
end
