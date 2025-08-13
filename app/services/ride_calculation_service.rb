class RideCalculationService
  BASE_PAY = 12.0
  DISTANCE_PAY_PER_MILE = 1.50
  TIME_PAY_PER_MINUTE = 0.70
  MINIMUM_PAID_MILES = 5
  MINIMUM_PAID_MINUTES = 15

  class RoutingError < StandardError; end
  class InvalidRideError < StandardError; end
  class RoutingCalculationError < InvalidRideError; end

  def self.calculate_ride_metrics(ride)
    commute = calculate_commute_route(ride)
    raise RoutingCalculationError, "Failed to calculate commute route from #{ride.driver.home_address} to #{ride.start_address}" unless commute

    ride_route = calculate_ride_route(ride)
    raise RoutingCalculationError, "Failed to calculate ride route from #{ride.start_address} to #{ride.destination_address}" unless ride_route

    calculate_metrics(commute, ride_route)
  end

  private

  def self.calculate_commute_route(ride)
    RoutingService.calculate_route_metrics(
      origin: ride.driver.home_address,
      destination: ride.start_address
    )
  end

  def self.calculate_ride_route(ride)
    RoutingService.calculate_route_metrics(
      origin: ride.start_address,
      destination: ride.destination_address
    )
  end

  def self.calculate_metrics(commute, ride_route)
    ride_duration_minutes = ride_route[:duration] * 60
    commute_duration_minutes = commute[:duration] * 60
    total_duration_minutes = ride_duration_minutes + commute_duration_minutes

    earnings = calculate_earnings(ride_duration_minutes, ride_route[:distance])
    score = earnings / (total_duration_minutes / 60.0)

    {
      commute_distance: commute[:distance],
      commute_duration_minutes: commute_duration_minutes,
      ride_distance: ride_route[:distance],
      ride_duration_minutes: ride_duration_minutes,
      earnings: earnings,
      score: score
    }
  end

  def self.calculate_earnings(duration_in_minutes, distance_in_miles)
    distance_pay = [ distance_in_miles - MINIMUM_PAID_MILES, 0 ].max * DISTANCE_PAY_PER_MILE
    time_pay = [ duration_in_minutes - MINIMUM_PAID_MINUTES, 0 ].max * TIME_PAY_PER_MINUTE

    BASE_PAY + distance_pay + time_pay
  end
end
