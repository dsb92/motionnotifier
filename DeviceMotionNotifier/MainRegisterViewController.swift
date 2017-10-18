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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    fileprivate var settingsViewController: MainRegisterSettingsViewController!
    
    var theme: SettingsTheme! {
        didSet {
            registerButton?.backgroundColor = theme.blueColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerButton.setTitle(getButtonText(), for: UIControlState())
        registerButton.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theme = SettingsTheme.theme01
        
        setupNavigationBar()
        setupSlidebarMenu()
        setDefaults()
        
        appDelegate.hubs.parseConnectionString()
        appDelegate.hubs.registerClient = RegisterClient(endpoint: BACKEND_ENDPOINT)
    }
    
    fileprivate func setupNavigationBar() {
        navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.isTranslucent = true
        navigationController!.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "GothamPro", size: 20)!,
            NSForegroundColorAttributeName: UIColor.white
        ]
    }
    
    fileprivate func setupSlidebarMenu() {
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            // if iPad:
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.revealViewController().rearViewRevealWidth = 600
            }
            else {
                self.revealViewController().rearViewRevealWidth = UIScreen().bounds.size.width - 30
            }
            
        }
    }
    
    fileprivate func setDefaults(){
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "kRemoveAdsSwitchValue") == nil {
            userDefaults.set(false, forKey: "kRemoveAdsSwitchValue")
        }
        
        userDefaults.synchronize()
    }
    
    fileprivate func getButtonText() -> String {
        let deviceRegistered = UserDefaults.standard.bool(forKey: "kdeviceRegistered")
        let registerButtonTitle = deviceRegistered ? "CONTINUE" : "REGISTER ALARM"
        return registerButtonTitle
    }
    
    @IBAction
    func backToMainRegisterViewController(_ segue: UIStoryboardSegue) { }

    @IBAction
    func RegisterButtonAction(_ sender: UIButton) {
        
        // Dont let user press button more than once
        registerButton.isEnabled = false
        
        // Register device here
        
        var deviceToMonitor = settingsViewController.nameOfDeviceToMonitorTextField.text
        var deviceToNotify = settingsViewController.nameOfDeviceToNotifyTextField.text;
        
        if (deviceToNotify!.isEmpty) {
            JSSAlertView().warning(self, title: "Warning", text: "Please turn on bluetooth on both devices")
            settingsViewController.nameOfDeviceToNotifyTextField.becomeFirstResponder()
            return
        }
        
        registerButton.setTitle("", for: UIControlState())
        
        spinner.startAnimating()

        // set '-' on white spaces
        deviceToMonitor = deviceToMonitor?.replacingOccurrences(of: " ", with: "-")
        deviceToNotify = deviceToNotify?.replacingOccurrences(of: " ", with: "-")
        
        // OBS Password same as name of device
        let pass = deviceToMonitor
        
        self.appDelegate.hubs.createAndSetAuthenticationHeader(withUsername: deviceToMonitor, andPassword: pass)
        
        if self.appDelegate.hubs.deviceToken != nil {
            self.appDelegate.hubs.registerClient.register(withDeviceToken: self.appDelegate.hubs.deviceToken, tags: nil) { (error) -> Void in
                
                DispatchQueue.main.async(execute: {
                    
                    self.spinner.stopAnimating()
                    
                    if (error == nil) {
                        
                        let deviceRegistered = UserDefaults.standard.bool(forKey: "kdeviceRegistered")
                        
                        if !deviceRegistered {
                            UserDefaults.standard.set(true, forKey: "kdeviceRegistered")
                        }
                        
                        self.appDelegate.hubs.userName = deviceToMonitor
                        self.appDelegate.hubs.recipientName = deviceToNotify
                        self.appDelegate.hubs.notificationMessage = Constants.Notifications.IntruderMessage
                        
                        let alarmSB = UIStoryboard(name: "Alarm", bundle: nil)
                        let initialVC = alarmSB.instantiateInitialViewController()
                        self.present(initialVC!, animated: true, completion: nil)
                    }
                    else{
                        JSSAlertView().danger(self, title: "Failed to register, please try again")
                        self.registerButton.setTitle(self.getButtonText(), for: UIControlState())
                        self.registerButton.isEnabled = true
                    }
                })
            }

        }
        else{
            print("ERROR: Device token nil, cannot register...")
            
            self.spinner.stopAnimating()
            JSSAlertView().danger(self, title: "Failed to register, please try again")
            self.registerButton.setTitle(self.getButtonText(), for: UIControlState())
            registerButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settings = segue.destination as? MainRegisterSettingsViewController {
            settingsViewController = settings
        }
    }
}

