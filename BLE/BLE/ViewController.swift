import Cocoa
import CoreBluetooth

class ViewController: NSViewController{
    
    var bleManager:BLEManager!
    var blePeripheralManager:PeripheralManagerBLE!
    
    @IBOutlet weak var adButton: NSButton!
    @IBOutlet weak var modeButton: NSButton!
    
    var isCentral: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        isCentral = false
    }
    override func viewWillDisappear() {
        bleManager.centralManagerBLE.stopScan()
        print("Scanning stopped")
        bleManager.data.removeAll(keepingCapacity: false)
        blePeripheralManager.peripheralManager.stopAdvertising()
        super.viewWillDisappear()
    }
    
    @IBAction func adChange(_ sender: NSButton) {
        if(isCentral){
            print("Advertising Does Not Apply In Central Mode")
        }
        else{
            blePeripheralManager.isAdvertising = !blePeripheralManager.isAdvertising
            if(blePeripheralManager.isAdvertising){
        blePeripheralManager.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [blePeripheralManager.serviceUUID]])
                print("Is Advertising")
            }
            else{
                blePeripheralManager.peripheralManager.stopAdvertising()
                print("Is Not Advertising")
            }
        }
    }
    
    @IBAction func changeMode(_ sender: NSButton) {
        isCentral = !isCentral
        if(isCentral){
            bleManager = BLEManager()
            bleManager.centralManagerBLE.delegate = bleManager
            print("Central Mode")
        }
        else{
            blePeripheralManager = PeripheralManagerBLE()
            blePeripheralManager.peripheralManager.delegate = blePeripheralManager
            print("Peripheral Mode")
        }
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

