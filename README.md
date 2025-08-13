# Rideshare API

A Rails 8 API application for managing scheduled rides and drivers with geocoded address validation, earnings calculations, and OpenAPI 3.0 documentation.

## 🧱 Architecture Overview

### Models

- `Ride`: Represents a ride between two locations, with validations for all required fields.
- `Driver`: Stores driver information, including their home address used for commute calculations.

### Services

#### RideCalculationService

Calculates:

- Commute and ride distances/durations
- Earnings with base pay and multipliers
- Score = earnings / (commute duration + ride duration)

#### RoutingService

Interfaces with OpenRouteService for:

- Address geocoding
- Route distance & duration calculations

## ⚙️ Tech Stack

- Ruby: 3.2+
- Rails: 8.0.2+
- PostgreSQL: 14+
- Faraday: For HTTP API requests
- RSpec: Testing framework
- OpenRouteService: Used for geocoding and routing

## 🚀 Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/KirbyMcKenzie/rideshare-api.git
   cd rideshare-api
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up the database:

   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Run the test suite:

   ```bash
   bundle exec rspec
   ```

5. Start the server:

   ```bash
   rails server
   ```

6. Run the test suite:

   ```bash
   bundle exec rspec
   ```

The API will be available at: http://localhost:3000

### 📃 API Documentation

This app includes OpenAPI 3.0 documentation. To view the interactive documentation:

1. Copy the contents of [openapi.yaml](/openapi.yaml)
2. Paste it into [https://editor.swagger.io/](https://editor.swagger.io/)

## 📡 API Endpoints

### `POST /api/rides`

Creates a new ride and assigns a random driver.

- **Required params:**

  - `start_address` (string)
  - `destination_address` (string)

- **Behavior:**

  - Geocodes both addresses
  - Calculates commute and ride routes
  - Computes earnings and score
  - Persists and returns the complete ride record

- **Performance Note:**
  - External API latency ~8s — all calculations handled during this request for deterministic results. (Discussed more in Performance section)

---

### `GET /api/drivers/:id/rides`

Fetches a driver’s rides, sorted by score (highest first).

- **Supports:**

  - Pagination via `?page=1&per=10`

- **Returns:**

  - List of rides including earnings, score, and address info
  - Metadata for pagination (`page`, `per`, `total_pages`, etc.)

- **Performance Note:**
  - Extremely fast — all data is precomputed during ride creation.

## ⚡ Performance, Design & Scaling Considerations

### Route Latency & Write Optimization

Calculating a ride’s commute and trip metrics (geocoding + 2 routes) takes ~8s via the OpenRouteService API. To keep reads fast, all heavy logic—geocoding, routing, earnings, and score calculations—is handled during `POST /rides` and stored. This allows `GET /drivers/:id/rides` to return sorted, paginated results instantly.

### Scaling for Production

If this were heading to production, next steps would be:

- **Background Jobs**: Offload route calculations and driver assignment using Sidekiq or similar. Avoid blocking requests on external API latency.
- **Caching**: Cache geocode and routing results by address pair using Redis with TTL.
- **Monitoring**: Track external latency, job queue stats, and failure rates. Add structured logging and alerting (e.g., Sentry, Datadog).
- **Resilience**: Wrap external calls with circuit breakers and retries. Provide safe fallbacks if APIs fail.

The current setup keeps things simple but scalable. Reads are fast, writes are deterministic, and the core bottleneck (routing) is isolated for easy offloading.
