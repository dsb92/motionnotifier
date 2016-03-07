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
    
    @IBOutlet
    weak var menuButton: UIBarButtonItem!
    
    @IBOutlet
    weak var alarmCountDownLabel: UILabel!
    
    @IBOutlet
    weak var numberPad: UITextField!
    
    @IBOutlet
    weak var touchIDButton: UIButton!
    
    @IBOutlet
    weak var previewView: AVCamPreviewView!
    
    var detectorManager: DetectorManager!
    var alarmManager: AlarmManager!
    
    var context: LAContext!
    
    var alarmTimer: NSTimer!
    var countDown = 10
    
    var delayTimer: NSTimer!
    var delayDown = 10
    
    var notificationTimer: NSTimer!
    var notifyTo = UINT16_MAX
    
    var isArmed = false
    var canCancel = false
    var passCode: String!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var dynamicBallsUIView: DynamicFlyingBalls!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        alarmManager.autoSnap.initializeOnViewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupSlidebarMenu()
        setupManagers()
        setupDynamic()
        setDefaults()
        
        theme = SettingsTheme.theme01
        self.numberPad.becomeFirstResponder()
        
        touchIDButton.hidden = true
        previewView.hidden = true
        
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
    
    private func setupManagers() {
        detectorManager = DetectorManager(detectorProtocol: self)
        alarmManager = AlarmManager(alarmProtocol: self)
        
        alarmManager.autoSnap = AVAutoSnap(vc: self)
        alarmManager.autoSnap.initializeOnViewDidLoad()
    }
    
    private func setupDynamic() {
        dynamicBallsUIView = DynamicFlyingBalls(frame: self.view.bounds)
        dynamicBallsUIView.associateVC(self)
        self.view.addSubview(dynamicBallsUIView)

    }
    
    private func setDefaults(){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("kTimerValue") == nil {
            userDefaults.setObject(Int(10), forKey: "kTimerValue")
        }
        
        if userDefaults.objectForKey("kPhotoSwitchValue") == nil {
            userDefaults.setObject(true, forKey: "kPhotoSwitchValue")
        }
        
        if userDefaults.objectForKey("kVideoSwitchValue") == nil {
            userDefaults.setObject(false, forKey: "kVideoSwitchValue")
        }
        
        if userDefaults.objectForKey("kDelaySwitchValue") == nil {
            userDefaults.setObject(false, forKey: "kVideoSwitchValue")
        }
        
        userDefaults.synchronize()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    func updateCountDown() {
        
        if(countDown > 0)
        {
            alarmCountDownLabel.text = String(countDown--)
        }
        // Time out, start arming
        else if (countDown == 0){
        
            armed()
        }
    }
    
    func armed() {
        
        let appFrame = UIScreen.mainScreen().bounds
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.navigationBarHidden = true
            self.view.window?.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)
        })
        
        setDynamicBall("ARMED", color: UIColor.redColor(), userinteractable: false)
        
        canCancel = false
        isArmed = true
        
        numberPad.text = ""
        alarmCountDownLabel.text = String(0)
        alarmCountDownLabel.hidden = true
        
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
            
            let silent = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
            
            if !silent {
                alarmManager.startMakingNoise()
            }
            
            let startCamera = NSUserDefaults.standardUserDefaults().boolForKey("kPhotoSwitchValue")
            
            if startCamera {
                alarmManager.startFrontCamera()
            }
            else{
                alarmManager.startCaptureVideo()
            }
        }
        else{
            notificationTimer.invalidate()
        }
    }
    
    func updateDelay() {
        if(delayDown > 0)
        {
            delayDown--
            print(delayDown)
        }
            // Time out, user did not disarm the alarm in time
        else if (delayDown == 0){
            
            // Stop delay timer
            delayTimer.invalidate()
            delayTimer = nil
            
            startAlarmProcedure()
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
            
            setDynamicBall("Ready", color: UIColor.greenColor(), userinteractable: false)
            
            isArmed = false
            canCancel = false

            detectorManager.stopDetectingMotions()
            detectorManager.stopDetectingNoise()
            alarmManager.stopMakingNoise()
            alarmManager.stopCaptureVideo()
            print("Success")
            previewView.hidden = true
            
            let appFrame = UIScreen.mainScreen().bounds
            
            UIView.animateWithDuration(0.5, animations: {
                self.navigationController?.navigationBarHidden = false
                self.view.window?.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)
            })
        }
        else{
            print("Fail")
        }
    }
    
    func intruderAlert(){
        
        print("INTRUDER ALERT")
        
        let noDelay = NSUserDefaults.standardUserDefaults().boolForKey("kDelaySwitchValue")
        
        if noDelay {
            startAlarmProcedure()
        }
        else{
            
            if self.delayTimer == nil {
                self.delayTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateDelay"), userInfo: nil, repeats: true)
            }
        }
    }
    
    func setDynamicBall(text: String, color: UIColor, userinteractable: Bool){
        let balls = dynamicBallsUIView.balls as! [UIButton]
        
        for ball in balls {
            ball.setTitle(text, forState: UIControlState.Normal)
            ball.backgroundColor = color
            ball.userInteractionEnabled = userinteractable
        }
    }
    
    private func startAlarmProcedure(){
        // If any of the detecting features detects disturbance(noise or motions) it stars the alarm.
        if self.notificationTimer == nil {
            previewView.hidden = false
            numberPad.becomeFirstResponder()
            
            self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("startAlarm"), userInfo: nil, repeats: true)
        }
    }
    
    
    @IBAction func numberPadChanged(sender: UITextField) {
        let codeFromPad = numberPad.text;
        
        // How many digits should the code have?
        let digits = 8
        
        if codeFromPad?.characters.count >= digits {
            numberPad.resignFirstResponder()
            
            if self.isArmed {
                setDynamicBall("DISARM", color: UIColor.greenColor(), userinteractable: true)
            }
            else{
                setDynamicBall("ARM", color: UIColor.redColor(), userinteractable: true)
            }
        }
        else{
            if self.isArmed {
                setDynamicBall("ARMED", color: UIColor.redColor(), userinteractable: false)
            }
            else{
                setDynamicBall("Ready", color: UIColor.greenColor(), userinteractable: false)
            }
        }
    }
    
    @IBAction func AlarmButtonAction(sender: UIButton) {
        
        // ARMED
        if (self.isArmed) {
            print("Trying to unarm...")
            if self.numberPad.text == self.passCode {
                self.didUnarm(true)
            }
            else{
                self.didUnarm(false)
            }
        }
        // CANCELED
        else if (self.canCancel){
            self.alarmTimer.invalidate()
            
            setDynamicBall("ARM", color: UIColor.redColor(), userinteractable: true)
            
            self.canCancel = false
            self.alarmCountDownLabel.hidden = true
        }
        // Ready
        else{
            // Start count down
            // When duration is out, start alarming
            let timerValue = NSUserDefaults.standardUserDefaults().floatForKey("kTimerValue")
            self.countDown = Int(timerValue)
            self.alarmCountDownLabel.text = String(self.countDown)
            self.alarmCountDownLabel.hidden = false
            
            self.alarmTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateCountDown"), userInfo: nil, repeats: true)
            
            setDynamicBall("CANCEL", color: UIColor.lightGrayColor(), userinteractable: true)
            
            self.canCancel = true
            
            // Save passcode
            self.passCode = numberPad.text;
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
    
    func takePicture(){

        //alarmManager.autoSnap.snapPhoto()
    }
    
    func recordVideo(){
        
//        if (!alarmManager.autoSnap.isRecording()) {
//            alarmManager.autoSnap.startRecording()
//        }
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
