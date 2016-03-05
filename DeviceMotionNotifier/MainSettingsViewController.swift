//
//  ViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class MainSettingsViewController: UIViewController {

    @IBOutlet
    weak var registerButton: UIButton!
    
    @IBOutlet
    weak var spinner: UIActivityIndicatorView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    private var settingsViewController: SettingsViewController!
    
    var theme: SettingsTheme! {
        didSet {
            settingsViewController?.theme = theme
            registerButton?.backgroundColor = theme.primaryColor
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.registerButton.setTitle("REGISTER", forState: UIControlState.Normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.hubs.ParseConnectionString()
        appDelegate.hubs.registerClient = RegisterClient(endpoint: BACKEND_ENDPOINT)
    }

    @IBAction func RegisterButtonAction(sender: UIButton) {
        
        // Register device here
        
        let deviceName = settingsViewController.nameOfDeviceTextField.text
        let deviceToMonitor = settingsViewController.nameOfDeviceToMonitorTextField.text;
        // OBS
        let pass = deviceName
        
        registerButton.setTitle("", forState: UIControlState.Normal)
        spinner.startAnimating()
        appDelegate.hubs.createAndSetAuthenticationHeaderWithUsername(deviceName, andPassword: pass)
        appDelegate.hubs.registerClient.registerWithDeviceToken(appDelegate.hubs.deviceToken, tags: nil) { (error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.spinner.stopAnimating()

                if (error == nil) {
                    
                    self.appDelegate.hubs.MessageBox("Success", message: "Registered successfully!")
                    self.appDelegate.hubs.userName = deviceName
                    self.appDelegate.hubs.recipientName = deviceToMonitor
                    self.appDelegate.hubs.notificationMessage = "Intruder alert!";
                    
                    self.performSegueWithIdentifier("presentAlarm", sender: self)
                }
                else{
                    self.appDelegate.hubs.MessageBox("Fail", message: "Failed to register")
                }
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let settings = segue.destinationViewController as? SettingsViewController {
            settingsViewController = settings
        }
    }
}

