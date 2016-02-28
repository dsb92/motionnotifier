//
//  AlarmViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 25/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import CoreMotion

let threshold = 0.50

class AlarmViewController: UIViewController {
    
    @IBOutlet weak var alarmCountDownLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    @IBOutlet weak var numberPad: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    var movementManager: CMMotionManager!
    var accelerometerData: CMAccelerometerData!
    var gyroData: CMGyroData!
    
    var alarmTimer: NSTimer!
    var countDown = 10
    
    var notificationTimer: NSTimer!
    var notifyTo = UINT16_MAX
    
    var isArmed = false
    var canCancel = false
    
    var passCode: NSString!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func updateCountDown() {
        
        if(countDown > 0)
        {
            alarmCountDownLabel.text = String(countDown--)
        }
        else if (countDown == 0){
            canCancel = false
            isArmed = true
            numberPad.text = ""
            alarmCountDownLabel.hidden = true
            
            // Change text of alarm button
            alarmButton.hidden = true
            alarmButton.setTitle("Unarm", forState: UIControlState.Normal)
            statusLabel.text = "ARMED"
            statusLabel.textColor = UIColor.redColor()
            
            alarmCountDownLabel.text = String(0)
            // Stop timer
            alarmTimer.invalidate()
            
            // Start detecting motion
            movementManager = CMMotionManager()
            movementManager.accelerometerUpdateInterval = 1.0
            movementManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!) { (accelerometerData: CMAccelerometerData?, NSError) -> Void in
                
                if(NSError != nil) {
                    print("\(NSError)")
                }
                
                if (self.accelerometerData == nil){
                    // Save current motion
                    self.accelerometerData = accelerometerData
                }
                
                // Compare saved motion with current acceleration data
                if (accelerometerData! > self.accelerometerData) {
                    
                    // Begin alarm
                    print("ALARM")
                    
                    if self.notificationTimer == nil {
                        // Start notification timer and notify user every 1 second
                        self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("notifyUser"), userInfo: nil, repeats: true)
                    }
                }
            }
            
            movementManager.startGyroUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
                
                if (NSError != nil){
                    print("\(NSError)")
                }
                
                if (self.gyroData == nil) {
                    // Save current rotation
                    self.gyroData = gyroData
                }
                
                // Compare saved motion with current rotation data
                if (gyroData!.rotationRate > self.gyroData.rotationRate){
                    
                    // ALARM
                    print("ALARM")
                    
                    if self.notificationTimer == nil {
                        self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("notifyUser"), userInfo: nil, repeats: true)
                    }
                    
                }
            })
        }
        
    }
    
    func notifyUser() {
        if (notifyTo > 0) {
            --notifyTo
            
            // Keep sending push notification to all the receivers until they have seen it
            if (!self.appDelegate.hubs.notificationSeen){
                self.appDelegate.hubs.SendToEnabledPlatforms()
            }
                // Alarm notification seen, stop pushing
            else{
                notificationTimer.invalidate()
            }
            
        }
        else{
            notificationTimer.invalidate()
        }
    }
    
    @IBAction func numberPadChanged(sender: UITextField) {
        let codeFromPad = numberPad.text;
        
        if codeFromPad?.characters.count >= 4 {
            numberPad.resignFirstResponder()
            alarmButton.hidden = false
        }
        else{
            alarmButton.hidden = true
        }
    }
    
    @IBAction func AlarmButtonAction(sender: AnyObject) {
        if (isArmed) {
            print("Trying to unarm...")
            if numberPad.text == passCode {
                notificationTimer.invalidate()
                self.notificationTimer = nil
                numberPad.text = ""
                statusLabel.text = "UNARMED"
                statusLabel.textColor = UIColor.greenColor()
                isArmed = false
                canCancel = true
                alarmButton.setTitle("Arm", forState: UIControlState.Normal)
                movementManager.stopAccelerometerUpdates()
                movementManager.stopGyroUpdates()
                print("Success")
            }
            else{
                print("Fail")
            }
        }
        else if (canCancel){
            alarmTimer.invalidate()
            
            // Change text of alarm button
            alarmButton.setTitle("Arm", forState: UIControlState.Normal)
            canCancel = false
        }
        else{
            // Start count down
            // When duration is out, start detecting motion
            countDown = 10
            alarmCountDownLabel.text = String(countDown)
            alarmCountDownLabel.hidden = false
            alarmTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("updateCountDown"), userInfo: nil, repeats: true)
            
            // Change text of alarm button
            alarmButton.setTitle("Cancel", forState: UIControlState.Normal)
            
            canCancel = true
            
            // Save passcode
            passCode = numberPad.text;
        }
    }
}

func >(newCMAccelData: CMAccelerometerData, oldCMAccelData: CMAccelerometerData) -> Bool {
    return (abs(newCMAccelData.acceleration.x - oldCMAccelData.acceleration.x) > threshold) ||
        (abs(newCMAccelData.acceleration.y - oldCMAccelData.acceleration.y) > threshold) ||
        (abs(newCMAccelData.acceleration.z - oldCMAccelData.acceleration.z) > threshold)
}

func >(newCMRotData: CMRotationRate, oldCMRotData: CMRotationRate) -> Bool {
    return (abs(newCMRotData.x - oldCMRotData.x) > threshold) ||
        (abs(newCMRotData.y - oldCMRotData.y) > threshold) ||
        (abs(newCMRotData.z - oldCMRotData.z) > threshold)
}
