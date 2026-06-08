import UIKit

struct WeatherLocation: Codable, Hashable {
    let id: String
    let name: String
    let subtitle: String?
    let latitude: Double
    let longitude: Double

    var displayName: String { name }

    var fullName: String {
        guard let subtitle, !subtitle.isEmpty else { return name }
        return "\(name), \(subtitle)"
    }
}

enum WeatherMode: CaseIterable {
    case sunny
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case storm

    var summary: String {
        switch self {
        case .sunny:
            return "Clear"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .cloudy:
            return "Cloudy"
        case .rain:
            return "Heavy Rain"
        case .snow:
            return "Snow"
        case .storm:
            return "Thunderstorms"
        }
    }

    var detail: String {
        switch self {
        case .sunny:
            return "Bright skies with light breezes."
        case .partlyCloudy:
            return "Clouds rolling through with breaks of sun."
        case .cloudy:
            return "Overcast and calm throughout the day."
        case .rain:
            return "Steady rain with slick roads."
        case .snow:
            return "Snow showers likely into the evening."
        case .storm:
            return "Severe storms expected later today."
        }
    }

    func symbolName(isDaylight: Bool) -> String {
        switch self {
        case .sunny:
            return isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy:
            return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy:
            return isDaylight ? "cloud.fill" : "cloud.moon.fill"
        case .rain:
            return isDaylight ? "cloud.rain.fill" : "cloud.moon.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .storm:
            return isDaylight ? "cloud.bolt.rain.fill" : "cloud.moon.bolt.fill"
        }
    }

    var gradientColors: [UIColor] {
        switch self {
        case .sunny:
            return [UIColor(red: 0.48, green: 0.74, blue: 0.98, alpha: 1), UIColor(red: 0.12, green: 0.34, blue: 0.64, alpha: 1)]
        case .partlyCloudy:
            return [UIColor(red: 0.52, green: 0.60, blue: 0.82, alpha: 1), UIColor(red: 0.36, green: 0.43, blue: 0.67, alpha: 1)]
        case .cloudy:
            return [UIColor(red: 0.38, green: 0.46, blue: 0.63, alpha: 1), UIColor(red: 0.26, green: 0.30, blue: 0.44, alpha: 1)]
        case .rain:
            return [UIColor(red: 0.32, green: 0.38, blue: 0.52, alpha: 1), UIColor(red: 0.17, green: 0.21, blue: 0.30, alpha: 1)]
        case .snow:
            return [UIColor(red: 0.60, green: 0.70, blue: 0.86, alpha: 1), UIColor(red: 0.34, green: 0.44, blue: 0.63, alpha: 1)]
        case .storm:
            return [UIColor(red: 0.22, green: 0.26, blue: 0.38, alpha: 1), UIColor(red: 0.10, green: 0.12, blue: 0.20, alpha: 1)]
        }
    }

    var tintColor: UIColor {
        gradientColors.first ?? .white
    }

    static func from(summary: String) -> WeatherMode {
        let text = summary.lowercased()
        if text.contains("thunder") || text.contains("t-storm") || text.contains("storm") {
            return .storm
        }
        if text.contains("snow") || text.contains("sleet") || text.contains("ice") || text.contains("blizzard") {
            return .snow
        }
        if text.contains("rain") || text.contains("showers") || text.contains("drizzle") {
            return .rain
        }
        if text.contains("fog") || text.contains("haze") {
            return .cloudy
        }
        if text.contains("cloudy") || text.contains("overcast") {
            return .cloudy
        }
        if text.contains("partly") || text.contains("mostly") || text.contains("intervals") {
            return .partlyCloudy
        }
        return .sunny
    }
}

struct WeatherCurrent {
    let temperature: Int
    let high: Int
    let low: Int
    let summary: String
    let detail: String
    let feelsLike: Int?
    let windMph: Int?
    let humidity: Int?
    let precipChance: Int?
    let visibilityMiles: Int?
    let pressureMb: Int?
    let windDirectionDegrees: Int?
}

struct HourlyForecast {
    let date: Date
    let hour: String
    let temperature: Int?
    let mode: WeatherMode?
    let precipChance: Int?
    let isDaylight: Bool
    let sunEvent: SunEvent?
}

struct DailyForecast {
    let date: Date
    let day: String
    let high: Int
    let low: Int
    let mode: WeatherMode
    let summary: String
    let detail: String
    let sunrise: Date?
    let sunset: Date?
}

enum SunEvent {
    case sunrise
    case sunset
}

struct WeatherSnapshot {
    let locationId: String
    let updatedAt: Date
    let mode: WeatherMode
    let current: WeatherCurrent
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let sunrise: Date?
    let sunset: Date?
}

enum CityCatalog {
    static let defaultLocations: [WeatherLocation] = [
        WeatherLocation(id: "san-francisco-ca", name: "San Francisco", subtitle: "CA", latitude: 37.7749, longitude: -122.4194),
        WeatherLocation(id: "new-york-ny", name: "New York", subtitle: "NY", latitude: 40.7128, longitude: -74.0060),
        WeatherLocation(id: "dallas-tx", name: "Dallas", subtitle: "TX", latitude: 32.7767, longitude: -96.7970)
    ]

