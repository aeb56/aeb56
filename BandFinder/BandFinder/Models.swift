import Foundation
import CoreBluetooth

// MARK: - Bluetooth SIG / vendor identifiers we care about

enum Vendor {
    /// 16-bit service UUIDs that Xiaomi / Huami wearables advertise.
    static let xiaomiServices: [CBUUID] = [
        CBUUID(string: "FEE0"), // Xiaomi Inc. — Mi Band primary service
        CBUUID(string: "FEE1"), // Xiaomi Inc. — Mi Band auth service
        CBUUID(string: "FEE2"), // Xiaomi Inc.
        CBUUID(string: "FE95"), // Xiaomi Inc. — MiBeacon
        CBUUID(string: "FDAB"), // Beijing Xiaomi Mobile Software
    ]

    /// Immediate Alert Service — used by the "buzz it" attempt.
    static let immediateAlert = CBUUID(string: "1802")
    static let alertLevel = CBUUID(string: "2A06")

    /// Bluetooth SIG company identifiers.
    static let huami: UInt16 = 0x0157      // Anhui Huami Information Technology
    static let xiaomiInc: UInt16 = 0x038F  // Xiaomi Inc.
    static let beijingXiaomi: UInt16 = 0x02FF

    static let nameHints = ["xiaomi", "mi band", "smart band", "miband", "huami", "amazfit", "redmi"]
}

// MARK: - A device we have heard from

struct Discovery: Identifiable, Equatable {
    /// CoreBluetooth's per-device identifier. iOS never gives us the MAC address,
    /// but this UUID is stable for a given device *on this iPhone*, so it is
    /// good enough to lock onto and to favourite.
    let id: UUID

    var name: String?
    var rssi: Int
    var smoothed: Double
    var peak: Int
    var firstSeen: Date
    var lastSeen: Date
    var packets: Int
    var serviceUUIDs: [CBUUID]
    var companyID: UInt16?
    var manufacturerPayload: Data?
    var serviceDataPayload: Data?
    var isConnectable: Bool
    var txPower: Int?

    /// 0...100 — how much this looks like the band we are hunting.
    var score: Int = 0
    var reasons: [String] = []

    static func == (a: Discovery, b: Discovery) -> Bool {
        a.id == b.id && a.rssi == b.rssi && a.packets == b.packets && a.score == b.score
    }

    var displayName: String { name ?? "(no name broadcast)" }

    /// Very rough log-distance path loss estimate. Treat it as "warmer / colder",
    /// never as metres — bodies, sand and wet clothing all skew it badly.
    var approxMetres: Double {
        let measuredPower = Double(txPower ?? -59)
        let n = 2.5
        return pow(10, (measuredPower - smoothed) / (10 * n))
    }

    var isStale: Bool { Date().timeIntervalSince(lastSeen) > 12 }
}

// MARK: - Scoring

enum Heuristics {
    /// Scores a discovery against the band we are hunting.
    /// `token` is the 4 hex characters from the paired name, e.g. "301A", which
    /// are the last two bytes of the band's Bluetooth MAC address.
    static func score(_ d: inout Discovery, token: String) {
        var score = 0
        var reasons: [String] = []

        let lowerName = (d.name ?? "").lowercased()

        if !lowerName.isEmpty {
            for hint in Vendor.nameHints where lowerName.contains(hint) {
                score += 60
                reasons.append("name contains “\(hint)”")
                break
            }
        }

        let cleanToken = token.trimmingCharacters(in: .whitespaces).uppercased()

        // Strongest possible signal: the name still carries the MAC suffix.
        if !cleanToken.isEmpty, lowerName.contains(cleanToken.lowercased()) {
            score += 100
            reasons.append("name ends in \(cleanToken)")
        }

        for service in d.serviceUUIDs where Vendor.xiaomiServices.contains(service) {
            score += 45
            reasons.append("advertises Xiaomi service 0x\(service.uuidString)")
        }

        if let company = d.companyID {
            switch company {
            case Vendor.huami:
                score += 50
                reasons.append("manufacturer: Anhui Huami (0x0157)")
            case Vendor.xiaomiInc, Vendor.beijingXiaomi:
                score += 45
                reasons.append("manufacturer: Xiaomi (0x\(String(format: "%04X", company)))")
            default:
                break
            }
        }

        // The payload hunt. Xiaomi/Huami bands routinely put their MAC address in
        // the manufacturer-specific data, so the bytes 30 1A show up even when
        // iOS reports no name at all. Check both byte orders.
        if let bytes = tokenBytes(cleanToken) {
            let haystacks = [d.manufacturerPayload, d.serviceDataPayload].compactMap { $0 }
            for haystack in haystacks {
                if contains(haystack, bytes) || contains(haystack, bytes.reversed()) {
                    score += 55
                    reasons.append("payload contains bytes \(cleanToken)")
                    break
                }
            }
        }

        d.score = min(score, 100)
        d.reasons = reasons
    }

    /// "301A" -> [0x30, 0x1A]
    static func tokenBytes(_ token: String) -> [UInt8]? {
        let chars = Array(token)
        guard chars.count >= 2, chars.count % 2 == 0 else { return nil }
        var out: [UInt8] = []
        var i = 0
        while i < chars.count {
            guard let byte = UInt8(String(chars[i...i + 1]), radix: 16) else { return nil }
            out.append(byte)
            i += 2
        }
        return out
    }

    static func contains<C: Collection>(_ haystack: Data, _ needle: C) -> Bool where C.Element == UInt8 {
        let n = Array(needle)
        guard !n.isEmpty, haystack.count >= n.count else { return false }
        let h = Array(haystack)
        for start in 0...(h.count - n.count) where Array(h[start..<start + n.count]) == n {
            return true
        }
        return false
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
