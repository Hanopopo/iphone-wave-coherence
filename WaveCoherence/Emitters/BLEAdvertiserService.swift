import CoreBluetooth
import Foundation

// Broadcasts a low-power BLE advertisement (the "intention beacon").
// Free Apple ID compatible: no background mode required in foreground.
final class BLEAdvertiserService: NSObject, ObservableObject {
    @Published private(set) var isAdvertising = false
    @Published private(set) var state: CBManagerState = .unknown
    @Published var localName: String = "WaveCoherence"
    @Published var intentionTag: String = "coherence"

    private var peripheral: CBPeripheralManager?

    func start() {
        if peripheral == nil {
            peripheral = CBPeripheralManager(delegate: self, queue: .main, options: [CBPeripheralManagerOptionShowPowerAlertKey: false])
        }
        startIfReady()
    }

    func stop() {
        peripheral?.stopAdvertising()
        isAdvertising = false
    }

    private func startIfReady() {
        guard let p = peripheral, p.state == .poweredOn else { return }
        let name = "\(localName) · \(intentionTag)".prefix(20)
        // 128-bit service UUID; first 16 bits encode the carrier frequency * 10 (e.g. 0x7E83 = 32387).
        let serviceUUID = CBUUID(string: "00007E83-C0DE-4AE7-9C0A-EFC0DEC0DEC0")
        let data: [String: Any] = [
            CBAdvertisementDataLocalNameKey: String(name),
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ]
        p.startAdvertising(data)
        isAdvertising = true
    }
}

extension BLEAdvertiserService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        state = peripheral.state
        if state == .poweredOn, !isAdvertising {
            startIfReady()
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        isAdvertising = error == nil
    }
}