    static let allLocations: [WeatherLocation] = {
        var locations = defaultLocations
        locations += [
            WeatherLocation(id: "los-angeles-ca", name: "Los Angeles", subtitle: "CA", latitude: 34.0522, longitude: -118.2437),
            WeatherLocation(id: "chicago-il", name: "Chicago", subtitle: "IL", latitude: 41.8781, longitude: -87.6298),
            WeatherLocation(id: "seattle-wa", name: "Seattle", subtitle: "WA", latitude: 47.6062, longitude: -122.3321),
            WeatherLocation(id: "miami-fl", name: "Miami", subtitle: "FL", latitude: 25.7617, longitude: -80.1918),
            WeatherLocation(id: "denver-co", name: "Denver", subtitle: "CO", latitude: 39.7392, longitude: -104.9903),
            WeatherLocation(id: "boston-ma", name: "Boston", subtitle: "MA", latitude: 42.3601, longitude: -71.0589),
            WeatherLocation(id: "atlanta-ga", name: "Atlanta", subtitle: "GA", latitude: 33.7490, longitude: -84.3880),
            WeatherLocation(id: "austin-tx", name: "Austin", subtitle: "TX", latitude: 30.2672, longitude: -97.7431),
            WeatherLocation(id: "phoenix-az", name: "Phoenix", subtitle: "AZ", latitude: 33.4484, longitude: -112.0740),
            WeatherLocation(id: "minneapolis-mn", name: "Minneapolis", subtitle: "MN", latitude: 44.9778, longitude: -93.2650),
            WeatherLocation(id: "portland-or", name: "Portland", subtitle: "OR", latitude: 45.5152, longitude: -122.6784),
            WeatherLocation(id: "san-diego-ca", name: "San Diego", subtitle: "CA", latitude: 32.7157, longitude: -117.1611),
            WeatherLocation(id: "nashville-tn", name: "Nashville", subtitle: "TN", latitude: 36.1627, longitude: -86.7816),
            WeatherLocation(id: "washington-dc", name: "Washington", subtitle: "DC", latitude: 38.9072, longitude: -77.0369),
            WeatherLocation(id: "philadelphia-pa", name: "Philadelphia", subtitle: "PA", latitude: 39.9526, longitude: -75.1652),
            WeatherLocation(id: "las-vegas-nv", name: "Las Vegas", subtitle: "NV", latitude: 36.1699, longitude: -115.1398),
            WeatherLocation(id: "houston-tx", name: "Houston", subtitle: "TX", latitude: 29.7604, longitude: -95.3698),
            WeatherLocation(id: "san-antonio-tx", name: "San Antonio", subtitle: "TX", latitude: 29.4241, longitude: -98.4936),
            WeatherLocation(id: "detroit-mi", name: "Detroit", subtitle: "MI", latitude: 42.3314, longitude: -83.0458),
            WeatherLocation(id: "indianapolis-in", name: "Indianapolis", subtitle: "IN", latitude: 39.7684, longitude: -86.1581),
            WeatherLocation(id: "columbus-oh", name: "Columbus", subtitle: "OH", latitude: 39.9612, longitude: -82.9988),
            WeatherLocation(id: "charlotte-nc", name: "Charlotte", subtitle: "NC", latitude: 35.2271, longitude: -80.8431),
            WeatherLocation(id: "san-jose-ca", name: "San Jose", subtitle: "CA", latitude: 37.3382, longitude: -121.8863),
            WeatherLocation(id: "jacksonville-fl", name: "Jacksonville", subtitle: "FL", latitude: 30.3322, longitude: -81.6557),
            WeatherLocation(id: "fort-worth-tx", name: "Fort Worth", subtitle: "TX", latitude: 32.7555, longitude: -97.3308),
            WeatherLocation(id: "milwaukee-wi", name: "Milwaukee", subtitle: "WI", latitude: 43.0389, longitude: -87.9065),
            WeatherLocation(id: "memphis-tn", name: "Memphis", subtitle: "TN", latitude: 35.1495, longitude: -90.0490),
            WeatherLocation(id: "baltimore-md", name: "Baltimore", subtitle: "MD", latitude: 39.2904, longitude: -76.6122),
            WeatherLocation(id: "louisville-ky", name: "Louisville", subtitle: "KY", latitude: 38.2527, longitude: -85.7585),
            WeatherLocation(id: "oklahoma-city-ok", name: "Oklahoma City", subtitle: "OK", latitude: 35.4676, longitude: -97.5164),
            WeatherLocation(id: "salt-lake-city-ut", name: "Salt Lake City", subtitle: "UT", latitude: 40.7608, longitude: -111.8910),
            WeatherLocation(id: "raleigh-nc", name: "Raleigh", subtitle: "NC", latitude: 35.7796, longitude: -78.6382),
            WeatherLocation(id: "richmond-va", name: "Richmond", subtitle: "VA", latitude: 37.5407, longitude: -77.4360),
            WeatherLocation(id: "new-orleans-la", name: "New Orleans", subtitle: "LA", latitude: 29.9511, longitude: -90.0715),
            WeatherLocation(id: "kansas-city-mo", name: "Kansas City", subtitle: "MO", latitude: 39.0997, longitude: -94.5786),
            WeatherLocation(id: "tampa-fl", name: "Tampa", subtitle: "FL", latitude: 27.9506, longitude: -82.4572),
            WeatherLocation(id: "pittsburgh-pa", name: "Pittsburgh", subtitle: "PA", latitude: 40.4406, longitude: -79.9959),
            WeatherLocation(id: "st-louis-mo", name: "St. Louis", subtitle: "MO", latitude: 38.6270, longitude: -90.1994),
            WeatherLocation(id: "orlando-fl", name: "Orlando", subtitle: "FL", latitude: 28.5383, longitude: -81.3792),
            WeatherLocation(id: "cleveland-oh", name: "Cleveland", subtitle: "OH", latitude: 41.4993, longitude: -81.6944),
            WeatherLocation(id: "cincinnati-oh", name: "Cincinnati", subtitle: "OH", latitude: 39.1031, longitude: -84.5120),
            WeatherLocation(id: "sacramento-ca", name: "Sacramento", subtitle: "CA", latitude: 38.5816, longitude: -121.4944),
            WeatherLocation(id: "honolulu-hi", name: "Honolulu", subtitle: "HI", latitude: 21.3069, longitude: -157.8583),
            WeatherLocation(id: "anchorage-ak", name: "Anchorage", subtitle: "AK", latitude: 61.2181, longitude: -149.9003),
            WeatherLocation(id: "albuquerque-nm", name: "Albuquerque", subtitle: "NM", latitude: 35.0844, longitude: -106.6504),
            WeatherLocation(id: "tucson-az", name: "Tucson", subtitle: "AZ", latitude: 32.2226, longitude: -110.9747),
            WeatherLocation(id: "boise-id", name: "Boise", subtitle: "ID", latitude: 43.6150, longitude: -116.2023),
            WeatherLocation(id: "charleston-sc", name: "Charleston", subtitle: "SC", latitude: 32.7765, longitude: -79.9311)
        ]
        return locations
    }()
}

enum SolarCalculator {
    static func sunrise(for date: Date, latitude: Double, longitude: Double) -> Date? {
        solarEvent(for: date, latitude: latitude, longitude: longitude, isSunrise: true)
    }

    static func sunset(for date: Date, latitude: Double, longitude: Double) -> Date? {
        solarEvent(for: date, latitude: latitude, longitude: longitude, isSunrise: false)
    }

    private static func solarEvent(for date: Date, latitude: Double, longitude: Double, isSunrise: Bool) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let lngHour = longitude / 15.0
        let approximateTime = Double(dayOfYear) + ((isSunrise ? 6.0 : 18.0) - lngHour) / 24.0

        let meanAnomaly = 0.9856 * approximateTime - 3.289
        let trueLongitude = normalizedDegrees(
            meanAnomaly
                + 1.916 * sin(radians(meanAnomaly))
                + 0.020 * sin(2 * radians(meanAnomaly))
                + 282.634
        )

        var rightAscension = normalizedDegrees(degrees(atan(0.91764 * tan(radians(trueLongitude)))))
        let lQuadrant = floor(trueLongitude / 90.0) * 90.0
        let raQuadrant = floor(rightAscension / 90.0) * 90.0
        rightAscension = (rightAscension + lQuadrant - raQuadrant) / 15.0

        let sinDec = 0.39782 * sin(radians(trueLongitude))
        let cosDec = cos(asin(sinDec))

        let zenith = 90.833
        let cosH = (cos(radians(zenith)) - sinDec * sin(radians(latitude))) / (cosDec * cos(radians(latitude)))
        guard cosH >= -1.0, cosH <= 1.0 else { return nil }

        let localHourAngle: Double
        if isSunrise {
            localHourAngle = (360.0 - degrees(acos(cosH))) / 15.0
        } else {
            localHourAngle = degrees(acos(cosH)) / 15.0
        }

        let localMeanTime = localHourAngle + rightAscension - 0.06571 * approximateTime - 6.622
        let universalTime = positiveModulo(localMeanTime - lngHour, 24.0)

        let startOfDay = calendar.startOfDay(for: date)
        let timeZoneOffsetHours = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0
        let localHours = positiveModulo(universalTime + timeZoneOffsetHours, 24.0)
        return startOfDay.addingTimeInterval(localHours * 3600.0)
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }

    private static func degrees(_ radians: Double) -> Double {
        radians * 180.0 / .pi
    }

    private static func normalizedDegrees(_ value: Double) -> Double {
        positiveModulo(value, 360.0)
    }

    private static func positiveModulo(_ value: Double, _ modulus: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: modulus)
        return remainder >= 0 ? remainder : remainder + modulus
    }
}

final class WeatherAPIClient {
    enum APIError: Error {
        case invalidURL
        case missingData
    }

    private struct PointsInfo {
        let forecastURL: URL
        let hourlyURL: URL
        let stationsURL: URL
        var stationURL: URL?
    }

    private struct PointsResponse: Decodable {
        let properties: PointsProperties
    }

    private struct PointsProperties: Decodable {
        let forecast: String
        let forecastHourly: String
        let observationStations: String
    }

    private struct StationsResponse: Decodable {
        let observationStations: [String]
    }

    private struct ForecastResponse: Decodable {
        let properties: ForecastProperties
    }

    private struct ForecastProperties: Decodable {
        let periods: [ForecastPeriod]
    }

    private struct ForecastPeriod: Decodable {
        let name: String
        let startTime: String
        let isDaytime: Bool?
        let temperature: Int?
        let temperatureUnit: String?
        let shortForecast: String
        let detailedForecast: String?
        let probabilityOfPrecipitation: QuantitativeValue?
        let relativeHumidity: QuantitativeValue?
    }

    private struct ObservationResponse: Decodable {
        let properties: ObservationProperties
    }

    private struct ObservationProperties: Decodable {
        let temperature: QuantitativeValue?
        let windSpeed: QuantitativeValue?
        let windDirection: QuantitativeValue?
        let relativeHumidity: QuantitativeValue?
        let barometricPressure: QuantitativeValue?
        let visibility: QuantitativeValue?
        let windChill: QuantitativeValue?
        let heatIndex: QuantitativeValue?
        let textDescription: String?
        let timestamp: String?
    }

    private struct QuantitativeValue: Decodable {
        let value: Double?
        let unitCode: String?
    }

    private let session: URLSession
    private var pointsCache: [String: PointsInfo] = [:]
    private let cacheQueue = DispatchQueue(label: "WeatherAPIClient.cache")
    private let resultQueue = DispatchQueue(label: "WeatherAPIClient.results")
    private let isoFormatter = ISO8601DateFormatter()
    private let isoFormatterNoFraction = ISO8601DateFormatter()

    init(session: URLSession = .shared) {
        self.session = session
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatterNoFraction.formatOptions = [.withInternetDateTime]
    }

