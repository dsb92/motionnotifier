//
//  ViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var nameForDeviceTextField: UITextField!
    @IBOutlet weak var recpientTextField: UITextField!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        appDelegate.hubs.ParseConnectionString()
        
        appDelegate.hubs.registerClient = RegisterClient(endpoint: BACKEND_ENDPOINT)
        
        nameForDeviceTextField.delegate = self
        recpientTextField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func RegisterButtonAction(sender: UIButton) {
        
        // Register device here
        
        let username = self.nameForDeviceTextField.text
        // OBS
        let pass = username
        
        appDelegate.hubs.createAndSetAuthenticationHeaderWithUsername(username, andPassword: pass)
        
        appDelegate.hubs.registerClient.registerWithDeviceToken(appDelegate.hubs.deviceToken, tags: nil) { (error) -> Void in
            
            if (error == nil) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.appDelegate.hubs.MessageBox("Success", message: "Registered successfully!")
                    
                    let username = self.nameForDeviceTextField.text
                    self.appDelegate.hubs.userName = username
                    self.appDelegate.hubs.recipientName = self.recpientTextField.text;
                    self.appDelegate.hubs.notificationMessage = "Intruder alert!";
                    
                    self.performSegueWithIdentifier("alarmVCIdentifier", sender: self)
                })
            }
            else{
                self.appDelegate.hubs.MessageBox("Fail", message: "Failed to register")
            }
            
        }
    }
    @IBAction func SendNotificationAction(sender: UIButton) {
        
        self.appDelegate.hubs.SendToEnabledPlatforms()
    }

}

