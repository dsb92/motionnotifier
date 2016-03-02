//
//  AlarmViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 25/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import LocalAuthentication

class AlarmViewController: UIViewController {
    
    @IBOutlet weak var alarmCountDownLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    @IBOutlet weak var numberPad: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var wrongPassLabel: UILabel!
    @IBOutlet weak var touchIDButton: UIButton!
    
    var detectorManager: DetectorManager!
    var alarmManager: AlarmManager!
    
    var context: LAContext!
    
    var alarmTimer: NSTimer!
    var countDown = 10
    
    var notificationTimer: NSTimer!
    var notifyTo = UINT16_MAX
    
    var isArmed = false
    var canCancel = false
    var passCode: String!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        detectorManager = DetectorManager(detectorProtocol: self)
        alarmManager = AlarmManager(alarmProtocol: self)
        
        self.numberPad.becomeFirstResponder()
        
        touchIDButton.hidden = true
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
        
        context = LAContext()
        
        // Show TouchID button if supported
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDButton.hidden = false
        }
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
            alarmManager.startFrontCamera()
            
        }
        else{
            notificationTimer.invalidate()
        }
    }
    
    func didUnarm(didArm: Bool){
        if didArm {
            if notificationTimer != nil {
                notificationTimer.invalidate()
            }
            self.notificationTimer = nil
            context = nil;
            touchIDButton.hidden = true
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
            wrongPassLabel.hidden = true
        }
        else{
            print("Fail")
            wrongPassLabel.hidden = false
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
    @IBAction func TouchIDButtonAction(sender: AnyObject) {
        
        // Touch ID available
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil){
            
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unarming with Touch ID",
                reply: { (success: Bool, error: NSError?) -> Void in
            
                    dispatch_async(dispatch_get_main_queue(), {
                        if success {
                            // Show "the passcode" for a short time
                            UIView.transitionWithView(self.numberPad, duration: 1.0, options: UIViewAnimationOptions.TransitionNone, animations: { () -> Void in
                                self.numberPad.text = self.passCode
                                }, completion: { (success:Bool) -> Void in
                                    self.didUnarm(true)
                            })
                        }
                        
                        if error != nil {
                            var message : NSString
                            var showAlert : Bool

                            switch(error!.code) {
                            case LAError.AuthenticationFailed.rawValue:
                                message = "There was a problem verifying your identity."
                                showAlert = true
                                break;
                            case LAError.UserCancel.rawValue:
                                message = "You pressed cancel."
                                showAlert = true
                                break;
                            case LAError.UserFallback.rawValue:
                                message = "You pressed password."
                                showAlert = true
                                break;
                            default:
                                showAlert = true
                                message = "Touch ID may not be configured"
                                break;
                            }
                            
                            let alertView = UIAlertController(title: "Error",
                                message: message as String, preferredStyle:.Alert)
                            let okAction = UIAlertAction(title: "Darn!", style: .Default, handler: nil)
                            alertView.addAction(okAction)
                            if showAlert {
                                self.presentViewController(alertView, animated: true, completion: nil)
                            }
                            
                            self.didUnarm(false)
                        }
                    })
                    
            })
        }
        // Touch ID not available
        else {
            let alertView = UIAlertController(title: "Error",
                message: "Touch ID not available" as String, preferredStyle:.Alert)
            let okAction = UIAlertAction(title: "Darn!", style: .Default, handler: nil)
            alertView.addAction(okAction)
            self.presentViewController(alertView, animated: true, completion: nil)
            
            self.didUnarm(false)
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
    
    func takePicture(previewLayer: AVCaptureVideoPreviewLayer, captureSession: AVCaptureSession){
        self.view.layer.addSublayer(previewLayer)
        previewLayer.frame = self.view.layer.frame
        captureSession.startRunning()
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
