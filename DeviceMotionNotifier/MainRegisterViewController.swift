//
//  ViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class MainRegisterViewController: UIViewController {

    @IBOutlet
    weak var registerButton: UIButton!
    
    @IBOutlet
    weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet
    weak var menuButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    private var settingsViewController: MainRegisterSettingsViewController!
    
    var theme: SettingsTheme! {
        didSet {
            registerButton?.backgroundColor = theme.primaryColor
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let deviceRegistered = NSUserDefaults.standardUserDefaults().boolForKey("kdeviceRegistered")
        let registerButtonTitle = deviceRegistered ? "CONTINUE" : "REGISTER"
        self.registerButton.setTitle(registerButtonTitle, forState: UIControlState.Normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theme = SettingsTheme.theme01
        
        setupNavigationBar()
        setupSlidebarMenu()
        setDefaults()
        
        appDelegate.hubs.ParseConnectionString()
        appDelegate.hubs.registerClient = RegisterClient(endpoint: BACKEND_ENDPOINT)
    }
    
    private func setupNavigationBar() {
        navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.translucent = true
        navigationController!.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "GothamPro", size: 20)!,
            NSForegroundColorAttributeName: UIColor.blackColor()
        ]
    }
    
    private func setupSlidebarMenu() {
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            // if iPad:
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                self.revealViewController().rearViewRevealWidth = 600
            }
            
        }
    }
    
    private func setDefaults(){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("kRemoveAdsSwitchValue") == nil {
            userDefaults.setObject(false, forKey: "kRemoveAdsSwitchValue")
        }
        
        userDefaults.synchronize()
    }
    
    @IBAction
    func backToMainRegisterViewController(segue: UIStoryboardSegue) { }

    @IBAction
    func RegisterButtonAction(sender: UIButton) {
        
        // Register device here
        
        var deviceToMonitor = settingsViewController.nameOfDeviceToMonitorTextField.text
        var deviceToNotify = settingsViewController.nameOfDeviceToNotifyTextField.text;
        
        if (deviceToNotify!.isEmpty) {
            JSSAlertView().warning(self, title: "Please turn on bluetooth on both devices", buttonText: "OK")
            settingsViewController.nameOfDeviceToNotifyTextField.becomeFirstResponder()
            return
        }
        
        registerButton.setTitle("", forState: UIControlState.Normal)
        spinner.startAnimating()

        // trim the names
        deviceToMonitor = deviceToMonitor?.stringByReplacingOccurrencesOfString(" ", withString: "")
        deviceToNotify = deviceToNotify?.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // OBS Password same as name of device
        let pass = deviceToMonitor
        
        appDelegate.hubs.createAndSetAuthenticationHeaderWithUsername(deviceToMonitor, andPassword: pass)
        appDelegate.hubs.registerClient.registerWithDeviceToken(appDelegate.hubs.deviceToken, tags: nil) { (error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.spinner.stopAnimating()

                if (error == nil) {
                    
                    let deviceRegistered = NSUserDefaults.standardUserDefaults().boolForKey("kdeviceRegistered")
                    
                    if !deviceRegistered {
                        self.appDelegate.hubs.MessageBox("Success", message: "Registered successfully!")
                        self.appDelegate.hubs.userName = deviceToMonitor
                        self.appDelegate.hubs.recipientName = deviceToNotify
                        self.appDelegate.hubs.notificationMessage = "Intruder alert!";
                        
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "kdeviceRegistered")
                    }
                    
                    let alarmSB = UIStoryboard(name: "Alarm", bundle: nil)
                    let initialVC = alarmSB.instantiateInitialViewController()
                    self.presentViewController(initialVC!, animated: true, completion: nil)
                }
                else{
                    self.appDelegate.hubs.MessageBox("Fail", message: "Failed to register")
                }
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let settings = segue.destinationViewController as? MainRegisterSettingsViewController {
            settingsViewController = settings
        }
    }
}

