//
//  MainViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction
    func backToMainViewController(segue: UIStoryboardSegue) { }
    
    @IBAction func deviceMonitorButton(sender: DeviceMonitorButton) {
        sender.animateTouchUpInside {
            self.performSegueWithIdentifier("presentSettings", sender: sender)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController
        if let navigation = destination as? UINavigationController,
            settings = navigation.topViewController as? MainSettingsViewController {
                
        }
    }


}
