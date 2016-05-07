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
import GoogleMobileAds

protocol SystemProtocol {
    func idle()
    func armed()
}

class AlarmViewController: UIViewController {
    
    @IBOutlet
    weak var menuButton: UIBarButtonItem!
    
    @IBOutlet
    weak var hideButton: MonitorButton!
    
    @IBOutlet
    weak var alarmCountDownLabel: UILabel!
    
    @IBOutlet
    weak var numberPad: UITextField!
    
    @IBOutlet
    weak var touchIDButton: UIButton!
    
    @IBOutlet
    weak var hiddenBlackView: UIView!
    
    @IBOutlet
    weak var bannerView: GADBannerView!
    
    @IBOutlet
    weak var roundClockPlaceholder: UIView!
    
    var previewView: AVCamPreviewView!
    
    var dynamicBallsUIView: DynamicFlyingBalls!
    var roundClock: RoundClock!
    
    var alarmManager: AlarmManager!
    var detectorManager: DetectorManager!
    var timerManager: TimerManager!
    
    var context: LAContext!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var interstitial: GADInterstitial!
    var showInterstitial: Bool!
    
    var passCode : String!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
            self.roundClockPlaceholder.backgroundColor = theme.backgroundColor
            self.hideButton.borderColor = theme.blueColor
            self.hideButton.setTitleColor(theme.blackColor, forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Preinitilization before setting up managers
        setupNavigationBar()
        setupDynamic()
        setupSlidebarMenu()
        setupAds()
        setupInterstitials()
        setDefaults()
        setTouchHandler()
        
        setupManagers()

        theme = SettingsTheme.theme01
        self.numberPad.becomeFirstResponder()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        NSNotificationCenter().addObserver(self, selector: #selector(setupAds), name: "onAdsEnabled", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        showInterstitial = false
        alarmManager.setAlarmState(.Ready)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func setupAds() {
        let removeAds = NSUserDefaults.standardUserDefaults().boolForKey("kRemoveAdsSwitchValue")
        
        if !removeAds {
            loadAdBanner()
        }
        else {
            bannerView.hidden = true
        }
    }
    
    private func loadAdBanner() {
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        bannerView.adUnitID = kConfigAdUnitBannerId
        
        bannerView.hidden = false
        bannerView.rootViewController = self
        bannerView.loadRequest(GADRequest())
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
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            // if iPad:
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                self.revealViewController().rearViewRevealWidth = UIScreen().bounds.size.width - 150
            }
            else {
                self.revealViewController().rearViewRevealWidth = UIScreen().bounds.size.width - 30
            }
        }
    }
    
    private func setupManagers() {
        alarmManager = AlarmManager.sharedInstance
        alarmManager.alertHandler.alarmOnDelegate = self
        alarmManager.alarmUIDelegate = self
        alarmManager.preview = previewView
        timerManager = alarmManager.timerManager
        
        alarmManager.detectorManager = DetectorManager(detectorProtocol: self)
        detectorManager = alarmManager.detectorManager
        
        alarmManager.setAlarmState(.Ready)
    }
    
    private func setupDynamic() {
        dynamicBallsUIView = DynamicFlyingBalls(frame: self.view.bounds)
        dynamicBallsUIView.associateVC(self)
        self.view.addSubview(dynamicBallsUIView)
        previewView = AVCamPreviewView(frame: dynamicBallsUIView.balls[0].frame)
    }
    
    private func startClock() {
        roundClockPlaceholder.hidden = false
        roundClock = RoundClock(frame: roundClockPlaceholder.bounds)
        roundClock.roundClockProtocol = self
        let delayTimer = timerManager.delayTimer
        roundClock.duration = Double(delayTimer.delayDown)
        roundClock.startCountDown()
        roundClockPlaceholder.addSubview(roundClock)
    }
    
    private func stopClock() {
        roundClockPlaceholder.hidden = true
        roundClock?.removeFromSuperview()
        roundClock?.stopCountDown()
        roundClock?.displayLink.invalidate()
        roundClock = nil
    }
    
    private func setupInterstitials() {
        let removeAds = NSUserDefaults.standardUserDefaults().boolForKey("kRemoveAdsSwitchValue")
        
        if !removeAds {
            showInterstitial = true
            self.interstitial = createAndLoadInterstitial()
        }
    }
    
    private func setDefaults(){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("kPhotoSwitchValue") == nil {
            userDefaults.setObject(true, forKey: "kPhotoSwitchValue")
        }
        
        if userDefaults.objectForKey("kVideoSwitchValue") == nil {
            userDefaults.setObject(false, forKey: "kVideoSwitchValue")
        }
        
        if userDefaults.objectForKey("kSoundSwitchValue") == nil {
            userDefaults.setObject(false, forKey: "kSoundSwitchValue")
        }
        
        if userDefaults.objectForKey("kSensitivityIndex") == nil {
            userDefaults.setObject(1, forKey: "kSensitivityIndex")
        }
        
        userDefaults.synchronize()
    }
    
