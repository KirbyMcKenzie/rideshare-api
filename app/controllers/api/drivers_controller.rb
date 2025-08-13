module Api
  class DriversController < ApplicationController
    DEFAULT_PER_PAGE = 5
    MAX_PER_PAGE = 50

    rescue_from ActiveRecord::RecordNotFound, with: :driver_not_found

    def rides
      driver = Driver.find(permitted_params[:id])
      rides_scope = driver.rides.order(score: :desc)

      rides = rides_scope.offset(page_offset).limit(page_size)
      total = rides_scope.count

      render json: {
        rides: rides,
        meta: {
          total: total,
          page: page_number,
          per_page: page_size,
          total_pages: (total.to_f / page_size).ceil
        }
      }
    end

    private

    def permitted_params
      params.permit(:id, :page, :per_page)
    end

    def page_number
      number = (permitted_params[:page] || 1).to_i
      number < 1 ? 1 : number
    end

    def page_size
      size = permitted_params[:per_page].to_i
      return DEFAULT_PER_PAGE if size <= 0
      [ size, MAX_PER_PAGE ].min
    end

    def page_offset
      (page_number - 1) * page_size
    end

    def driver_not_found
      render json: { error: "Driver not found" }, status: :not_found
    end
  end
end
