//
//  MainViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class MonitorsOverviewMainViewController: UIViewController {

    @IBOutlet
    weak var navigationBar: UINavigationBar!
   
    @IBOutlet
    weak var startDeviceMonitorButton: MonitorButton!
    
    @IBOutlet
    weak var startBabyMonitorButton: UIButton!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
            self.navigationBar.barTintColor = theme.backgroundColor
            self.startDeviceMonitorButton.borderColor = theme.primaryColor
            self.startDeviceMonitorButton.setTitleColor(theme.secondaryColor, forState: UIControlState.Normal)
            self.startBabyMonitorButton.borderColor = theme.primaryColor
            self.startBabyMonitorButton.setTitleColor(theme.secondaryColor, forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
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

    @IBAction
    func babyMonitorButtonAction(sender: MonitorButton) {
        sender.animateTouchUpInside { () -> Void in
            let babySB = UIStoryboard(name: "Baby", bundle: nil)
            let initialVC = babySB.instantiateInitialViewController()
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
