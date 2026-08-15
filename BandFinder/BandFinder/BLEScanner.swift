import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BLEScanner: NSObject, ObservableObject {

    @Published private(set) var devices: [Discovery] = []
    @Published private(set) var state: CBManagerState = .unknown
    @Published private(set) var isScanning = false

    /// The 4 hex characters from the paired device name — the MAC suffix.
    @Published var token: String = "301A" { didSet { rescoreAll() } }

    /// Restrict the radio to Xiaomi service UUIDs. Fewer devices, but iOS
    /// surfaces matching packets more aggressively, so it is worth a pass.
    @Published var xiaomiServicesOnly = false { didSet { restartScan() } }

    /// Hide anything that scores 0 — cuts hundreds of phones on a beach down to a handful.
    @Published var hideUnlikely = true

    /// Drop devices we have not heard from in a while.
    @Published var pruneStale = true

    @Published private(set) var buzzStatus: String?

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var pruneTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
        ])
        pruneTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.prune() }
        }
    }

    // MARK: - Scanning

    func startScan() {
        guard central.state == .poweredOn else { return }
        let services = xiaomiServicesOnly ? Vendor.xiaomiServices : nil
        central.scanForPeripherals(withServices: services, options: [
            // Essential: without this iOS collapses repeats and the RSSI stops updating,
            // which makes hot/cold hunting impossible.
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        isScanning = true
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
    }

    func restartScan() {
        guard isScanning else { return }
        stopScan()
        startScan()
    }

    func clear() {
        devices.removeAll()
        peripherals.removeAll()
    }

    /// Sorted for the hunt: best candidates first, then loudest.
    var sorted: [Discovery] {
        devices
            .filter { !hideUnlikely || $0.score > 0 }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.smoothed > $1.smoothed
            }
    }

    func device(id: UUID) -> Discovery? { devices.first { $0.id == id } }

    private func rescoreAll() {
        for i in devices.indices {
            Heuristics.score(&devices[i], token: token)
        }
    }

    private func prune() {
        guard pruneStale else { return }
        let cutoff = Date().addingTimeInterval(-45)
        devices.removeAll { $0.lastSeen < cutoff && $0.score == 0 }
    }

    // MARK: - Buzz attempt

    /// Best-effort: connect and write to the Immediate Alert service so the band
    /// vibrates. Many Xiaomi bands refuse this until authenticated, so treat a
    /// failure as normal rather than as proof it is the wrong device.
    func buzz(_ id: UUID) {
        guard let peripheral = peripherals[id] else {
            buzzStatus = "Lost the handle on that device — rescan."
            return
        }
        buzzStatus = "Connecting…"
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func disconnect(_ id: UUID) {
        guard let peripheral = peripherals[id] else { return }
        central.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEScanner: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.state = central.state
            if central.state == .poweredOn { self.startScan() } else { self.isScanning = false }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        let rssi = RSSI.intValue
        // iOS reports 127 when the reading is unavailable.
        guard rssi < 0, rssi > -127 else { return }

        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        let overflow = (advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]) ?? []
        let mfr = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let connectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
        let tx = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue

        var serviceData: Data?
        if let dict = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            serviceData = dict.values.reduce(into: Data()) { $0.append($1) }
        }

        var company: UInt16?
        if let mfr, mfr.count >= 2 {
            company = UInt16(mfr[mfr.startIndex]) | (UInt16(mfr[mfr.startIndex + 1]) << 8)
        }

        Task { @MainActor in
            self.peripherals[peripheral.identifier] = peripheral
            self.ingest(id: peripheral.identifier,
                        name: name,
                        rssi: rssi,
                        services: services + overflow,
                        company: company,
                        mfr: mfr,
                        serviceData: serviceData,
                        connectable: connectable,
                        tx: tx)
        }
    }

    private func ingest(id: UUID, name: String?, rssi: Int, services: [CBUUID],
                        company: UInt16?, mfr: Data?, serviceData: Data?,
                        connectable: Bool, tx: Int?) {

        if let index = devices.firstIndex(where: { $0.id == id }) {
            var d = devices[index]
            d.rssi = rssi
            // Exponential moving average. Raw BLE RSSI swings ±10 dB packet to
            // packet; without smoothing the meter is unreadable while walking.
            d.smoothed = d.smoothed * 0.75 + Double(rssi) * 0.25
            d.peak = max(d.peak, rssi)
            d.lastSeen = Date()
            d.packets += 1
            if let name, !name.isEmpty { d.name = name }
            if !services.isEmpty { d.serviceUUIDs = Array(Set(d.serviceUUIDs + services)) }
            if let company { d.companyID = company }
            if let mfr { d.manufacturerPayload = mfr }
            if let serviceData { d.serviceDataPayload = serviceData }
            if let tx { d.txPower = tx }
            d.isConnectable = connectable || d.isConnectable
            Heuristics.score(&d, token: token)
            devices[index] = d
        } else {
            var d = Discovery(id: id,
                              name: name,
                              rssi: rssi,
                              smoothed: Double(rssi),
                              peak: rssi,
                              firstSeen: Date(),
                              lastSeen: Date(),
                              packets: 1,
                              serviceUUIDs: services,
                              companyID: company,
                              manufacturerPayload: mfr,
                              serviceDataPayload: serviceData,
                              isConnectable: connectable,
                              txPower: tx)
            Heuristics.score(&d, token: token)
            devices.append(d)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in self.buzzStatus = "Connected — looking for the alert service…" }
        peripheral.discoverServices([Vendor.immediateAlert])
    }

    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            self.buzzStatus = "Could not connect: \(error?.localizedDescription ?? "unknown")"
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEScanner: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Vendor.immediateAlert }) else {
            Task { @MainActor in
                self.buzzStatus = "No alert service — this device cannot be buzzed unauthenticated."
                self.central.cancelPeripheralConnection(peripheral)
            }
            return
        }
        peripheral.discoverCharacteristics([Vendor.alertLevel], for: service)
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        guard let ch = service.characteristics?.first(where: { $0.uuid == Vendor.alertLevel }) else {
            Task { @MainActor in self.buzzStatus = "Alert characteristic missing." }
            return
        }
        // 0x02 = high alert.
        peripheral.writeValue(Data([0x02]), for: ch, type: .withoutResponse)
        Task { @MainActor in
            self.buzzStatus = "Alert sent. Listen and watch for a vibration."
        }
    }
}
