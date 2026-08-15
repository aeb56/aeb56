import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var scanner: BLEScanner
    @EnvironmentObject var log: SearchLog

    @State private var showSpots = false

    var body: some View {
        NavigationStack {
            Group {
                if scanner.state != .poweredOn {
                    bluetoothNotice
                } else {
                    list
                }
            }
            .navigationTitle("Band Finder")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSpots = true } label: {
                        Label("Pins", systemImage: "mappin.and.ellipse")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(scanner.isScanning ? "Pause" : "Scan") {
                        scanner.isScanning ? scanner.stopScan() : scanner.startScan()
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                TrackerView(deviceID: id)
            }
            .sheet(isPresented: $showSpots) { HotSpotsView() }
            .onAppear { log.requestAccess() }
        }
    }

    private var list: some View {
        List {
            Section {
                HStack {
                    Text("MAC suffix")
                    Spacer()
                    TextField("301A", text: $scanner.token)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .font(.body.monospaced())
                }
                Toggle("Xiaomi services only", isOn: $scanner.xiaomiServicesOnly)
                Toggle("Hide unlikely devices", isOn: $scanner.hideUnlikely)
            } header: {
                Text("Hunt settings")
            } footer: {
                Text("The 4 characters after the name on the pairing screen (301A) are the last two bytes of the band’s Bluetooth address. The app looks for them in the name *and* in the raw advertising bytes, so it can spot the band even when iOS shows no name.")
            }

            Section {
                if scanner.sorted.isEmpty {
                    Text(scanner.hideUnlikely
                         ? "Nothing matching yet. Turn off “Hide unlikely devices” to see everything in range."
                         : "Nothing in range yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scanner.sorted) { device in
                        NavigationLink(value: device.id) { DeviceRow(device: device) }
                    }
                }
            } header: {
                HStack {
                    Text("\(scanner.sorted.count) shown · \(scanner.devices.count) heard")
                    Spacer()
                    if scanner.isScanning {
                        ProgressView().controlSize(.mini)
                    }
                }
            }
        }
    }

    private var bluetoothNotice: some View {
        ContentUnavailableView(
            "Bluetooth unavailable",
            systemImage: "antenna.radiowaves.left.and.right.slash",
            description: Text(stateDescription)
        )
    }

    private var stateDescription: String {
        switch scanner.state {
        case .poweredOff: return "Turn Bluetooth on in Control Centre or Settings."
        case .unauthorized: return "Allow Bluetooth for this app in Settings › Privacy › Bluetooth."
        case .unsupported: return "This device has no Bluetooth LE radio."
        default: return "Starting the Bluetooth radio…"
        }
    }
}

struct DeviceRow: View {
    let device: Discovery

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(colour.opacity(0.18))
                VStack(spacing: 0) {
                    Text("\(device.rssi)").font(.system(size: 15, weight: .bold, design: .rounded))
                    Text("dBm").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.displayName)
                    .font(.callout.weight(device.score >= 45 ? .semibold : .regular))
                    .foregroundStyle(device.name == nil ? .secondary : .primary)
                    .lineLimit(1)

                if device.score > 0 {
                    Text(device.reasons.first ?? "")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                }

                Text("peak \(device.peak) · \(device.packets) pkts · ~\(String(format: "%.0f", device.approxMetres)) m")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if device.score > 0 {
                Text("\(device.score)")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(colour.opacity(0.2), in: Capsule())
                    .foregroundStyle(colour)
            }
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .opacity(device.isStale ? 0.45 : 1)
        .padding(.vertical, 2)
    }

    private var colour: Color {
        switch device.score {
        case 80...: return .green
        case 45..<80: return .orange
        case 1..<45: return .yellow
        default: return .gray
        }
    }
}
