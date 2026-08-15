import SwiftUI

/// Full-screen hot/cold hunt for one device.
struct TrackerView: View {
    let deviceID: UUID

    @EnvironmentObject var scanner: BLEScanner
    @EnvironmentObject var feedback: Feedback
    @EnvironmentObject var log: SearchLog

    @State private var sessionPeak: Int = -127
    @State private var markResult: String?
    @State private var showRaw = false

    private var device: Discovery? { scanner.device(id: deviceID) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let device {
                    meter(device)
                    readouts(device)
                    controls(device)
                    evidence(device)
                } else {
                    ContentUnavailableView("Signal lost",
                                           systemImage: "wifi.exclamationmark",
                                           description: Text("No packets from this device any more. Walk back the way you came."))
                        .padding(.top, 60)
                }
            }
            .padding()
        }
        .navigationTitle(device?.displayName ?? "Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: device?.smoothed ?? -100) { _, new in
            feedback.update(rssi: new)
            if let rssi = device?.rssi { sessionPeak = max(sessionPeak, rssi) }
        }
        .onDisappear { feedback.soundOn = false }
    }

    // MARK: - Meter

    private func meter(_ d: Discovery) -> some View {
        let fraction = min(max((d.smoothed + 100) / 60, 0), 1)
        return ZStack {
            // Three-quarter dial, rotated so the gap sits at the bottom.
            Group {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.secondary.opacity(0.15), style: .init(lineWidth: 22, lineCap: .round))
                Circle()
                    .trim(from: 0, to: 0.75 * fraction)
                    .stroke(gradient, style: .init(lineWidth: 22, lineCap: .round))
                    .animation(.easeOut(duration: 0.25), value: fraction)
            }
            .rotationEffect(.degrees(135))

            VStack(spacing: 2) {
                Text("\(Int(d.smoothed))")
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("dBm")
                    .font(.caption).foregroundStyle(.secondary)
                Text(verdict(d.smoothed))
                    .font(.headline)
                    .foregroundStyle(colour(fraction))
                    .padding(.top, 6)
            }
        }
        .frame(height: 240)
    }

    private var gradient: AngularGradient {
        AngularGradient(colors: [.blue, .cyan, .yellow, .orange, .red], center: .center)
    }

    private func colour(_ f: Double) -> Color {
        switch f {
        case 0.8...: return .red
        case 0.6..<0.8: return .orange
        case 0.35..<0.6: return .yellow
        default: return .blue
        }
    }

    private func verdict(_ rssi: Double) -> String {
        switch rssi {
        case -45...: return "ON TOP OF IT"
        case -60..<(-45): return "VERY WARM"
        case -75..<(-60): return "WARM"
        case -88..<(-75): return "COLD"
        default: return "BARELY THERE"
        }
    }

    // MARK: - Numbers

    private func readouts(_ d: Discovery) -> some View {
        HStack(spacing: 0) {
            stat("Live", "\(d.rssi)")
            Divider().frame(height: 34)
            stat("Best here", sessionPeak == -127 ? "—" : "\(sessionPeak)")
            Divider().frame(height: 34)
            stat("Rough", String(format: "%.0f m", d.approxMetres))
            Divider().frame(height: 34)
            stat("Packets", "\(d.packets)")
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(.title3, design: .rounded).weight(.semibold)).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Controls

    private func controls(_ d: Discovery) -> some View {
        VStack(spacing: 12) {
            Toggle(isOn: $feedback.soundOn) {
                Label("Geiger sound", systemImage: "speaker.wave.3.fill")
            }
            Toggle(isOn: $feedback.hapticsOn) {
                Label("Vibration", systemImage: "iphone.radiowaves.left.and.right")
            }

            Button {
                sessionPeak = -127
            } label: {
                Label("Reset best-here", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                let ok = log.mark(rssi: d.rssi, note: d.displayName)
                markResult = ok ? "Pin dropped at \(d.rssi) dBm."
                                : "No GPS fix yet — wait a few seconds outdoors."
            } label: {
                Label("Drop a pin here", systemImage: "mappin.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if d.isConnectable {
                Button {
                    scanner.buzz(d.id)
                } label: {
                    Label("Try to buzz it", systemImage: "bell.badge.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            if let markResult {
                Text(markResult).font(.caption).foregroundStyle(.secondary)
            }
            if let status = scanner.buzzStatus {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Why we think this is it

    private func evidence(_ d: Discovery) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Match score \(d.score)/100").font(.subheadline.bold())
                Spacer()
                Button(showRaw ? "Hide raw" : "Raw data") { showRaw.toggle() }
                    .font(.caption)
            }

            if d.reasons.isEmpty {
                Text("Nothing about this device points at a Xiaomi band.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(d.reasons, id: \.self) { reason in
                    Label(reason, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if showRaw {
                Group {
                    labelled("Identifier", d.id.uuidString)
                    labelled("Services", d.serviceUUIDs.map(\.uuidString).joined(separator: ", "))
                    if let c = d.companyID { labelled("Company", String(format: "0x%04X", c)) }
                    if let m = d.manufacturerPayload { labelled("Mfr data", m.hexString) }
                    if let s = d.serviceDataPayload { labelled("Service data", s.hexString) }
                    labelled("Connectable", d.isConnectable ? "yes" : "no")
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
    }

    private func labelled(_ key: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(key).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.caption2, design: .monospaced)).textSelection(.enabled)
        }
    }
}

// MARK: - Pins

struct HotSpotsView: View {
    @EnvironmentObject var log: SearchLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if log.spots.isEmpty {
                    Text("No pins yet. While tracking, drop a pin every time the signal peaks — the cluster tells you where to dig.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(log.spots) { spot in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(spot.rssi) dBm · \(spot.note)").font(.callout.weight(.medium))
                            Text(String(format: "%.6f, %.6f  ±%.0f m", spot.latitude, spot.longitude, spot.accuracy))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Text(spot.date.formatted(date: .omitted, time: .standard))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .onDelete { indexSet in
                        // Resolve to values first — deleting shifts the indices.
                        let doomed = indexSet.map { log.spots[$0] }
                        for spot in doomed { log.delete(spot) }
                    }
                }
            }
            .navigationTitle("Pins")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = log.exportCSV(), !log.spots.isEmpty {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
        }
    }
}