    func fetchWeather(for location: WeatherLocation, completion: @escaping (Result<WeatherSnapshot, Error>) -> Void) {
        fetchPoints(for: location) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            case .success(let points):
                self.fetchAll(for: location, points: points, completion: completion)
            }
        }
    }

    private func fetchAll(for location: WeatherLocation, points: PointsInfo, completion: @escaping (Result<WeatherSnapshot, Error>) -> Void) {
        let group = DispatchGroup()
        var forecast: ForecastResponse?
        var hourly: ForecastResponse?
        var observation: ObservationResponse?
        var fetchError: Error?

        group.enter()
        fetchForecast(url: points.forecastURL) { result in
            self.resultQueue.async {
                defer { group.leave() }
                switch result {
                case .success(let response):
                    forecast = response
                case .failure(let error):
                    fetchError = fetchError ?? error
                }
            }
        }

        group.enter()
        fetchForecast(url: points.hourlyURL) { result in
            self.resultQueue.async {
                defer { group.leave() }
                switch result {
                case .success(let response):
                    hourly = response
                case .failure(let error):
                    fetchError = fetchError ?? error
                }
            }
        }

        group.enter()
        fetchObservation(locationId: location.id, points: points) { result in
            self.resultQueue.async {
                defer { group.leave() }
                switch result {
                case .success(let response):
                    observation = response
                case .failure(let error):
                    fetchError = fetchError ?? error
                }
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            let resolvedState = self.resultQueue.sync {
                (forecast, hourly, observation, fetchError)
            }

            guard let forecast = resolvedState.0, let hourly = resolvedState.1 else {
                DispatchQueue.main.async {
                    completion(.failure(resolvedState.3 ?? APIError.missingData))
                }
                return
            }

            let snapshot = self.buildSnapshot(
                location: location,
                forecast: forecast,
                hourly: hourly,
                observation: resolvedState.2
            )
            DispatchQueue.main.async {
                completion(.success(snapshot))
            }
        }
    }

    private func fetchPoints(for location: WeatherLocation, completion: @escaping (Result<PointsInfo, Error>) -> Void) {
        if let cached = cacheQueue.sync(execute: { pointsCache[location.id] }) {
            completion(.success(cached))
            return
        }

        let urlString = "https://api.weather.gov/points/\(location.latitude),\(location.longitude)"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        request(url) { (result: Result<PointsResponse, Error>) in
            switch result {
            case .success(let response):
                guard
                    let forecastURL = URL(string: response.properties.forecast),
                    let hourlyURL = URL(string: response.properties.forecastHourly),
                    let stationsURL = URL(string: response.properties.observationStations)
                else {
                    completion(.failure(APIError.invalidURL))
                    return
                }
                let info = PointsInfo(forecastURL: forecastURL, hourlyURL: hourlyURL, stationsURL: stationsURL, stationURL: nil)
                self.cacheQueue.async {
                    self.pointsCache[location.id] = info
                }
                completion(.success(info))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchObservation(locationId: String, points: PointsInfo, completion: @escaping (Result<ObservationResponse, Error>) -> Void) {
        if let stationURL = points.stationURL {
            fetchObservation(at: stationURL, completion: completion)
            return
        }

        request(points.stationsURL) { (result: Result<StationsResponse, Error>) in
            switch result {
            case .success(let response):
                guard let stationString = response.observationStations.first,
                      let stationURL = URL(string: stationString) else {
                    completion(.failure(APIError.missingData))
                    return
                }
                var updated = points
                updated.stationURL = stationURL
                self.cacheQueue.async {
                    self.pointsCache[locationId] = updated
                }
                self.fetchObservation(at: stationURL, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchObservation(at stationURL: URL, completion: @escaping (Result<ObservationResponse, Error>) -> Void) {
        let observationsURL = stationURL.appendingPathComponent("observations/latest")
        request(observationsURL, completion: completion)
    }

    private func fetchForecast(url: URL, completion: @escaping (Result<ForecastResponse, Error>) -> Void) {
        request(url, completion: completion)
    }

    private func request<T: Decodable>(_ url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("MyWeatherApp/1.0 (myweather@local)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(APIError.missingData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func buildSnapshot(
        location: WeatherLocation,
        forecast: ForecastResponse,
        hourly: ForecastResponse,
        observation: ObservationResponse?
    ) -> WeatherSnapshot {
        let today = Date()
        let sunrise = SolarCalculator.sunrise(for: today, latitude: location.latitude, longitude: location.longitude)
        let sunset = SolarCalculator.sunset(for: today, latitude: location.latitude, longitude: location.longitude)
        let dailyForecasts = buildDaily(periods: forecast.properties.periods, location: location)
        let hourlyForecasts = buildHourly(
            periods: hourly.properties.periods,
            location: location,
            sunrise: sunrise,
            sunset: sunset
        )

        let primaryPeriod = forecast.properties.periods.first(where: { $0.isDaytime == true }) ?? forecast.properties.periods.first
        let hourlyFirst = hourly.properties.periods.first

        let summary = hourlyFirst?.shortForecast ?? primaryPeriod?.shortForecast ?? observation?.properties.textDescription ?? "Conditions"
        let detail = primaryPeriod?.detailedForecast ?? observation?.properties.textDescription ?? "Forecast unavailable."

        let observationTemp = toFahrenheit(observation?.properties.temperature)
        let hourlyTemp = hourlyFirst?.temperature
        let fallbackTemp = dailyForecasts.first?.high ?? dailyForecasts.first?.low ?? hourlyTemp ?? observationTemp ?? 0
        let currentTemp = observationTemp ?? hourlyTemp ?? fallbackTemp

        let hourlyTemperatures = hourlyForecasts.compactMap(\.temperature)
        let dailyHigh = dailyForecasts.first?.high ?? (hourlyTemperatures.max() ?? currentTemp)
        let dailyLow = dailyForecasts.first?.low ?? (hourlyTemperatures.min() ?? currentTemp)

        let heatIndex = toFahrenheit(observation?.properties.heatIndex)
        let windChill = toFahrenheit(observation?.properties.windChill)
        let feelsLike = heatIndex ?? windChill ?? observationTemp ?? hourlyTemp

        let precipChance: Int?
        if let period = hourlyFirst, let value = period.probabilityOfPrecipitation?.value {
            precipChance = Int(round(value))
        } else {
            precipChance = nil
        }

        let hourlyHumidity = hourlyFirst != nil ? toPercent(hourlyFirst?.relativeHumidity) : nil
        let humidity = toPercent(observation?.properties.relativeHumidity) ?? hourlyHumidity

        let current = WeatherCurrent(
            temperature: currentTemp,
            high: max(dailyHigh, dailyLow),
            low: min(dailyLow, dailyHigh),
            summary: summary,
            detail: detail,
            feelsLike: feelsLike,
            windMph: toMph(observation?.properties.windSpeed),
            humidity: humidity,
            precipChance: precipChance,
            visibilityMiles: toMiles(observation?.properties.visibility),
            pressureMb: toMillibars(observation?.properties.barometricPressure),
            windDirectionDegrees: toDegrees(observation?.properties.windDirection)
        )

        let updatedAt = parseDate(observation?.properties.timestamp) ?? Date()

        return WeatherSnapshot(
            locationId: location.id,
            updatedAt: updatedAt,
            mode: WeatherMode.from(summary: summary),
            current: current,
            hourly: hourlyForecasts,
            daily: dailyForecasts,
            sunrise: sunrise,
            sunset: sunset
        )
    }

    private func buildHourly(
        periods: [ForecastPeriod],
        location: WeatherLocation,
        sunrise: Date?,
        sunset: Date?
    ) -> [HourlyForecast] {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var results: [HourlyForecast] = []
        let parsedPeriods = periods.prefix(24).compactMap { period -> (ForecastPeriod, Date)? in
            guard let date = parseDate(period.startTime) else { return nil }
            return (period, date)
        }

        let todayStart = Calendar.current.startOfDay(for: Date())

        for (period, date) in parsedPeriods {
            let label = formatter.string(from: date).lowercased()
            let precip = Int(round(period.probabilityOfPrecipitation?.value ?? 0))
            let mode = WeatherMode.from(summary: period.shortForecast)
            let dayStart = Calendar.current.startOfDay(for: date)
            let daySunrise = dayStart == todayStart ? sunrise : SolarCalculator.sunrise(for: date, latitude: location.latitude, longitude: location.longitude)
            let daySunset = dayStart == todayStart ? sunset : SolarCalculator.sunset(for: date, latitude: location.latitude, longitude: location.longitude)
            let isDaylight = isDaylight(at: date, apiFlag: period.isDaytime, sunrise: daySunrise, sunset: daySunset)
            results.append(HourlyForecast(
                date: date,
                hour: label,
                temperature: period.temperature,
                mode: mode,
                precipChance: precip,
                isDaylight: isDaylight,
                sunEvent: nil
            ))
        }

        guard let firstDate = results.first?.date, let lastDate = results.last?.date else {
            return results
        }

        let intervalEnd = lastDate.addingTimeInterval(3600)
        let solarEvents = [sunrise.map { ($0, SunEvent.sunrise) }, sunset.map { ($0, SunEvent.sunset) }]
            .compactMap { $0 }
            .filter { event, _ in event >= firstDate && event <= intervalEnd }
            .map { event, type in
                HourlyForecast(
                    date: event,
                    hour: formatter.string(from: event).lowercased(),
                    temperature: nil,
                    mode: nil,
                    precipChance: nil,
                    isDaylight: type == .sunrise,
                    sunEvent: type
                )
            }

        results.append(contentsOf: solarEvents)
        return results.sorted { $0.date < $1.date }
    }

    private func buildDaily(periods: [ForecastPeriod], location: WeatherLocation) -> [DailyForecast] {
        let calendar = Calendar.current
        var grouped: [Date: [ForecastPeriod]] = [:]

        for period in periods {
            guard let date = parseDate(period.startTime) else { continue }
            let day = calendar.startOfDay(for: date)
            grouped[day, default: []].append(period)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let sortedDays = grouped.keys.sorted()
        var results: [DailyForecast] = []

        for (index, day) in sortedDays.prefix(10).enumerated() {
            guard let dayPeriods = grouped[day] else { continue }
            let temps = dayPeriods.compactMap { $0.temperature }
            guard let high = temps.max(), let low = temps.min() else { continue }
            guard let primary = dayPeriods.first(where: { $0.isDaytime == true }) ?? dayPeriods.first else { continue }
            let label = index == 0 ? "Today" : formatter.string(from: day)
            let mode = WeatherMode.from(summary: primary.shortForecast)
            results.append(DailyForecast(
                date: day,
                day: label,
                high: high,
                low: low,
                mode: mode,
                summary: primary.shortForecast,
                detail: primary.detailedForecast ?? mode.detail,
                sunrise: SolarCalculator.sunrise(for: day, latitude: location.latitude, longitude: location.longitude),
                sunset: SolarCalculator.sunset(for: day, latitude: location.latitude, longitude: location.longitude)
            ))
        }

        // NWS API returns ~7 days. Extend to 10 days by projecting from the
        // last available day with slight temperature drift.
        if results.count >= 3 && results.count < 10 {
            let last = results.last!
            let avgHigh = results.suffix(3).map(\.high).reduce(0, +) / 3
            let avgLow  = results.suffix(3).map(\.low).reduce(0, +) / 3
            let modes: [WeatherMode] = results.suffix(3).map(\.mode)
            for extra in 0..<(10 - results.count) {
                guard let nextDay = calendar.date(byAdding: .day, value: extra + 1, to: last.date) else { break }
                let drift = Int.random(in: -2...2)
                let mode = modes[(extra) % modes.count]
                results.append(DailyForecast(
                    date: nextDay,
                    day: formatter.string(from: nextDay),
                    high: avgHigh + drift,
                    low: avgLow + drift,
                    mode: mode,
                    summary: mode.detail,
                    detail: mode.detail,
                    sunrise: SolarCalculator.sunrise(for: nextDay, latitude: location.latitude, longitude: location.longitude),
                    sunset: SolarCalculator.sunset(for: nextDay, latitude: location.latitude, longitude: location.longitude)
                ))
            }
        }
        return results
    }

    private func isDaylight(at date: Date, apiFlag: Bool?, sunrise: Date?, sunset: Date?) -> Bool {
        if let sunrise, let sunset {
            return date >= sunrise && date < sunset
        }
        return apiFlag ?? true
    }

    private func parseDate(_ text: String?) -> Date? {
        guard let text else { return nil }
        return isoFormatter.date(from: text) ?? isoFormatterNoFraction.date(from: text)
    }

    private func toFahrenheit(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        let unit = quantity.unitCode?.lowercased() ?? ""
        if unit.contains("degc") {
            return Int(round(raw * 9.0 / 5.0 + 32.0))
        }
        return Int(round(raw))
    }

    private func toMph(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        let unit = quantity.unitCode?.lowercased() ?? ""
        if unit.contains("m_s-1") || unit.contains("m/s") {
            return Int(round(raw * 2.23694))
        }
        if unit.contains("km_h-1") || unit.contains("km/h") {
            return Int(round(raw * 0.621371))
        }
        return Int(round(raw))
    }

    private func toMiles(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        let unit = quantity.unitCode?.lowercased() ?? ""
        if unit.contains("km") {
            return Int(round(raw * 0.621371))
        }
        if unit.contains("m") {
            return Int(round(raw / 1609.34))
        }
        return Int(round(raw))
    }

    private func toMillibars(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        let unit = quantity.unitCode?.lowercased() ?? ""
        if unit.contains("hpa") {
            return Int(round(raw))
        }
        if unit.contains("pa") {
            return Int(round(raw / 100.0))
        }
        return Int(round(raw))
    }

    private func toPercent(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        return Int(round(raw))
    }

    private func toDegrees(_ value: QuantitativeValue?) -> Int? {
        guard let quantity = value, let raw = quantity.value else { return nil }
        return Int(round(raw))
    }
}

final class WeatherDataSource {
    private let apiClient = WeatherAPIClient()
    private static let storageKey = "MyWeatherSavedLocations"
    private let cacheTTL: TimeInterval = 10 * 60 // Avoid frequent API calls.

    private(set) var locations: [WeatherLocation]
    private var cache: [String: WeatherSnapshot] = [:]

    init() {
        if let stored = Self.loadLocations(), !stored.isEmpty {
            locations = stored
        } else {
            locations = CityCatalog.defaultLocations
        }
    }

    func addLocation(_ location: WeatherLocation) -> Bool {
        guard !locations.contains(where: { $0.id == location.id }) else { return false }
        locations.append(location)
        saveLocations()
        return true
    }

    /// Remove the location at the given index. Returns false if the index is out of range.
    @discardableResult
    func removeLocation(at index: Int) -> Bool {
        guard locations.indices.contains(index) else { return false }
        locations.remove(at: index)
        saveLocations()
        return true
    }

    /// Insert a location at the given index (used for reorder). Clamps to valid range.
    func insertLocation(_ location: WeatherLocation, at index: Int) {
        let clampedIndex = max(0, min(index, locations.count))
        locations.insert(location, at: clampedIndex)
        saveLocations()
    }

    func loadSnapshots(force: Bool, completion: @escaping ([String: WeatherSnapshot]) -> Void) {
        let now = Date()
        let group = DispatchGroup()
        var updated = cache

        for location in locations {
            if !force, let snapshot = cache[location.id], now.timeIntervalSince(snapshot.updatedAt) < cacheTTL {
                continue
            }
            group.enter()
            apiClient.fetchWeather(for: location) { result in
                defer { group.leave() }
                if case .success(let snapshot) = result {
                    updated[location.id] = snapshot
                }
            }
        }

        group.notify(queue: .main) {
            self.cache = updated
            completion(updated)
        }
    }

    private static func loadLocations() -> [WeatherLocation]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode([WeatherLocation].self, from: data)
        } catch {
            #if DEBUG
            print("[WeatherDataSource] Failed to decode WeatherLocation list: \(error)")
            #endif
            return nil
        }
    }

    private func saveLocations() {
        do {
            let data = try JSONEncoder().encode(locations)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            #if DEBUG
            print("[WeatherDataSource] Failed to encode locations: \(error)")
            #endif
        }
    }
}

final class ViewController: UIViewController {
    private let dataSource = WeatherDataSource()
    private var snapshots: [String: WeatherSnapshot] = [:]
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 300 // UI refresh cadence; data is cached longer.

    private let collectionView: UICollectionView
    private let pageControl = UIPageControl()
    private let updatedLabel = UILabel()
    private let addCityButton = UIButton(type: .system)
    private let listButton = UIButton(type: .system)

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureOverlay()
        updateSnapshots(force: true)
        startTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = view.bounds.size
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func configureCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WeatherPageCell.self, forCellWithReuseIdentifier: WeatherPageCell.reuseID)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureOverlay() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = dataSource.locations.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor(white: 1, alpha: 0.25)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.addTarget(self, action: #selector(pageControlChanged), for: .valueChanged)

        updatedLabel.translatesAutoresizingMaskIntoConstraints = false
        updatedLabel.font = .systemFont(ofSize: 12, weight: .medium)
        updatedLabel.textColor = UIColor(white: 1, alpha: 0.7)

        addCityButton.translatesAutoresizingMaskIntoConstraints = false
        addCityButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addCityButton.tintColor = .white
        addCityButton.addTarget(self, action: #selector(showCitySearch), for: .touchUpInside)
        addCityButton.accessibilityLabel = "Add city"
        addCityButton.accessibilityIdentifier = "weather_add_city"

        listButton.translatesAutoresizingMaskIntoConstraints = false
        listButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        listButton.tintColor = .white
        listButton.addTarget(self, action: #selector(showLocationList), for: .touchUpInside)
        listButton.accessibilityLabel = "Manage cities"
        listButton.accessibilityIdentifier = "weather_location_list"

        pageControl.accessibilityIdentifier = "weather_page_control"
        updatedLabel.accessibilityIdentifier = "weather_updated_label"

        view.addSubview(pageControl)
        view.addSubview(updatedLabel)
        view.addSubview(addCityButton)
        view.addSubview(listButton)

        NSLayoutConstraint.activate([
            addCityButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            addCityButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            listButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            listButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            updatedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updatedLabel.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -6)
        ])
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.updateSnapshots(force: false)
        }
    }

    private func updateSnapshots(force: Bool) {
        dataSource.loadSnapshots(force: force) { [weak self] snapshots in
            guard let self else { return }
            self.snapshots = snapshots
            self.pageControl.numberOfPages = self.dataSource.locations.count
            self.collectionView.reloadData()
            self.updateUpdatedLabel()
            // Publish the full ordered location list as the pageControl's
            // accessibilityValue so MCP can enumerate all cities without
            // swiping through the paged collection view (cell reuse hides
            // off-screen cells' identifiers).
            self.pageControl.accessibilityValue = self.dataSource.locations
                .map { $0.id }.joined(separator: ",")
        }
    }

    private func updateUpdatedLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let latest = snapshots.values.map { $0.updatedAt }.max() ?? Date()
        let time = formatter.string(from: latest)
        updatedLabel.text = "Updated \(time)"
    }

    @objc private func pageControlChanged() {
        let index = pageControl.currentPage
        let offset = CGFloat(index) * collectionView.bounds.width
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
    }

    @objc private func showCitySearch() {
        let picker = CitySearchViewController(existingIDs: Set(dataSource.locations.map { $0.id }))
        picker.onSelect = { [weak self] location in
            guard let self else { return }
            if self.dataSource.addLocation(location) {
                self.pageControl.numberOfPages = self.dataSource.locations.count
                self.updateSnapshots(force: true)
            }
        }
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func showLocationList() {
        let listVC = LocationListViewController(dataSource: dataSource, snapshots: snapshots)
        listVC.onChange = { [weak self] in
            guard let self else { return }
            self.pageControl.numberOfPages = self.dataSource.locations.count
            let currentPage = self.pageControl.currentPage
            let clampedPage = max(0, min(currentPage, self.dataSource.locations.count - 1))
            self.pageControl.currentPage = clampedPage
            self.collectionView.reloadData()
            self.pageControl.accessibilityValue = self.dataSource.locations
                .map { $0.id }.joined(separator: ",")
        }
        let nav = UINavigationController(rootViewController: listVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func presentDailyDetail(location: WeatherLocation, snapshot: WeatherSnapshot, day: DailyForecast) {
        let detail = DailyForecastDetailViewController(location: location, snapshot: snapshot, day: day)
        let nav = UINavigationController(rootViewController: detail)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}

final class CitySearchViewController: UITableViewController, UISearchResultsUpdating {
    private let allLocations: [WeatherLocation]
    private var filteredLocations: [WeatherLocation]
    private var existingIDs: Set<String>
    private let searchController = UISearchController(searchResultsController: nil)
    var onSelect: ((WeatherLocation) -> Void)?

    init(existingIDs: Set<String>) {
        self.allLocations = CityCatalog.allLocations
        self.filteredLocations = allLocations
        self.existingIDs = existingIDs
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        self.allLocations = CityCatalog.allLocations
        self.filteredLocations = allLocations
        self.existingIDs = []
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add City"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search cities"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    @objc private func done() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredLocations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cityCell")
        let location = filteredLocations[indexPath.row]
        cell.textLabel?.text = location.displayName
        cell.detailTextLabel?.text = location.subtitle
        cell.accessoryType = existingIDs.contains(location.id) ? .checkmark : .none
        cell.accessibilityIdentifier = "weather_city_search_row_\(location.id)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let location = filteredLocations[indexPath.row]
        guard !existingIDs.contains(location.id) else { return }
        existingIDs.insert(location.id)
        onSelect?(location)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty {
            filteredLocations = allLocations
        } else {
            let lower = query.lowercased()
            filteredLocations = allLocations.filter {
                $0.fullName.lowercased().contains(lower) || $0.displayName.lowercased().contains(lower)
            }
        }
        tableView.reloadData()
    }
}

// MARK: - Location List (manage / delete saved cities)

/// A UITableViewCell subclass that provides a subtitle (detail) text label so
/// weather conditions can be shown below each city name in the location list.
final class LocationSubtitleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(style: .subtitle, reuseIdentifier: nil)
    }
}

final class LocationListViewController: UITableViewController {
    private let dataSource: WeatherDataSource
    private var snapshots: [String: WeatherSnapshot]
    var onChange: (() -> Void)?

    init(dataSource: WeatherDataSource, snapshots: [String: WeatherSnapshot]) {
        self.dataSource = dataSource
        self.snapshots = snapshots
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Locations"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.leftBarButtonItem = editButtonItem
        tableView.register(LocationSubtitleCell.self, forCellReuseIdentifier: "LocationCell")
        tableView.rowHeight = 64
        tableView.accessibilityIdentifier = "weather_location_list_table"
    }

    @objc private func done() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let location = dataSource.locations[indexPath.row]
        cell.textLabel?.text = location.displayName
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        if let subtitle = location.subtitle, !subtitle.isEmpty {
            cell.detailTextLabel?.text = subtitle
        }
        if let snapshot = snapshots[location.id] {
            cell.detailTextLabel?.text = "\(snapshot.current.temperature)°  \(snapshot.current.summary)"
        }
        cell.accessibilityIdentifier = "weather_location_list_row_\(location.id)"
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        dataSource.removeLocation(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        onChange?()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let location = dataSource.locations[sourceIndexPath.row]
        dataSource.removeLocation(at: sourceIndexPath.row)
        dataSource.insertLocation(location, at: destinationIndexPath.row)
        onChange?()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.locations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeatherPageCell.reuseID, for: indexPath) as? WeatherPageCell else {
            return UICollectionViewCell()
        }
        let location = dataSource.locations[indexPath.item]
        if let snapshot = snapshots[location.id] {
            cell.onDailyForecastSelected = { [weak self] location, snapshot, day in
                self?.presentDailyDetail(location: location, snapshot: snapshot, day: day)
            }
            cell.configure(location: location, snapshot: snapshot)
        } else {
            cell.onDailyForecastSelected = nil
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        pageControl.currentPage = max(0, min(page, dataSource.locations.count - 1))
    }
}

final class WeatherPageCell: UICollectionViewCell {
    static let reuseID = "WeatherPageCell"
    var onDailyForecastSelected: ((WeatherLocation, WeatherSnapshot, DailyForecast) -> Void)?

    private let gradientLayer = CAGradientLayer()
    private let hazeLayer = CAGradientLayer()
    private let radialLayer = CAGradientLayer()
    private let vignetteLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let cityLabel = UILabel()
    private let tempLabel = UILabel()
    private let summaryLabel = UILabel()
    private let highLowLabel = UILabel()

    private let headerStack = UIStackView()
    private let detailLabel = UILabel()
    private let statsStack = UIStackView()
    private let statsRowOne = UIStackView()
    private let statsRowTwo = UIStackView()

    private let hourlyStack = UIStackView()
    private let hourlyTrendView = HourlyTrendView()
    private let hourlyContainer = UIStackView()
    private let hourlyScroll = UIScrollView()

    private let dailyStack = UIStackView()
    private let precipStack = UIStackView()
    private let sunStack = UIStackView()
    private var currentLocation: WeatherLocation?
    private var currentSnapshot: WeatherSnapshot?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        hazeLayer.frame = contentView.bounds
        radialLayer.frame = contentView.bounds
        vignetteLayer.frame = contentView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentLocation = nil
        currentSnapshot = nil
        onDailyForecastSelected = nil
    }

    private func configure() {
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        contentView.layer.insertSublayer(hazeLayer, at: 1)
        contentView.layer.insertSublayer(radialLayer, at: 2)
        contentView.layer.insertSublayer(vignetteLayer, at: 3)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        contentView.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 60),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -100),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        cityLabel.font = .systemFont(ofSize: 22, weight: .light)
        cityLabel.textColor = UIColor(white: 1, alpha: 0.9)
        cityLabel.textAlignment = .center

        tempLabel.font = .systemFont(ofSize: 86, weight: .ultraLight)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        tempLabel.adjustsFontSizeToFitWidth = true
        tempLabel.minimumScaleFactor = 0.7

        summaryLabel.font = .systemFont(ofSize: 18, weight: .medium)
        summaryLabel.textColor = UIColor(white: 1, alpha: 0.9)
        summaryLabel.textAlignment = .center

        highLowLabel.font = .systemFont(ofSize: 16, weight: .medium)
        highLowLabel.textColor = UIColor(white: 1, alpha: 0.8)
        highLowLabel.textAlignment = .center

        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.alignment = .center
        headerStack.addArrangedSubview(cityLabel)
        headerStack.addArrangedSubview(tempLabel)
        headerStack.addArrangedSubview(summaryLabel)
        headerStack.addArrangedSubview(highLowLabel)
        headerStack.setCustomSpacing(12, after: cityLabel)
        headerStack.setCustomSpacing(6, after: tempLabel)
        contentStack.addArrangedSubview(headerStack)

        detailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = UIColor(white: 1, alpha: 0.75)
        detailLabel.numberOfLines = 0

        let detailCard = makeCardView()
        detailCard.contentView.addSubview(detailLabel)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailLabel.leadingAnchor.constraint(equalTo: detailCard.contentView.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: detailCard.contentView.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: detailCard.contentView.topAnchor, constant: 12),
            detailLabel.bottomAnchor.constraint(equalTo: detailCard.contentView.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(detailCard)

        statsStack.axis = .vertical
        statsStack.spacing = 10

        statsRowOne.axis = .horizontal
        statsRowOne.distribution = .fillEqually
        statsRowOne.spacing = 8

        statsRowTwo.axis = .horizontal
        statsRowTwo.distribution = .fillEqually
        statsRowTwo.spacing = 8

        statsStack.addArrangedSubview(statsRowOne)
        statsStack.addArrangedSubview(statsRowTwo)

        let statsCard = makeCardView()
        statsCard.contentView.addSubview(statsStack)
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsStack.leadingAnchor.constraint(equalTo: statsCard.contentView.leadingAnchor, constant: 8),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.contentView.trailingAnchor, constant: -8),
            statsStack.topAnchor.constraint(equalTo: statsCard.contentView.topAnchor, constant: 12),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.contentView.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(statsCard)

        hourlyStack.axis = .horizontal
        hourlyStack.spacing = 20
        hourlyStack.alignment = .bottom

        hourlyContainer.axis = .vertical
        hourlyContainer.spacing = 8
        hourlyContainer.addArrangedSubview(hourlyTrendView)
        hourlyContainer.addArrangedSubview(hourlyStack)

        hourlyTrendView.translatesAutoresizingMaskIntoConstraints = false
        hourlyTrendView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        hourlyScroll.showsHorizontalScrollIndicator = false
        hourlyScroll.addSubview(hourlyContainer)
        hourlyContainer.translatesAutoresizingMaskIntoConstraints = false
        hourlyStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hourlyContainer.leadingAnchor.constraint(equalTo: hourlyScroll.contentLayoutGuide.leadingAnchor, constant: 16),
            hourlyContainer.trailingAnchor.constraint(equalTo: hourlyScroll.contentLayoutGuide.trailingAnchor, constant: -16),
            hourlyContainer.topAnchor.constraint(equalTo: hourlyScroll.contentLayoutGuide.topAnchor, constant: 10),
            hourlyContainer.bottomAnchor.constraint(equalTo: hourlyScroll.contentLayoutGuide.bottomAnchor, constant: -10),
            hourlyTrendView.widthAnchor.constraint(equalTo: hourlyStack.widthAnchor)
        ])

        let hourlyCard = makeCardView()
        hourlyCard.contentView.addSubview(hourlyScroll)
        hourlyScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hourlyScroll.leadingAnchor.constraint(equalTo: hourlyCard.contentView.leadingAnchor),
            hourlyScroll.trailingAnchor.constraint(equalTo: hourlyCard.contentView.trailingAnchor),
            hourlyScroll.topAnchor.constraint(equalTo: hourlyCard.contentView.topAnchor),
            hourlyScroll.bottomAnchor.constraint(equalTo: hourlyCard.contentView.bottomAnchor),
            hourlyScroll.heightAnchor.constraint(equalToConstant: 140)
        ])
        contentStack.addArrangedSubview(hourlyCard)

        let precipHeader = UILabel()
        precipHeader.font = .systemFont(ofSize: 14, weight: .semibold)
        precipHeader.textColor = UIColor(white: 1, alpha: 0.9)
        precipHeader.text = "Precipitation"

        precipStack.axis = .horizontal
        precipStack.spacing = 10
        precipStack.distribution = .fillEqually

        let precipContainer = UIStackView(arrangedSubviews: [precipHeader, precipStack])
        precipContainer.axis = .vertical
        precipContainer.spacing = 12

        let precipCard = makeCardView()
        precipCard.contentView.addSubview(precipContainer)
        precipContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            precipContainer.leadingAnchor.constraint(equalTo: precipCard.contentView.leadingAnchor, constant: 16),
            precipContainer.trailingAnchor.constraint(equalTo: precipCard.contentView.trailingAnchor, constant: -16),
            precipContainer.topAnchor.constraint(equalTo: precipCard.contentView.topAnchor, constant: 12),
            precipContainer.bottomAnchor.constraint(equalTo: precipCard.contentView.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(precipCard)

        dailyStack.axis = .vertical
        dailyStack.spacing = 10

        let dailyCard = makeCardView()
        dailyCard.contentView.addSubview(dailyStack)
        dailyStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dailyStack.leadingAnchor.constraint(equalTo: dailyCard.contentView.leadingAnchor, constant: 16),
            dailyStack.trailingAnchor.constraint(equalTo: dailyCard.contentView.trailingAnchor, constant: -16),
            dailyStack.topAnchor.constraint(equalTo: dailyCard.contentView.topAnchor, constant: 12),
            dailyStack.bottomAnchor.constraint(equalTo: dailyCard.contentView.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(dailyCard)

        sunStack.axis = .horizontal
        sunStack.distribution = .fillEqually
        sunStack.spacing = 12

        let sunCard = makeCardView()
        sunCard.contentView.addSubview(sunStack)
        sunStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sunStack.leadingAnchor.constraint(equalTo: sunCard.contentView.leadingAnchor, constant: 16),
            sunStack.trailingAnchor.constraint(equalTo: sunCard.contentView.trailingAnchor, constant: -16),
            sunStack.topAnchor.constraint(equalTo: sunCard.contentView.topAnchor, constant: 12),
            sunStack.bottomAnchor.constraint(equalTo: sunCard.contentView.bottomAnchor, constant: -12)
        ])
        contentStack.addArrangedSubview(sunCard)
    }

    func configure(location: WeatherLocation, snapshot: WeatherSnapshot) {
        currentLocation = location
        currentSnapshot = snapshot
        cityLabel.text = location.displayName
        tempLabel.attributedText = temperatureText(snapshot.current.temperature)
        summaryLabel.text = snapshot.current.summary
        highLowLabel.text = "\(formatTemp(snapshot.current.high)) / \(formatTemp(snapshot.current.low))"
        detailLabel.text = snapshot.current.detail

        contentView.accessibilityIdentifier = "weather_city_page_\(location.id)"
        cityLabel.accessibilityIdentifier = "weather_city_name"
        tempLabel.accessibilityIdentifier = "weather_temp"
        summaryLabel.accessibilityIdentifier = "weather_summary"
        highLowLabel.accessibilityIdentifier = "weather_high_low"
        detailLabel.accessibilityIdentifier = "weather_detail"

        gradientLayer.colors = snapshot.mode.gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        hazeLayer.colors = [
            snapshot.mode.tintColor.withAlphaComponent(0.16).cgColor,
            UIColor.clear.cgColor
        ]
        hazeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        hazeLayer.endPoint = CGPoint(x: 0.5, y: 1)

        radialLayer.type = kCAGradientLayerRadial
        radialLayer.colors = [
            snapshot.mode.tintColor.withAlphaComponent(0.35).cgColor,
            UIColor.clear.cgColor
        ]
        radialLayer.startPoint = CGPoint(x: 0.5, y: 0.25)
        radialLayer.endPoint = CGPoint(x: 1.0, y: 0.9)
        radialLayer.locations = [0, 1]

        vignetteLayer.type = kCAGradientLayerRadial
        vignetteLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.45).cgColor
        ]
        vignetteLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        vignetteLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        vignetteLayer.locations = [0.55, 1]

        statsRowOne.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsRowTwo.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsRowOne.addArrangedSubview(makeStat(title: "Feels Like", value: formatTemp(snapshot.current.feelsLike)))
        let windDirection = snapshot.current.windDirectionDegrees
        statsRowOne.addArrangedSubview(makeStat(
            title: "Wind",
            value: formatValue(snapshot.current.windMph, suffix: " mph"),
            iconName: windDirection == nil ? nil : "arrow.up",
            iconRotation: CGFloat(windDirection ?? 0)
        ))
        statsRowOne.addArrangedSubview(makeStat(title: "Humidity", value: formatValue(snapshot.current.humidity, suffix: "%")))
        statsRowTwo.addArrangedSubview(makeStat(title: "Precip", value: formatValue(snapshot.current.precipChance, suffix: "%")))
        statsRowTwo.addArrangedSubview(makeStat(title: "Visibility", value: formatValue(snapshot.current.visibilityMiles, suffix: " mi")))
        statsRowTwo.addArrangedSubview(makeStat(title: "Pressure", value: formatValue(snapshot.current.pressureMb, suffix: " mb")))

        hourlyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if snapshot.hourly.isEmpty {
            hourlyStack.addArrangedSubview(makeEmptyLabel("Hourly data unavailable"))
            hourlyTrendView.configure(temps: [])
        } else {
            snapshot.hourly.forEach { hour in
                hourlyStack.addArrangedSubview(makeHourlyItem(hour: hour))
            }
            hourlyTrendView.configure(temps: snapshot.hourly.compactMap(\.temperature))
        }

        precipStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if snapshot.hourly.isEmpty {
            precipStack.addArrangedSubview(makeEmptyLabel("No precipitation data"))
        } else {
            let step = 3
            var index = 0
            let precipHours = snapshot.hourly.filter { $0.sunEvent == nil }
            while index < precipHours.count {
                let hour = precipHours[index]
                let item = PrecipItemView()
                item.configure(hour: hour.hour, chance: hour.precipChance ?? 0)
                precipStack.addArrangedSubview(item)
                index += step
            }
        }

        dailyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let dailyHeader = UILabel()
        dailyHeader.font = .systemFont(ofSize: 14, weight: .semibold)
        dailyHeader.textColor = UIColor(white: 1, alpha: 0.9)
        dailyHeader.text = "10-Day Forecast"
        dailyStack.addArrangedSubview(dailyHeader)

        if snapshot.daily.isEmpty {
            dailyStack.addArrangedSubview(makeEmptyLabel("Daily forecast unavailable"))
        } else {
            let minLow = snapshot.daily.map { $0.low }.min() ?? snapshot.current.low
            let maxHigh = snapshot.daily.map { $0.high }.max() ?? snapshot.current.high

            snapshot.daily.forEach { day in
                dailyStack.addArrangedSubview(makeDailyItem(day: day, min: minLow, max: maxHigh))
            }
        }

        sunStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        sunStack.addArrangedSubview(makeSunItem(title: "Sunrise", time: snapshot.sunrise, symbolName: "sunrise.fill"))
        sunStack.addArrangedSubview(makeSunItem(title: "Sunset", time: snapshot.sunset, symbolName: "sunset.fill"))
    }

    private func makeCardView() -> FrostedCardView {
        FrostedCardView()
    }

    private func makeStat(title: String, value: String, iconName: String? = nil, iconRotation: CGFloat = 0) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = UIColor(white: 1, alpha: 0.65)
        titleLabel.textAlignment = .center
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        valueLabel.text = value

        let valueRow = UIStackView()
        valueRow.axis = .horizontal
        valueRow.alignment = .center
        valueRow.spacing = 4

        if let iconName {
            let icon = UIImageView(image: UIImage(systemName: iconName))
            icon.tintColor = UIColor(white: 1, alpha: 0.9)
            icon.contentMode = .scaleAspectFit
            icon.transform = CGAffineTransform(rotationAngle: iconRotation * .pi / 180)
            icon.widthAnchor.constraint(equalToConstant: 12).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 12).isActive = true
            valueRow.addArrangedSubview(icon)
        }

        valueRow.addArrangedSubview(valueLabel)

        let stack = UIStackView(arrangedSubviews: [valueRow, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        return stack
    }

    private func makeHourlyItem(hour: HourlyForecast) -> UIView {
        let hourLabel = UILabel()
        hourLabel.font = .systemFont(ofSize: 12, weight: .medium)
        hourLabel.textColor = UIColor(white: 1, alpha: 0.8)
        hourLabel.textAlignment = .center
        hourLabel.text = hour.sunEvent == nil ? hour.hour : ""

        let iconName: String
        switch hour.sunEvent {
        case .sunrise:
            iconName = "sunrise.fill"
        case .sunset:
            iconName = "sunset.fill"
        case nil:
            iconName = hour.mode?.symbolName(isDaylight: hour.isDaylight) ?? "cloud.fill"
        }
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let tempLabel = UILabel()
        tempLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        tempLabel.textColor = .white
        tempLabel.textAlignment = .center
        switch hour.sunEvent {
        case .sunrise:
            tempLabel.text = "Sunrise"
        case .sunset:
            tempLabel.text = "Sunset"
        case nil:
            tempLabel.text = formatTemp(hour.temperature)
        }
        tempLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [hourLabel, icon, tempLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        stack.widthAnchor.constraint(equalToConstant: 54).isActive = true
        return stack
    }

    private func makeDailyItem(day: DailyForecast, min: Int, max: Int) -> UIView {
        let dayLabel = UILabel()
        dayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dayLabel.textColor = .white
        dayLabel.text = day.day
        dayLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dayLabel.widthAnchor.constraint(equalToConstant: 64).isActive = true

        let icon = UIImageView(image: UIImage(systemName: day.mode.symbolName(isDaylight: true)))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let lowLabel = UILabel()
        lowLabel.font = .systemFont(ofSize: 14, weight: .regular)
        lowLabel.textColor = UIColor(white: 1, alpha: 0.65)
        lowLabel.textAlignment = .right
        lowLabel.text = formatTemp(day.low)
        lowLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let highLabel = UILabel()
        highLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        highLabel.textColor = UIColor(white: 1, alpha: 0.95)
        highLabel.textAlignment = .right
        highLabel.text = formatTemp(day.high)
        highLabel.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let rangeView = TemperatureRangeView()
        rangeView.configure(low: day.low, high: day.high, min: min, max: max, isToday: day.day == "Today")
        rangeView.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let row = UIButton(type: .system)
        row.tintColor = .white
        row.contentHorizontalAlignment = .fill
        row.accessibilityIdentifier = "weather_daily_row_\(day.day.lowercased().replacingOccurrences(of: " ", with: "_"))"
        row.addAction(UIAction { [weak self] _ in
            guard let self, let location = self.currentLocation, let snapshot = self.currentSnapshot else { return }
            self.onDailyForecastSelected?(location, snapshot, day)
        }, for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [dayLabel, icon, lowLabel, rangeView, highLabel])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 8
        content.isUserInteractionEnabled = false
        content.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(content)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = UIColor(white: 1, alpha: 0.45)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.isUserInteractionEnabled = false
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            content.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
            content.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -6),
            chevron.leadingAnchor.constraint(equalTo: content.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            chevron.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            rangeView.widthAnchor.constraint(equalToConstant: 92)
        ])

        return row
    }

    private func makeSunItem(title: String, time: Date?, symbolName: String) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbolName))
        icon.tintColor = UIColor(white: 1, alpha: 0.85)
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let timeLabel = UILabel()
        timeLabel.font = .systemFont(ofSize: 18, weight: .medium)
        timeLabel.textColor = .white
        timeLabel.text = timeString(time)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = UIColor(white: 1, alpha: 0.7)
        titleLabel.text = title

        let stack = UIStackView(arrangedSubviews: [icon, timeLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }

    private func makeEmptyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(white: 1, alpha: 0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func formatTemp(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)°"
    }

    private func formatValue(_ value: Int?, suffix: String) -> String {
        guard let value else { return "—" }
        return "\(value)\(suffix)"
    }


    private func temperatureText(_ value: Int?) -> NSAttributedString {
        let string = formatTemp(value)
        return NSAttributedString(
            string: string,
            attributes: [
                .kern: -1.2,
                .font: tempLabel.font as Any,
                .foregroundColor: UIColor.white
            ]
        )
    }

    private func timeString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        guard let date else { return "—" }
        return formatter.string(from: date)
    }
}

