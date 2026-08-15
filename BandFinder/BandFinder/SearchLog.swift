import Foundation
import CoreLocation
import Combine

struct HotSpot: Identifiable, Codable {
    let id: UUID
    let date: Date
    let rssi: Int
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let note: String
}

/// Records where on the beach a signal was strongest. Walking a grid and dropping
/// a pin at every peak is what actually narrows a search area down — the meter
/// alone will send you in circles.
@MainActor
final class SearchLog: NSObject, ObservableObject {

    @Published private(set) var spots: [HotSpot] = []
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorized = false

    private let manager = CLLocationManager()
    private let storeURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("hotspots.json")
    }()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        load()
    }

    func requestAccess() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    @discardableResult
    func mark(rssi: Int, note: String) -> Bool {
        guard let loc = currentLocation else { return false }
        let spot = HotSpot(id: UUID(),
                           date: Date(),
                           rssi: rssi,
                           latitude: loc.coordinate.latitude,
                           longitude: loc.coordinate.longitude,
                           accuracy: loc.horizontalAccuracy,
                           note: note)
        spots.insert(spot, at: 0)
        save()
        return true
    }

    func delete(_ spot: HotSpot) {
        spots.removeAll { $0.id == spot.id }
        save()
    }

    func clear() {
        spots.removeAll()
        save()
    }

    /// CSV you can drop into any mapping tool once you are off the beach.
    func exportCSV() -> URL? {
        var csv = "timestamp,rssi,latitude,longitude,accuracy_m,note\n"
        let formatter = ISO8601DateFormatter()
        for s in spots.reversed() {
            let note = s.note.replacingOccurrences(of: ",", with: ";")
            csv += "\(formatter.string(from: s.date)),\(s.rssi),\(s.latitude),\(s.longitude),\(s.accuracy),\(note)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("band-search.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(spots) else { return }
        try? data.write(to: storeURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([HotSpot].self, from: data) else { return }
        spots = decoded
    }
}

extension SearchLog: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in self.currentLocation = last }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
            if self.authorized { manager.startUpdatingLocation() }
        }
    }
}
