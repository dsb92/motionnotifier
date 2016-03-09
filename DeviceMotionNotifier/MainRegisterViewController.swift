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
        self.registerButton.setTitle("REGISTER", forState: UIControlState.Normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theme = SettingsTheme.theme01
        
        setupNavigationBar()
        setupSlidebarMenu()
        
        appDelegate.hubs.ParseConnectionString()
        appDelegate.hubs.registerClient = RegisterClient(endpoint: BACKEND_ENDPOINT)
    }
    
    private func setupNavigationBar() {
        print(navigationController)
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
    
    @IBAction
    func backToMainRegisterViewController(segue: UIStoryboardSegue) { }

    @IBAction
    func RegisterButtonAction(sender: UIButton) {
        
        // Register device here
        
        let deviceName = settingsViewController.nameOfDeviceTextField.text
        let deviceToMonitor = settingsViewController.nameOfDeviceToMonitorTextField.text;
        // OBS
        let pass = deviceName
        
        registerButton.setTitle("", forState: UIControlState.Normal)
        spinner.startAnimating()

        //self.performSegueWithIdentifier("presentMain", sender: self)

        appDelegate.hubs.createAndSetAuthenticationHeaderWithUsername(deviceName, andPassword: pass)
        appDelegate.hubs.registerClient.registerWithDeviceToken(appDelegate.hubs.deviceToken, tags: nil) { (error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                
                self.spinner.stopAnimating()

                if (error == nil) {
                    
                    self.appDelegate.hubs.MessageBox("Success", message: "Registered successfully!")
                    self.appDelegate.hubs.userName = deviceName
                    self.appDelegate.hubs.recipientName = deviceToMonitor
                    self.appDelegate.hubs.notificationMessage = "Intruder alert!";
                    
                    self.performSegueWithIdentifier("presentMain", sender: self)
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