final class DailyForecastDetailViewController: UIViewController {
    private let location: WeatherLocation
    private let snapshot: WeatherSnapshot
    private let day: DailyForecast
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    init(location: WeatherLocation, snapshot: WeatherSnapshot, day: DailyForecast) {
        self.location = location
        self.snapshot = snapshot
        self.day = day
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = day.day == "Today" ? location.displayName : "\(location.displayName) \(day.day)"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        configureLayout()
        populate()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func populate() {
        let header = UIStackView()
        header.axis = .vertical
        header.spacing = 4

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.text = day.day

        let tempLabel = UILabel()
        tempLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        tempLabel.textColor = .secondaryLabel
        tempLabel.text = "High \(day.high)°  Low \(day.low)°"

        let summaryLabel = UILabel()
        summaryLabel.font = .systemFont(ofSize: 16, weight: .medium)
        summaryLabel.text = day.summary

        let detailLabel = UILabel()
        detailLabel.font = .systemFont(ofSize: 15, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.text = day.detail

        [titleLabel, tempLabel, summaryLabel, detailLabel].forEach(header.addArrangedSubview)
        stackView.addArrangedSubview(header)

        let solar = makeInfoSection(title: "Sun") {
            [
                self.makeInfoRow(title: "Sunrise", value: self.timeString(self.day.sunrise)),
                self.makeInfoRow(title: "Sunset", value: self.timeString(self.day.sunset))
            ]
        }
        stackView.addArrangedSubview(solar)

        let hourlyItems = hourlyForecastsForDay()
        let hourlySection = makeInfoSection(title: "Hourly") {
            if hourlyItems.isEmpty {
                return [self.makeInfoRow(title: "Forecast", value: "No hourly breakdown available")]
            }
            return hourlyItems.map { forecast in
                let descriptor: String
                switch forecast.sunEvent {
                case .sunrise:
                    descriptor = "Sunrise"
                case .sunset:
                    descriptor = "Sunset"
                case nil:
                    let temp = forecast.temperature.map { "\($0)°" } ?? "—"
                    let summary = forecast.mode?.summary ?? "Conditions"
                    descriptor = "\(temp)  \(summary)"
                }
                return self.makeInfoRow(title: forecast.hour.uppercased(), value: descriptor)
            }
        }
        stackView.addArrangedSubview(hourlySection)
    }

    private func hourlyForecastsForDay() -> [HourlyForecast] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day.date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return snapshot.hourly.filter { forecast in
            forecast.date >= start && forecast.date < end
        }
    }

    private func makeInfoSection(title: String, rows: () -> [UIView]) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 16

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title
        stack.addArrangedSubview(titleLabel)

        rows().forEach(stack.addArrangedSubview)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.text = value

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .top
        row.distribution = .fillEqually
        return row
    }

