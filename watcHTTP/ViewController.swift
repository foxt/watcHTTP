//
//  ViewController.swift
//  watcHTTP
//
//  Created by Leo Nesfield on 13/8/19.
//  Copyright © 2019 Leo Nesfield. All rights reserved.
//

// this code is very messy and needs refactering by someone (possibly future me) who knows what they're doing

import UIKit
import WatchConnectivity

class ViewController: UIViewController, UITableViewDataSource,WCSessionDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var wcSession : WCSession! = nil
    var watchAvailable = false
    var watchAvailableString = "Watch unavailable 🙁"
    func loadConfig() {
        let saved = UserDefaults.standard.array(forKey: "endpoints")
        if (saved != nil) {
            data = saved as! [Array<String>]
        } else {
            let defaultData: [Array<String>] = [
                ["What's my public IP?","https://api.ipify.org/"],
                ["Random Word API","https://api.noopschallenge.com/wordbot"]]
            UserDefaults.standard.set(defaultData,forKey: "endpoints")
            loadConfig()
        }
    }
    func checkAvailability() {
        if WCSession.isSupported() { // check if the device support to handle an Apple Watch
            watchAvailable = wcSession.isPaired && wcSession.isWatchAppInstalled && wcSession.isReachable
            if (watchAvailable) {
                watchAvailableString = "Watch available!"
            } else {
                if (!wcSession.isPaired) {
                    watchAvailableString = "Watch not paired 🙁"
                } else if (!wcSession.isWatchAppInstalled) {
                    watchAvailableString = "Watch doesn't have app 🙁"
                } else if (!wcSession.isReachable) {
                    watchAvailableString = "Watch doesn't have app open 🙁"
                }
                
            }
        } else {
            watchAvailableString = "Unsupported!"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfig()
        
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateSelected), userInfo: nil, repeats: true)
        tableView.dataSource = self
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        checkAvailability()
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func saveData() {
        UserDefaults.standard.set(data,forKey: "endpoints")
        checkAvailability()
        loadConfig()
        if (watchAvailable) {
            wcSession.sendMessage(["data":data], replyHandler: nil) { (error) in
                let alert = UIAlertController(title: "Error saving to watch", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        self.tableView.reloadData()
        
    }
    
    @objc func updateSelected() {
        if (tableView.indexPathForSelectedRow != nil) {
            let ip = tableView.indexPathForSelectedRow
            tableView.deselectRow(at: (tableView.indexPathForSelectedRow)!, animated: true)
            if (ip?.section == 0) {
                print("Selected row \(data[ip!.row][0])")
                data.remove(at: (ip?.row)!)
                saveData()
            } else if (ip?.section == 1) {
                if (ip!.row == 0) {
                    let alertController = UIAlertController(title: "Add endpoint", message: "", preferredStyle: UIAlertController.Style.alert)
                    alertController.addTextField { (textField : UITextField!) -> Void in
                        textField.placeholder = "Friendly name (ex: Ping production server)"
                    }
                    alertController.addTextField { (textField : UITextField!) -> Void in
                        textField.placeholder = "URL (ex: http://192.256.128.25:1254/status)"
                        textField.keyboardType = UIKeyboardType.URL
                    }
                    let saveAction = UIAlertAction(title: "Add", style: UIAlertAction.Style.default, handler: { alert -> Void in
                        let firstTextField = alertController.textFields![0] as UITextField
                        let secondTextField = alertController.textFields![1] as UITextField
                        self.data.append([firstTextField.text!,secondTextField.text!])
                        self.saveData()
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                        (action : UIAlertAction!) -> Void in })
                    
                    
                    alertController.addAction(saveAction)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                } else if (ip!.row == 1) {
                    saveData()
                } else if (ip!.row == 2) {
                    UserDefaults.standard.removeObject(forKey: "endpoints")
                    loadConfig()
                    saveData()
                } else if (ip!.row == 3) {
                    let alert = UIAlertController(title: "watcHTTP Credits", message: "Developed by Leo Nesfield (theLMGN) in 2019.\nwatcHTTP is licenced under the GPLv3\nand uses code from the Alamofire project.\n\nhttps://github.com/thelmgn/watchttp", preferredStyle: UIAlertController.Style.alert)
                    
                    // add an action (button)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                    
                    // show the alert
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    private var data: [Array<String>] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return data.count
        } else {
            return 4
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")! //1.
        var text = "You shouldn't be seeing this."
        if (indexPath.section == 0) {
            let d = data[indexPath.row] //2.
            text = "\(d[0]) : \(d[1])"
        } else {
            if (indexPath.row == 0) {
                text = "Add Endpoint"
            } else if (indexPath.row == 1) {
                text = "Force watch refresh"
            } else if (indexPath.row == 2) {
                text = "Reset to example endpoints"
            } else if (indexPath.row == 3) {
                text = "About"
            } else {
                text = "You shouldn't be seeing this."
            }
        }
        cell.textLabel?.text = text //3.
        return cell //4.
    }
    var selectedCell: IndexPath = []
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Endpoints (tap to remove, editing not supported yet)"
        } else if (section == 1) {
            return watchAvailableString
        } else {
            return "You shouldn't be seeing this."
        }
    }
    
    
}

