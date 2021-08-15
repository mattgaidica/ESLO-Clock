//
// ViewController.swift
// BLEPeripheralApp
// see https://blog.usejournal.com/creating-ios-application-as-bluetooth-peripheral-669404230232
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController,CBPeripheralManagerDelegate {
    @IBOutlet weak var ClockLabel: UILabel!
    @IBOutlet weak var MessageLabel: UILabel!
    @IBOutlet weak var ClockIntegerLabel: UILabel!
    @IBOutlet weak var TransmitImage: UIImageView!
    
    // init
    private var service: CBUUID!
    private var myCharacteristic: CBMutableCharacteristic!
    private var value:UInt32 = 0
    private var peripheralManager : CBPeripheralManager!
    var ClockTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
        case .resetting:
            print("Bluetooth Device is RESETTING")
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            addServices()
        @unknown default:
            fatalError()
        }
    }

    func addServices() {
        let valueData = getClockData()
        // 1. Create instance of CBMutableCharcateristic
        myCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "EFFF"), properties: [.read], value: valueData, permissions: [.readable])
        // 2. Create instance of CBMutableService
        service = CBUUID(string: "EFFE")
        let myService = CBMutableService(type: service, primary: true)
        // 3. Add characteristics to the service
        myService.characteristics = [myCharacteristic]
        // 4. Add service to peripheralManager
        peripheralManager.add(myService)
        // 5. Start advertising
        startAdvertising()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
         if let error = error {
            print("Add service failed: \(error.localizedDescription)")
            return
        }
        print("Add service succeeded")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Start advertising failed: \(error.localizedDescription)")
            return
        }
        print("Start advertising succeeded")
        TransmitImage.isHidden = false
        startClock()
    }

    func startAdvertising() {
        MessageLabel.text = "Advertising"
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "ESLOTime", CBAdvertisementDataServiceUUIDsKey : [service]])
        print("Started Advertising")
    }
    
    func getClockData() -> Data {
        let secondsSince1970 = NSDate().timeIntervalSince1970
        value = UInt32(secondsSince1970)
        let valueData = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        ClockLabel.text = String(format: "0x%llX", value)
        ClockIntegerLabel.text = String(value)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.TransmitImage.transform = .init(scaleX: 1.25, y: 1.25)
        }) { (finished: Bool) -> Void in
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.TransmitImage.transform = .identity
            })
        }
        return valueData
    }
    
    func startClock() {
        self.ClockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            self.peripheralManager.stopAdvertising()
            self.peripheralManager.removeAllServices()
            self.addServices()
        }
    }
}
