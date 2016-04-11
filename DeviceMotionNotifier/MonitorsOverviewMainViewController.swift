//
//  MainViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MonitorsOverviewMainViewController: UIViewController {

    @IBOutlet
    weak var navigationBar: UINavigationBar!
   
    @IBOutlet
    weak var startDeviceMonitorButton: MonitorButton!
    
    @IBOutlet
    weak var bannerView: GADBannerView!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
            self.navigationBar.barTintColor = theme.backgroundColor
            self.startDeviceMonitorButton.borderColor = theme.primaryColor
            self.startDeviceMonitorButton.setTitleColor(theme.secondaryColor, forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadAds()
        
        theme = SettingsTheme.theme01
    }
    
    private func setupNavigationBar() {
        print(navigationController)
        self.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.translucent = true
        self.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "GothamPro", size: 20)!,
            NSForegroundColorAttributeName: UIColor.blackColor()
        ]
    }
    
    private func loadAds() {
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        // Test
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        // Live
        //bannerView.adUnitID = "ca-app-pub-2595377837159656/1504782129"
        
        bannerView.rootViewController = self
        bannerView.loadRequest(GADRequest())
    }
  
    @IBAction
    func backToMainViewController(segue: UIStoryboardSegue) { }
    
    @IBAction
    func deviceMonitorButton(sender: MonitorButton) {
        sender.animateTouchUpInside {
            let alarmSB = UIStoryboard(name: "Alarm", bundle: nil)
            let initialVC = alarmSB.instantiateInitialViewController()
            self.presentViewController(initialVC!, animated: true, completion: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        let destination = segue.destinationViewController
//        if let navigation = destination as? UINavigationController,
//            settings = navigation.topViewController as? MainSettingsViewController {
//                
//        }
    }


}
