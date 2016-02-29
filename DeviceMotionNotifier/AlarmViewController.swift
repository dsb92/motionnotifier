//
//  AlarmViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 25/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import CoreMotion

class AlarmViewController: UIViewController {
    
    @IBOutlet weak var alarmCountDownLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    @IBOutlet weak var numberPad: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    var detectorManager: DetectorManager!
    var alarmManager: AlarmManager!
    
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

        detectorManager = DetectorManager(detectorProtocol: self)
        alarmManager = AlarmManager(alarmProtocol: self)
        
        self.numberPad.becomeFirstResponder()
    }
    
    func updateCountDown() {
        
        if(countDown > 0)
        {
            alarmCountDownLabel.text = String(countDown--)
        }
        // Time out, start arming
        else if (countDown == 0){
        
            arming()
        }
        
    }
    
    func arming() {
        canCancel = false
        isArmed = true
        numberPad.text = ""
        alarmCountDownLabel.text = String(0)
        alarmCountDownLabel.hidden = true
        
        // Change text of alarm button
        alarmButton.hidden = true
        alarmButton.setTitle("Disarm", forState: UIControlState.Normal)
        
        // Let the user know it's armed
        statusLabel.text = "ARMED"
        statusLabel.textColor = UIColor.redColor()
        
        // Stop timer
        alarmTimer.invalidate()
        
        // Start detecting motion
        detectorManager.startDetectingMotion()
        
        // Start detecting noise
        detectorManager.startDetectingNoise()
    }
    
    func startAlarm() {
        if (notifyTo > 0) {
            --notifyTo
            
            // Keep sending push notification to all the receivers until they have seen it
            if (!self.appDelegate.hubs.notificationSeen){
                alarmManager.startNotifyingRecipient()
            }
            // Alarm notification seen, stop pushing
            else{
                notificationTimer.invalidate()
            }
            
            numberPad.becomeFirstResponder()
            alarmManager.startMakingNoise()
            
        }
        else{
            notificationTimer.invalidate()
        }
    }
    
    func didUnarm(didArm: Bool){
        if didArm {
            notificationTimer.invalidate()
            self.notificationTimer = nil
            numberPad.text = ""
            statusLabel.text = "DISARMED"
            statusLabel.textColor = UIColor.greenColor()
            isArmed = false
            canCancel = false
            alarmButton.hidden = true
            alarmButton.setTitle("Arm", forState: UIControlState.Normal)
            detectorManager.stopDetectingMotions()
            detectorManager.stopDetectingNoise()
            alarmManager.stopMakingNoise()
            print("Success")
        }
        else{
            print("Fail")
        }
    }
    
    func intruderAlert(){
        // If any of the detecting features detects disturbance(noise or motions) it stars the alarm.
        if self.notificationTimer == nil {
            self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("startAlarm"), userInfo: nil, repeats: true)
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
                didUnarm(true)
            }
            else{
                didUnarm(false)
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
            // When duration is out, start alarming
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

extension AlarmViewController : DetectorProtol {
    func detectMotion(accelerometerData: CMAccelerometerData!, gyroData: CMGyroData!) {
        
        if (accelerometerData != nil){
            // Compare saved motion with current acceleration data
            if (accelerometerData! > detectorManager.accelerometerData) {
                intruderAlert()
            }
        }
        
        if (gyroData != nil){
            // Compare saved motion with current rotation data
            if (gyroData!.rotationRate > detectorManager.gyroData.rotationRate){
                intruderAlert()
            }
        }
    }
    
    func detectNoise() {
        intruderAlert()
    }
}

extension AlarmViewController : AlarmProtocol {
    func notifyRecipient(){
        self.appDelegate.hubs.SendToEnabledPlatforms()
    }
    
    func alarmWithNoise(){
    }
    
    func takePicture(){
        
    }
    
    func recordVideo(){
        
    }
    
    func saveToCloud(){
        
    }
}

func >(newCMAccelData: CMAccelerometerData, oldCMAccelData: CMAccelerometerData) -> Bool {
    return (abs(newCMAccelData.acceleration.x - oldCMAccelData.acceleration.x) > motionThreshold) ||
        (abs(newCMAccelData.acceleration.y - oldCMAccelData.acceleration.y) > motionThreshold) ||
        (abs(newCMAccelData.acceleration.z - oldCMAccelData.acceleration.z) > motionThreshold)
}

func >(newCMRotData: CMRotationRate, oldCMRotData: CMRotationRate) -> Bool {
    return (abs(newCMRotData.x - oldCMRotData.x) > motionThreshold) ||
        (abs(newCMRotData.y - oldCMRotData.y) > motionThreshold) ||
        (abs(newCMRotData.z - oldCMRotData.z) > motionThreshold)
}