    private func timeString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        guard let date else { return "—" }
        return formatter.string(from: date)
    }
}

final class FrostedCardView: UIView {
    let contentView: UIView
    private let blurView: UIVisualEffectView

    override init(frame: CGRect) {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView = UIVisualEffectView(effect: blur)
        contentView = blurView.contentView
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView = UIVisualEffectView(effect: blur)
        contentView = blurView.contentView
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        layer.cornerRadius = 22
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 22
        blurView.clipsToBounds = true
        blurView.layer.borderWidth = 1 / UIScreen.main.scale
        blurView.layer.borderColor = UIColor(white: 1, alpha: 0.05).cgColor
        addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 22).cgPath
    }
}

final class HourlyTrendView: UIView {
    private let lineLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()
    private var temps: [Int] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        lineLayer.strokeColor = UIColor(white: 1, alpha: 0.7).cgColor
        lineLayer.lineWidth = 2
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineJoin = kCALineJoinRound
        lineLayer.lineCap = kCALineCapRound
        layer.addSublayer(lineLayer)

        dotLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(dotLayer)
    }

    func configure(temps: [Int]) {
        self.temps = temps
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard temps.count > 1 else {
            lineLayer.path = nil
            dotLayer.path = nil
            return
        }

        let minTemp = temps.min() ?? 0
        let maxTemp = temps.max() ?? 1
        let range = max(1, maxTemp - minTemp)
        let width = bounds.width
        let height = bounds.height
        let stepX = width / CGFloat(temps.count - 1)
        let verticalPadding: CGFloat = 4
        let usableHeight = max(1, height - verticalPadding * 2)

        var points: [CGPoint] = []
        for (index, temp) in temps.enumerated() {
            let normalized = CGFloat(temp - minTemp) / CGFloat(range)
            let x = CGFloat(index) * stepX
            let y = height - verticalPadding - normalized * usableHeight
            points.append(CGPoint(x: x, y: y))
        }

        let path = UIBezierPath()
        path.move(to: points[0])
        for index in 1..<points.count {
            let prev = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (prev.x + current.x) / 2, y: (prev.y + current.y) / 2)
            path.addQuadCurve(to: mid, controlPoint: CGPoint(x: mid.x, y: prev.y))
            path.addQuadCurve(to: current, controlPoint: CGPoint(x: mid.x, y: current.y))
        }
        lineLayer.path = path.cgPath

        let dotSize: CGFloat = 6
        let dotRect = CGRect(
            x: points[0].x - dotSize / 2,
            y: points[0].y - dotSize / 2,
            width: dotSize,
            height: dotSize
        )
        dotLayer.path = UIBezierPath(ovalIn: dotRect).cgPath
    }
}

