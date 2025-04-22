module Api
  class DriversController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :driver_not_found

    def rides
      driver = Driver.find(permitted_params[:id])
      rides = driver.rides
                    .order(score: :desc)
                    .drop(page_offset)
                    .take(page_size)

      render json: {
        rides: rides,
        meta: pagination_meta(rides.size)
      }
    end

    private

    def permitted_params
      params.permit(:id, :page, :per_page)
    end

    def page_number
      (permitted_params[:page] || 1).to_i.clamp(1, 100)
    end

    def page_size
      (permitted_params[:per_page] || 10).to_i.clamp(1, 50)
    end

    def page_offset
      (page_number - 1) * page_size
    end

    def pagination_meta(total)
      {
        total: total,
        page: page_number,
        per_page: page_size,
        total_pages: (total.to_f / page_size).ceil
      }
    end

    def driver_not_found
      render json: { error: "Driver not found" }, status: :not_found
    end
  end
end
