import Cocoa
import CoreBluetooth

class ViewController: NSViewController{
    
    var bleManager:BLEManager!
    
    @IBOutlet weak var adButton: NSButton!
    @IBOutlet weak var modeButton: NSButton!
    
    var isCentral: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        bleManager = BLEManager()
        bleManager.centralManagerBLE.delegate = bleManager
        isCentral = false
        bleManager.isAdvertisingBLE = false
    }
    override func viewWillDisappear() {
        bleManager.centralManagerBLE.stopScan()
        print("Scanning stopped")
        bleManager.data.removeAll(keepingCapacity: false)
        bleManager.peripheralManagerBLE.stopAdvertising()
        super.viewWillDisappear()
    }
    
    @IBAction func adChange(_ sender: NSButton) {
        bleManager.isAdvertisingBLE = !bleManager.isAdvertisingBLE
        if(bleManager.isAdvertisingBLE){
    bleManager.peripheralManagerBLE.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [bleManager.serviceUUID]])
            print("Is Advertising")
        }
        else{
            bleManager.peripheralManagerBLE.stopAdvertising()
            print("Is Not Advertising")
        }
    }
    
    @IBAction func changeMode(_ sender: NSButton) {
        isCentral = !isCentral
        if(isCentral){
            print("Central Mode")
        }
        else{
            print("Peripheral Mode")
        }
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

