import Foundation
import CoreBluetooth
import IOBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    var centralManagerBLE: CBCentralManager!
    var magicMouse: CBPeripheral!
    var serviceUUID:CBUUID!  //Look into Bluetooth Specs
    var characteristicsUUID:CBUUID!
    
    var isAdvertisingBLE:Bool!
    // Real Data
    var discoveredPeripheral: CBPeripheral?
    var transferCharacteristic: CBCharacteristic?
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0
    
    let defaultIterations = 5     // change this value based on test usecase
    
    var data = Data()
    
    // Peripheral Data
    
    var transferCharacteristicBLE: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    var sendingEOM = false
    
    override init() {
        centralManagerBLE = CBCentralManager()
        serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")   //Look into Bluetooth Specs
        characteristicsUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
        print("BLE Manager Initialized")
        
    }
    
    private func retrievePeripheral() {
        
        let connectedPeripherals: [CBPeripheral] = (centralManagerBLE.retrieveConnectedPeripherals(withServices: [serviceUUID]))
        
        print("Found connected Peripherals with transfer service: %@", connectedPeripherals.first)
        
        if let connectedPeripheral = connectedPeripherals.last {
            print("Connecting to peripheral %@", connectedPeripheral)
            self.discoveredPeripheral = connectedPeripheral
            centralManagerBLE.connect(connectedPeripheral, options: nil)
        } else {
            centralManagerBLE.scanForPeripherals(withServices: [serviceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    private func cleanup() {
        // Don't do anything if we're not connected
        guard let discoveredPeripheral = discoveredPeripheral,
            case .connected = discoveredPeripheral.state else { return }
        
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == characteristicsUUID && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        
        // If we've gotten this far, we're connected, but we're not subscribed, so we just disconnect
        centralManagerBLE.cancelPeripheralConnection(discoveredPeripheral)
    }
    
    private func writeData() {
        
        guard let discoveredPeripheral = discoveredPeripheral,
            let transferCharacteristic = transferCharacteristic
            else { return }
        
        // check to see if number of iterations completed and peripheral can accept more data
        while writeIterationsComplete < defaultIterations && discoveredPeripheral.canSendWriteWithoutResponse {
            
            let mtu = discoveredPeripheral.maximumWriteValueLength (for: .withoutResponse)
            var rawPacket = [UInt8]()
            
            let bytesToCopy: size_t = min(mtu, data.count)
            data.copyBytes(to: &rawPacket, count: bytesToCopy)
            let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
            
            let stringFromData = String(data: packetData, encoding: .utf8)
            print("Writing %d bytes: %s", bytesToCopy, String(describing: stringFromData))
            
            discoveredPeripheral.writeValue(packetData, for: transferCharacteristic, type: .withoutResponse)
            
            writeIterationsComplete += 1
            
        }
        
        if writeIterationsComplete == defaultIterations {
            // Cancel our subscription to the characteristic
            discoveredPeripheral.setNotifyValue(false, for: transferCharacteristic)
        }
    }
    
    
    // Central Manager Delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on")
            retrievePeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            break
        case .resetting:
            print("CBManager is resetting")
        case .unauthorized:
            print("Unauthorized")
            break
        case .unknown:
            print("CBManager state is unknown")
            break
        case .unsupported:
            print("Bluetooth is not supported on this device")
            break
        @unknown default:
            print("A previously unknown central manager state occurred")
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        guard RSSI.intValue >= -50
            else {
                print("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
                return
        }
        
        print("Discovered %s at %d", String(describing: peripheral.name), RSSI.intValue)
        
        // Device is in range - have we already seen it?
            
            // And finally, connect to the peripheral.
        print("Connecting to perhiperal %@", peripheral)
        centralManagerBLE.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to %@. %s", peripheral, String(describing: error))
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        centralManagerBLE.stopScan()
        print("Scanning stopped")
        
        // set iteration info
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        
        // Clear the data that we may already have
        data.removeAll(keepingCapacity: false)
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([serviceUUID])
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhiperal Disconnected")
        discoveredPeripheral = nil
        
        // We're disconnected, so start scanning again
        if connectionIterationsComplete < defaultIterations {
            retrievePeripheral()
        } else {
            print("Connection iterations completed")
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == serviceUUID {
            print("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([serviceUUID])
        }
    }
    
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([characteristicsUUID], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == characteristicsUUID {
            // If it is, subscribe to it
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        print("Received %d bytes: %s", characteristicData.count, stringFromData)
        
        // Have we received the end-of-message token?
        if stringFromData == "EOM" {
            // End-of-message case: show the data.
            // Dispatch the text view update to the main queue for updating the UI, because
            // we don't know which thread this method will be called back on.
            DispatchQueue.main.async() {
                print(String(data: self.data, encoding: .utf8))
            }
            
            // Write test data
            writeData()
        } else {
            // Otherwise, just append the data to what we have previously received.
            data.append(characteristicData)
        }
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == characteristicsUUID else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            print("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            print("Notification stopped on %@. Disconnecting", characteristic)
            cleanup()
        }
        
    }
    
    /*
     *  This is called when peripheral is ready to accept more data when using write without response
     */
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("Peripheral is ready, send data")
        writeData()
    }
    
}

// NEW CLASS

class PeripheralManagerBLE: NSObject, CBPeripheralDelegate {
    
    var serviceUUID:CBUUID!  //Look into Bluetooth Specs
    var characteristicsUUID:CBUUID!
    
    var peripheralManager: CBPeripheralManager!
    
    var transferCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()
    var sendDataIndex: Int = 0

    var isAdvertising:Bool!
    override init() {
        peripheralManager = CBPeripheralManager()
        serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")   //Look into Bluetooth Specs
        characteristicsUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
        isAdvertising = false
        print("Peripheral Manager Initialized")
    }

    static var sendingEOM = false
    
    private func sendData() {
        
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // First up, check if we're meant to be sending an EOM
        if PeripheralManagerBLE.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                PeripheralManagerBLE.sendingEOM = false
                print("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                PeripheralManagerBLE.sendingEOM = true
                
                //Send it
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                            for: transferCharacteristic, onSubscribedCentrals: nil)
                
                if eomSent {
                    // It sent; we're all done
                    PeripheralManagerBLE.sendingEOM = false
                    print("Sent: EOM")
                }
                return
            }
        }
    }
    
    private func setupPeripheral() {
        
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let transferCharacteristic = CBMutableCharacteristic(type: characteristicsUUID,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic
        
    }
}

extension PeripheralManagerBLE: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        peripheralManagerDidUpdateState(peripheral, strValue: "Something")
    }
    
    // implementations of the CBPeripheralManagerDelegate methods
    
    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager, strValue: String){
        
        isAdvertising = peripheral.state == .poweredOn
        
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on. Setting Up Peripheral for Transfer Service.")
            setupPeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            break
        case .resetting:
            print("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            break
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *){
                print("Available")
            }
        case .unknown:
            print("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            break
        case .unsupported:
            print("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            break
        @unknown default:
            print("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            break
        }
        print("Updated Peripheral State")
    }
    
    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic")
        
        // Get the data
        dataToSend = "".data(using: .utf8)!
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central
        
        // Start sending
        sendData()
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            
            print("Received write request of %d bytes: %s", requestValue.count, stringFromData)
            print(stringFromData)
        }
    }
}

