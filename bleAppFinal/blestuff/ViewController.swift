//
//  ViewController.swift
//  blestuff
//
//  Created by Eric on 2/5/19.
//  Copyright © 2019 Eric. All rights reserved.
//


import UIKit
import CoreBluetooth

extension UIViewController{// in an extension so can access it anywhere
    func HideKeyboard(){
        let Tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))// dismissing keyboard when tapping anywhere on screen
        
        view.addGestureRecognizer(Tap)
    }
    @objc func DismissKeyboard(){
        
        view.endEditing(true)
    }
}

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITextFieldDelegate  {
    
    
    @IBOutlet weak var btnON: UIButton!
    
    @IBOutlet weak var btnOFF: UIButton!
    
    @IBOutlet weak var btnConnect: UIButton!
    
    @IBOutlet weak var btnDisconnect: UIButton!
    @IBOutlet weak var lblDATA: UILabel!
    
    @IBOutlet weak var labelSentTemp: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var senttemplabelapper: UILabel!
    
    @IBOutlet weak var RoomTempLabel: UILabel!
    var settemp = ""// save old set temp to display
    
    @IBAction func senddata(_ sender: Any) {
        
        if validate(textField: textField) {// checks if text field blank
            // if not blank send data and set things up
            writeValue(onOff: textField.text!)// send data to arduino
            settemp = textField.text!// save old data sent
            textField.text = ""// set textfield to blank
            DismissKeyboard()// after send get rid of keyboard
            senttemplabelapper.isHidden = false// let labels appear
            labelSentTemp.isHidden = false
            labelSentTemp.text = settemp// set the label to ned data
        } else {
            print("Nothing entered")// if nothing here just print in debug terminal nothing entered
        }
        
    }
    var manager : CBCentralManager!
    var myBluetoothPeripheral : CBPeripheral!
    var myCharacteristic : CBCharacteristic!
    
    var isMyPeripheralConected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        senttemplabelapper.isHidden = true// set labels to be hidden until you send temperature
        labelSentTemp.isHidden = true
        
        RoomTempLabel.isHidden = true// set both off room temperature labes to hide unless data
        lblDATA.isHidden = true
        
        textField.keyboardType = UIKeyboardType.numberPad// set keyboard to number pad
        
        self.HideKeyboard()// hides keyboard on tap
        textField.delegate = self// must do this to dismiss keyboard
        initSetup()
        manager = CBCentralManager(delegate: self, queue: nil)// calling to look for the ble module
        // then later auto connects
        
        
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 2// sets keyboard to only allow 2 numbers to be sent
        // I have arduino set to only allow 2 values to be sent so if more get send it causes problems
    }
    
    @IBAction func discoverPeripheral(_ sender: Any) {
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func connect(_ sender: Any) {
        
        manager.connect(myBluetoothPeripheral, options: nil) //connect to my peripheral
        
    }
    
    @IBAction func switchOn(_ sender: Any) {
        writeValue(onOff: "a")
    }
    
    
    @IBAction func switchOf(_ sender: Any) {
        writeValue(onOff: "d")
    }
    
    
    @IBAction func disconnect(_ sender: Any) {
        manager.cancelPeripheralConnection(myBluetoothPeripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        var msg = ""
        
        switch central.state {
            
        case .poweredOff:
            msg = "Bluetooth is Off"
        case .poweredOn:
            msg = "Bluetooth is On"
            manager.scanForPeripherals(withServices: nil, options: nil)
        case .unsupported:
            msg = "Not Supported"
        default:
            msg = ""
            
        }
        
        print("STATE: " + msg)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        //you are going to use the name here down here ⇩
        
        if peripheral.name == "AIR1278" { //if is it my peripheral, then connect
            print("AYO")
          //  lblPeripheralName.isHidden = true// set to false to show name of what you are connecting to
        //    lblPeripheralName.text = peripheral.name ?? "Default"
            
            self.myBluetoothPeripheral = peripheral     //save peripheral
            self.myBluetoothPeripheral.delegate = self
            
            manager.stopScan()                          //stop scanning for peripherals
            manager.connect(myBluetoothPeripheral, options: nil)// when i put this here it auto connects to the air1278 module
            // if not we it will just chill   This will technically not run since name !- air1278
            // good for security reasons becuase they dont know what i am connecing to
            // also user does not know what to connect to
            // looks like magic
            // 2/12/19
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isMyPeripheralConected = true //when connected change to true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        initSetup()
    }
    
    
    func initSetup(){
        initUI()
        initLogic()
        
    }
    
    func initUI(){
        
      //  btnDiscoverPeripheral.setTitle("Discocer Devices", for: .normal)
      //  lblPeripheralName.text = "Discovering..."
        btnConnect.setTitle("Connect", for: .normal)
        btnDisconnect.setTitle("Disconnected", for: .normal)
        btnDisconnect.isEnabled = false
    //    lblPeripheralName.isHidden = true
    }
    
    func initLogic(){
        isMyPeripheralConected = false //and to falso when disconnected
        
        if myBluetoothPeripheral != nil{
            
            if myBluetoothPeripheral.delegate != nil {
                myBluetoothPeripheral.delegate = nil
            }
            
        }
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let servicePeripheral = peripheral.services as [CBService]! { //get the services of the perifereal
            
            for service in servicePeripheral {
                
                //Then look for the characteristics of the services
                print(service.uuid.uuidString)
                
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let characterArray = service.characteristics as [CBCharacteristic]! {
            
            for cc in characterArray {
                
                print(cc.uuid.uuidString)
                
                if(cc.uuid.uuidString == "FFE1") { //properties: read, write
                    //if you have another BLE module, you should print or look for the characteristic you need.
                    
                    myCharacteristic = cc //saved it to send data in another function.
                    
                    updateUiOnSuccessfullConnectionAfterFoundCharacteristics()
                    
                    myBluetoothPeripheral.setNotifyValue(true, for: myCharacteristic)// was missing this code
                    
                    /*in our example we have to write on and off, readValue does not make any sense for now. Uncomment when needed
                     peripheral.readValue(for: cc) //to read the value of the characteristic
                     
                     */
                }
                
            }
        }
        
    }
    
    func updateUiOnSuccessfullConnectionAfterFoundCharacteristics(){
        
        btnConnect.setTitle("Connected", for: .normal)
        btnDisconnect.setTitle("Disconnect", for: .normal)
        btnDisconnect.isEnabled = true
        
    }
    
    
   // in our example we have to write on and off, readValue does not make any sense for now. Uncomment when needed
     func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
     
     print(characteristic.uuid.uuidString)
     
     if (characteristic.uuid.uuidString == "FFE1") {
    
     
        guard let readValue = characteristic.value else{
            return
        }
        
    if let dataString = NSString.init(data: readValue, encoding: String.Encoding.utf8.rawValue) as String? {
        RoomTempLabel.isHidden = false
        lblDATA.isHidden = false
            lblDATA.text = dataString
            print(dataString)
            
        }
     
    
     }
     }
    
    
    
    //if you want to send an string you can use this function.
    func writeValue(onOff : String) {
        
        if isMyPeripheralConected { //check if myPeripheral is connected to send data
            
            let dataToSend: Data = onOff.data(using: String.Encoding.utf8)!
            
            myBluetoothPeripheral.writeValue(dataToSend, for: myCharacteristic, type: CBCharacteristicWriteType.withoutResponse)    //Writing the data to the peripheral
            
        } else {
            print("Not connected")
        }
    }
    func validate(textField textField: UITextField) -> Bool {// check to see if something in textfield
        guard let text = textField.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                // this will be reached if the text is nil (unlikely)
                // or if the text only contains white spaces
                // or no text at all
                return false
        }
        
        return true// if not send back all good
    }
    
}
