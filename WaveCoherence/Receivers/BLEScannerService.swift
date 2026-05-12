import Combine
import CoreBluetooth
import Foundation

final class BLEScannerService: NSObject, ObservableObject {
    struct Device: Identifiable, Hashable {
        let id: UUID
        let name: String
        let rssi: Int
        let lastSeen: Date
    }

    @Published private(set) var devices: [Device] = []
    @Published private(set) var rfDensity: Double = 0
    @Published private(set) var isRunning = false
    @Published private(set) var state: CBManagerState = .unknown

    private var central: CBCentralManager?
    private var pending: [UUID: Device] = [:]
    private let pendingLock = NSLock()

    func start() {
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        }
        if central?.state == .poweredOn {
            central?.scanForPeripherals(withServices: nil,
                                        options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            isRunning = true
        } else {
            // The state callback will start scanning when poweredOn
            isRunning = true
        }
    }

    func stop() {
        central?.stopScan()
        isRunning = false
    }
}

extension BLEScannerService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        if state == .poweredOn && isRunning {
            central.scanForPeripherals(withServices: nil,
                                       options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let rssi = RSSI.intValue
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Unknown"
        let id = peripheral.identifier

        pendingLock.lock()
        pending[id] = Device(id: id, name: name, rssi: rssi, lastSeen: Date())
        let cutoff = Date().addingTimeInterval(-8)
        pending = pending.filter { $0.value.lastSeen > cutoff }
        let list = Array(pending.values).sorted { $0.rssi > $1.rssi }
        pendingLock.unlock()

        let trimmed = Array(list.prefix(40))
        let density: Double
        if list.isEmpty {
            density = 0
        } else {
            let avg = list.map { Double($0.rssi) }.reduce(0, +) / Double(list.count)
            let count = Double(list.count)
            density = min(1.0, count / 30.0) * 0.5 + (1.0 - min(1.0, abs(avg + 100) / 60.0)) * 0.5
        }

        devices = trimmed
        rfDensity = density
    }
}
