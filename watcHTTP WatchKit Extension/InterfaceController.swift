//
//  InterfaceController.swift
//  watcHTTP WatchKit Extension
//
//  Created by Leo Nesfield on 12/8/19.
//  Copyright © 2019 Leo Nesfield. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire



class InterfaceController: WKInterfaceController {
    @IBOutlet weak var endpointPicker: WKInterfacePicker!
    @IBOutlet weak var sendBtn: WKInterfaceButton!
    
    var progressTracker = 0
    var loadingTimer = Timer()

    func startProgressIndicator() {
        progressTracker = 0
        loadingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    var loaderChars = ["⠙","⠸","⠴","⠦","⠇","⠋"]
    @objc func updateProgress() {
        progressTracker += 1
        if (loaderChars.count - 1 < progressTracker) {
            progressTracker = 0
        }
        sendBtn.setTitle(loaderChars[progressTracker])
    }

    func stopProgressIndicator() {
        sendBtn.setTitle("Send")
        loadingTimer.invalidate()
    }
    
    var REQUEST_PREFIX = "http://192.168.1.148:3435/"
    
    var i = "none"
    @IBAction func sendBtnPressed() {
        startProgressIndicator()
        sendBtn.setEnabled(false)
        endpointPicker.setEnabled(false)
        print("Requesting \(i)")
        AF.request(i).responseString { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            let action1 = WKAlertAction(title: "Done", style: .cancel) {}

            self.presentAlert(withTitle: "Response code: \(response.response?.statusCode ?? 000)", message: "\(response.result)", preferredStyle: .actionSheet, actions: [action1])
            self.endpointPicker.setEnabled(true)
            self.sendBtn.setEnabled(true)
            self.stopProgressIndicator()
        }
    }
    struct defaultsKeys {
        static let requestprefix = "requestprefix"
    }
    var endpointLists: [(String,String)] = [
        ("One","http://192.168.1.148:3435/one"),
        ("Two","http://192.168.1.148:3435/two")
    ]
    override func willActivate() {
        super.willActivate()
        
        let pickerItems: [WKPickerItem] = endpointLists.map {
            let pickerItem = WKPickerItem()
            pickerItem.title = $0.0
            pickerItem.caption = $0.1
            return pickerItem
        }
        i = endpointLists[0].1
        endpointPicker.setItems(pickerItems)
    }
    
    @IBAction func pickerSelectedItemChanged(value: Int) {
        print("List Picker: \(endpointLists[value].0) selected")
        i = endpointLists[value].1
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
