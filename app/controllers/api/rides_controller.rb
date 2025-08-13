module Api
  class RidesController < ApplicationController
    before_action :validate_ride_params, only: [ :create ]

    def create
      ride = Ride.new(ride_params)
      ride.driver = Driver.all.sample

      begin
        ride_metrics = RideCalculationService.calculate_ride_metrics(ride)
        ride.assign_attributes(ride_metrics)
        ride.save!

        render json: ride, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      rescue RideCalculationService::RoutingCalculationError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    private

    def ride_params
      params.require(:ride).permit(:start_address, :destination_address)
    end

    def validate_ride_params
      if params[:ride].blank?
        render json: { error: "Missing required parameters" }, status: :bad_request
      end
    end
  end
end