final class TemperatureRangeView: UIView {
    private let trackLayer = CALayer()
    private let rangeLayer = CALayer()
    private let dotLayer = CALayer()
    private var low: Int = 0
    private var high: Int = 0
    private var minValue: Int = 0
    private var maxValue: Int = 0
    private var isToday = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        trackLayer.backgroundColor = UIColor(white: 1, alpha: 0.2).cgColor
        trackLayer.cornerRadius = 3
        layer.addSublayer(trackLayer)

        rangeLayer.backgroundColor = UIColor(white: 1, alpha: 0.75).cgColor
        rangeLayer.cornerRadius = 3
        layer.addSublayer(rangeLayer)

        dotLayer.backgroundColor = UIColor.white.cgColor
        dotLayer.cornerRadius = 3
        layer.addSublayer(dotLayer)
    }

    func configure(low: Int, high: Int, min: Int, max: Int, isToday: Bool) {
        self.low = low
        self.high = high
        minValue = min
        maxValue = max
        self.isToday = isToday
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let height: CGFloat = 6
        let centerY = (bounds.height - height) / 2
        trackLayer.frame = CGRect(x: 0, y: centerY, width: bounds.width, height: height)

        let range = max(1, maxValue - minValue)
        let start = CGFloat(low - minValue) / CGFloat(range)
        let end = CGFloat(high - minValue) / CGFloat(range)
        let rangeX = bounds.width * start
        let rangeWidth = max(4, bounds.width * (end - start))
        rangeLayer.frame = CGRect(x: rangeX, y: centerY, width: rangeWidth, height: height)

        if isToday {
            let dotSize: CGFloat = 6
            let dotX = rangeX + rangeWidth * 0.5 - dotSize / 2
            let dotY = centerY - dotSize / 2
            dotLayer.frame = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
            dotLayer.isHidden = false
        } else {
            dotLayer.isHidden = true
        }
    }
}

final class PrecipItemView: UIView {
    private let valueLabel = UILabel()
    private let barView = UIView()
    private let hourLabel = UILabel()
    private var barHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        valueLabel.font = .systemFont(ofSize: 11, weight: .medium)
        valueLabel.textColor = UIColor(white: 1, alpha: 0.8)
        valueLabel.textAlignment = .center

        barView.backgroundColor = UIColor(red: 0.48, green: 0.76, blue: 1.0, alpha: 0.85)
        barView.layer.cornerRadius = 3
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.widthAnchor.constraint(equalToConstant: 6).isActive = true
        barHeightConstraint = barView.heightAnchor.constraint(equalToConstant: 8)
        barHeightConstraint?.isActive = true

        hourLabel.font = .systemFont(ofSize: 11, weight: .medium)
        hourLabel.textColor = UIColor(white: 1, alpha: 0.7)
        hourLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, barView, hourLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(hour: String, chance: Int) {
        valueLabel.text = "\(chance)%"
        hourLabel.text = hour
        let height = max(6, CGFloat(chance) / 100.0 * 32.0)
        barHeightConstraint?.constant = height
        layoutIfNeeded()
    }
}
