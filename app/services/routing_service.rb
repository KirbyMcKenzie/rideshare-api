class RoutingService
  API_BASE = "https://api.openrouteservice.org"

  class RoutingError < StandardError; end
  class InvalidAddressError < RoutingError; end

  def self.calculate_route_metrics(origin:, destination:)
    origin_coords = geocode(origin)
    raise InvalidAddressError, "Failed to geocode origin address: #{origin}" unless origin_coords

    destination_coords = geocode(destination)
    raise InvalidAddressError, "Failed to geocode destination address: #{destination}" unless destination_coords

    fetch_route_data(origin_coords, destination_coords)
  end

  private

  def self.geocode(address)
    response = Faraday.get("#{API_BASE}/geocode/search") do |req|
      req.params["api_key"] = Rails.application.credentials.openroute_api_key
      req.params["text"] = address
    end

    return nil unless response.success?

    data = JSON.parse(response.body)
    return nil if data["features"].empty?

    data["features"].first["geometry"]["coordinates"].reverse
  rescue Faraday::Error, JSON::ParserError
    nil
  end

  def self.fetch_route_data(origin_coords, destination_coords)
    coordinates = [
      origin_coords.reverse,
      destination_coords.reverse
    ]

    response = Faraday.post("#{API_BASE}/v2/directions/driving-car") do |req|
      req.headers["Content-Type"] = "application/json"
      req.params["api_key"] = Rails.application.credentials.openroute_api_key
      req.body = { coordinates: coordinates }.to_json
    end

    return nil unless response.success?

    data = JSON.parse(response.body)
    route = data["routes"]&.first
    return nil unless route

    distance = route["summary"]["distance"] / 1000.0 * 0.621371  # Convert meters to miles
    duration = route["summary"]["duration"] / 3600.0  # Convert seconds to hours

    { distance: distance, duration: duration }
  rescue Faraday::Error, JSON::ParserError
    nil
  end
end
