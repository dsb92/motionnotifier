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
    weak var previewView: AVCamPreviewView!
    
    @IBOutlet
    weak var hiddenBlackView: UIView!
    
    @IBOutlet
    weak var bannerView: GADBannerView!
    
    @IBOutlet
    weak var roundClockPlaceholder: UIView!
    
    var dynamicBallsUIView: DynamicFlyingBalls!
    var roundClock: RoundClock!
    
    var alarmManager: AlarmManager!
    var detectorManager: DetectorManager!
    var timerManager: TimerManager!
    
    var context: LAContext!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var interstitial: GADInterstitial!
    
    var passCode : String!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
            self.roundClockPlaceholder.backgroundColor = theme.backgroundColor
            self.hideButton.borderColor = theme.primaryColor
            self.hideButton.setTitleColor(theme.secondaryColor, forState: UIControlState.Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupDynamic()
        setupSlidebarMenu()
        setupAds()
        setupInterstitials()
        setDefaults()
        setOtherStuff()
        
        setupManagers()

        theme = SettingsTheme.theme01
        self.numberPad.becomeFirstResponder()
        
        NSNotificationCenter().addObserver(self, selector: #selector(setupAds), name: "onAdsEnabled", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        alarmManager.setAlarmState(.Ready)
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
        
        // Test
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        // Live
        //bannerView.adUnitID = "ca-app-pub-2595377837159656/1504782129"
        
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
            menuButton.action = "revealToggle:"
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
        timerManager = alarmManager.timerManager
        
        alarmManager.assoicateVC(self)
        detectorManager = alarmManager.detectorManager
        
        alarmManager.initializeAlarm()
        alarmManager.setAlarmState(.Ready)
    }
    
    private func setupDynamic() {
        dynamicBallsUIView = DynamicFlyingBalls(frame: self.view.bounds)
        dynamicBallsUIView.associateVC(self)
        self.view.addSubview(dynamicBallsUIView)
        
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
        roundClock?.stopCountDown()
        roundClock?.displayLink.invalidate()
        roundClock = nil
    }
    
    private func setupInterstitials() {
        let removeAds = NSUserDefaults.standardUserDefaults().boolForKey("kRemoveAdsSwitchValue")
        
        if !removeAds {
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
    
    private func setOtherStuff() {
        let singleFingerTap = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
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
            alarmManager.setAlarmState(.Alarming)
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
        
        // Test
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        
        // Live
        //let interstitial = GADInterstitial(adUnitID: "ca-app-pub-2595377837159656/4903743727")
        
        interstitial.delegate = self
        interstitial.loadRequest(GADRequest())
        return interstitial
    }
    
    private func showInterstitials() {
        if self.interstitial != nil && self.interstitial.isReady {
            print("***INTERSTITIAL SHOWING***")
            self.interstitial.presentFromRootViewController(self)
        }
    }
    
    @IBAction func numberPadChanged(sender: UITextField) {
        let codeFromPad = numberPad.text;
        
        // How many digits should the code have?
        let digits = 8
        
        if codeFromPad?.characters.count >= digits {
            numberPad.resignFirstResponder()
            
            if alarmManager.getAlarmState() == .Armed ||  alarmManager.getAlarmState() == .Alarming ||  alarmManager.getAlarmState() == .Alarm {
                setDynamicBall("DISARM", color: UIColor.greenColor(), userinteractable: true)
            }
            else{
                setDynamicBall("ARM", color: UIColor.redColor(), userinteractable: true)
            }
        }
        else{
            if alarmManager.getAlarmState() == .Armed {
                setDynamicBall("ARMED", color: UIColor.redColor(), userinteractable: false)
            }
            else{
                setDynamicBall("Ready", color: UIColor.greenColor(), userinteractable: false)
            }
        }
    }
    
    @IBAction func AlarmButtonAction(sender: UIButton) {
        
        // ARMED
        if alarmManager.getAlarmState() == .Armed ||  alarmManager.getAlarmState() == .Alarming ||  alarmManager.getAlarmState() == .Alarm {
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
        
        setDynamicBall("Ready", color: UIColor.greenColor(), userinteractable: false)
        
        touchIDButton.hidden = true
        previewView.hidden = true
        
        let appFrame = UIScreen.mainScreen().bounds
        
        UIView.animateWithDuration(0.5, animations: {
            self.navigationController?.navigationBarHidden = false
            self.view.window?.frame = CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)
            self.hideButton.hidden = true
        })
        
        appDelegate.hubs.remoteDisarmAlarm = false
        appDelegate.hubs.notificationSeen = false
        appDelegate.hubs.notificationMessage = "Intruder alert!";
    }
    
    func arming() {
        setDynamicBall("CANCEL", color: UIColor.lightGrayColor(), userinteractable: true)
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
        
        setDynamicBall("ARMED", color: UIColor.redColor(), userinteractable: false)
  
        numberPad.text = ""
        alarmCountDownLabel.text = String(0)
        alarmCountDownLabel.hidden = true
   
        context = LAContext()
        
        // Show TouchID button if supported
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDButton.hidden = false
        }
    }
    
    func alarming() {
        startClock()
        self.hiddenBlackView.hidden = true;
    }
    
    func alarm() {
        previewView.hidden = false
        numberPad.becomeFirstResponder()
        
        self.appDelegate.hubs.notificationSeen = false
        self.appDelegate.hubs.remoteDisarmAlarm = false
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
                self.alarmManager.setAlarmState(.Alarm)
            }
        })
    }
    
    func alarmWithNoise(){
    }
    
    func takePicture(){
        
        alarmManager.armedHandler.autoSnap.snapPhoto()
    }
    
    func recordVideo(){
        
        if (!alarmManager.armedHandler.autoSnap.isRecording()) {
            alarmManager.armedHandler.autoSnap.startRecording()
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