    private func setTouchHandler() {
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(AlarmViewController.handleSingleTap(_:)))
        hiddenBlackView.addGestureRecognizer(singleFingerTap)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer){
        if alarmManager.getAlarmState() == .Armed {
            hiddenBlackView.hidden = true
            hideButton.hidden = false
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    func intruderAlert(){
    
        if alarmManager.getAlarmState() == .Armed  {
            alarmManager.setAlarmState(.Alert)
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
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: kConfigAdUnitInterstitialsId)
        
        interstitial.delegate = self
        interstitial.loadRequest(GADRequest())
        return interstitial
    }
    
    private func showInterstitials() {
        if self.interstitial != nil && self.interstitial.isReady {
            if showInterstitial == true {
                print("***INTERSTITIAL SHOWING***")
                self.interstitial.presentFromRootViewController(self)
                showInterstitial = false
            }
        }
    }
    
    @IBAction func numberPadChanged(sender: UITextField) {
        let codeFromPad = numberPad.text;
        
        // How many digits should the code have?
        let digits = 6
        
        if codeFromPad?.characters.count >= digits {
            numberPad.resignFirstResponder()
            
            if alarmManager.getAlarmState() == .Armed ||  alarmManager.getAlarmState() == .Alert ||  alarmManager.getAlarmState() == .Alerting {
                previewView.removeFromSuperview()
                setDynamicBall("DISARM", color: SettingsTheme.theme01.disarm, userinteractable: true)
            }
            else{
                setDynamicBall("ARM", color: SettingsTheme.theme01.arm, userinteractable: true)
            }
        }
        else{
            if alarmManager.getAlarmState() == .Armed ||  alarmManager.getAlarmState() == .Alert ||  alarmManager.getAlarmState() == .Alerting  {
                let ball = dynamicBallsUIView.balls[0]
                ball.addSubview(previewView)
                //setDynamicBall("ARMED", color: SettingsTheme.theme01.arm, userinteractable: false)
            }
            else{
                setDynamicBall("Ready", color: SettingsTheme.theme01.ready, userinteractable: false)
            }
        }
    }
    
    @IBAction func AlarmButtonAction(sender: UIButton) {
        
        // ARMED
        if alarmManager.getAlarmState() == .Armed ||  alarmManager.getAlarmState() == .Alert ||  alarmManager.getAlarmState() == .Alerting {
            if self.numberPad.text == self.passCode {
                alarmManager.setAlarmState(.Ready)
            }
        }
        
        // ARMING
        else if alarmManager.getAlarmState() == .Arming{
            alarmManager.setAlarmState(.Ready)
        }
        
        // READY
        else{
            alarmManager.setAlarmState(.Arming)
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
                                                    self.alarmManager.setAlarmState(.Ready)
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
        }
    }
    
    @IBAction
    func hideButtonAction(sender: MonitorButton) {
        sender.animateTouchUpInside { () -> Void in
            self.hiddenBlackView.hidden = false
            self.hideButton.hidden = true
        }
    }
}

extension AlarmViewController : AlarmUIDelegate {
    func idle() {
        showInterstitials()
        stopClock()
 
        alarmCountDownLabel.hidden = true
        context = nil;
        touchIDButton.hidden = true
        numberPad.text = ""
        
        setDynamicBall("Ready", color: SettingsTheme.theme01.ready, userinteractable: false)
        
        touchIDButton.hidden = true
        previewView.hidden = true
        
        let appFrame = UIScreen.mainScreen().bounds
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.navigationBarHidden = false
            self.view.window?.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)
            self.hideButton.hidden = true
        })
        
        appDelegate.hubs.notificationMessage = "Intruder alert!";
    }
    
    func arming() {
        setDynamicBall("CANCEL", color: SettingsTheme.theme01.cancel, userinteractable: true)
    }
    
    func armed() {
        // Save passcode
        self.passCode = numberPad.text;
        
        let appFrame = UIScreen.mainScreen().bounds
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.navigationBarHidden = true
            self.view.window?.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)
            self.hiddenBlackView.hidden = false;
        })
        
        setDynamicBall("ARMED", color: SettingsTheme.theme01.arm, userinteractable: false)
  
        numberPad.text = ""
        alarmCountDownLabel.text = String(0)
        alarmCountDownLabel.hidden = true
   
        context = LAContext()
        
        // Show TouchID button if supported
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDButton.hidden = false
        }
    }
    
    func alert() {
        startClock()
        self.hiddenBlackView.hidden = true;
        self.hideButton.hidden = true
    }
    
    func alerting() {
        let startCamera = NSUserDefaults.standardUserDefaults().boolForKey("kPhotoSwitchValue")
        let startVideo = NSUserDefaults.standardUserDefaults().boolForKey("kVideoSwitchValue")
        
        if startCamera || startVideo {
            previewView.hidden = false
            let balls = dynamicBallsUIView.balls as! [UIButton]
            balls[0].addSubview(previewView)
        }
        numberPad.becomeFirstResponder()

        self.appDelegate.hubs.notificationMessage = "Intruder alert!";
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

extension AlarmViewController : AlarmOnDelegate {
    func notifyRecipient(){
        
        let deviceRegistered = NSUserDefaults.standardUserDefaults().boolForKey("kdeviceRegistered")
        
        if !deviceRegistered { return }
        
        appDelegate.hubs.SendToEnabledPlatforms()
    }
    
    func beep() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            
            let countTimer = self.timerManager.countDownTmer
            
            if countTimer.isRunning() {
                self.alarmCountDownLabel.hidden = false
                self.alarmCountDownLabel.text = String(countTimer.countDown)
            }
            else{
                self.alarmManager.setAlarmState(.Armed)
            }
        })
    }
    
    func tone() {
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in            
            let delayTimer = self.timerManager.delayTimer
            
            if delayTimer.isRunning() {
                print("Alarming in \(delayTimer.delayDown)")
            }
            else{
                self.alarmManager.setAlarmState(.Alerting)
            }
        })
    }
    
    func alarmWithNoise(){
    }
    
    func takePicture(){
        
        alarmManager.alertHandler.autoSnap.snapPhoto()
    }
    
    func recordVideo(){
        
        if (!alarmManager.alertHandler.autoSnap.isRecording()) {
            alarmManager.alertHandler.autoSnap.startRecording()
        }
        
    }
}

extension AlarmViewController : GADInterstitialDelegate {
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        setupInterstitials()
    }
}

extension AlarmViewController : RoundClockProtocol {
    func timerDidFinish() {
        stopClock()
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
