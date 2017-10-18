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
import CoreLocation
import LocalAuthentication
import GoogleMobileAds
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var interstitial: GADInterstitial!
    var showInterstitial: Bool!
    
    var passCode : String!
    
    var theme: SettingsTheme!{
        didSet {
            self.view.backgroundColor = theme.backgroundColor
            self.roundClockPlaceholder.backgroundColor = theme.backgroundColor
            self.hideButton.borderColor = theme.blueColor
            self.hideButton.setTitleColor(theme.blackColor, for: UIControlState())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
        
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AlarmViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter().addObserver(self, selector: #selector(setupAds), name: NSNotification.Name(rawValue: "onAdsEnabled"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        showInterstitial = false
        alarmManager.setAlarmState(.Ready)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc fileprivate func setupAds() {
        let removeAds = UserDefaults.standard.bool(forKey: "kRemoveAdsSwitchValue")
        
        if !removeAds {
            loadAdBanner()
        }
        else {
            bannerView.isHidden = true
        }
    }
    
    fileprivate func loadAdBanner() {
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        bannerView.adUnitID = kConfigAdUnitBannerId
        
        bannerView.isHidden = false
        bannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID, "9d76e2f8ed01fcade9b41f4fea72a5c7"]
        bannerView.load(request)
    }
    
    fileprivate func setupNavigationBar() {
        navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController!.navigationBar.shadowImage = UIImage()
        navigationController!.navigationBar.isTranslucent = true
        navigationController!.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "GothamPro", size: 20)!,
            NSForegroundColorAttributeName: UIColor.black
        ]
    }
    
    fileprivate func setupSlidebarMenu() {
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            // if iPad:
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.revealViewController().rearViewRevealWidth = UIScreen().bounds.size.width - 150
            }
            else {
                self.revealViewController().rearViewRevealWidth = UIScreen().bounds.size.width - 30
            }
        }
    }
    
    fileprivate func setupManagers() {
        alarmManager = AlarmManager.sharedInstance
        alarmManager.alertHandler.alarmOnDelegate = self
        alarmManager.alarmUIDelegate = self
        alarmManager.preview = previewView
        timerManager = alarmManager.timerManager
        
        alarmManager.detectorManager = DetectorManager(detectorProtocol: self)
        detectorManager = alarmManager.detectorManager
        
        alarmManager.setAlarmState(.Ready)
    }
    
    fileprivate func setupDynamic() {
        dynamicBallsUIView = DynamicFlyingBalls(frame: self.view.bounds)
        dynamicBallsUIView.associateVC(self)
        self.view.addSubview(dynamicBallsUIView)
        previewView = AVCamPreviewView(frame: dynamicBallsUIView.balls[0].frame)
    }
    
    fileprivate func startClock() {
        roundClockPlaceholder.isHidden = false
        roundClock = RoundClock(frame: roundClockPlaceholder.bounds)
        roundClock.roundClockProtocol = self
        let delayTimer = timerManager.delayTimer
        roundClock.duration = Double((delayTimer?.delayDown)!)
        roundClock.startCountDown()
        roundClockPlaceholder.addSubview(roundClock)
    }
    
    fileprivate func stopClock() {
        roundClockPlaceholder.isHidden = true
        roundClock?.removeFromSuperview()
        roundClock?.stopCountDown()
        roundClock?.displayLink.invalidate()
        roundClock = nil
    }
    
    fileprivate func setupInterstitials() {
        let removeAds = UserDefaults.standard.bool(forKey: "kRemoveAdsSwitchValue")
        
        if !removeAds {
            showInterstitial = true
            self.interstitial = createAndLoadInterstitial()
        }
    }
    
    fileprivate func setDefaults(){
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "kPhotoSwitchValue") == nil {
            userDefaults.set(true, forKey: "kPhotoSwitchValue")
        }
        
        if userDefaults.object(forKey: "kVideoSwitchValue") == nil {
            userDefaults.set(false, forKey: "kVideoSwitchValue")
        }
        
        if userDefaults.object(forKey: "kSoundSwitchValue") == nil {
            userDefaults.set(false, forKey: "kSoundSwitchValue")
        }
        
        if userDefaults.object(forKey: "kSensitivityIndex") == nil {
            userDefaults.set(1, forKey: "kSensitivityIndex")
        }
        
        userDefaults.synchronize()
    }
    
    fileprivate func setTouchHandler() {
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(AlarmViewController.handleSingleTap(_:)))
        hiddenBlackView.addGestureRecognizer(singleFingerTap)
    }
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer){
        if alarmManager.getAlarmState() == .Armed {
            hiddenBlackView.isHidden = true
            hideButton.isHidden = false
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    func intruderAlert(){
    
        if alarmManager.getAlarmState() == .Armed  {
            alarmManager.setAlarmState(.Alert)
        }

    }
    
    func setDynamicBall(_ text: String, color: UIColor, userinteractable: Bool){
        let balls = dynamicBallsUIView.balls as! [UIButton]
        
        for ball in balls {
            ball.setTitle(text, for: UIControlState())
            ball.backgroundColor = color
            ball.isUserInteractionEnabled = userinteractable
        }
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: kConfigAdUnitInterstitialsId)
        
        interstitial.delegate = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID, "9d76e2f8ed01fcade9b41f4fea72a5c7"]
        interstitial.load(request)
        return interstitial
    }
    
    fileprivate func showInterstitials() {
        if self.interstitial != nil && self.interstitial.isReady {
            if showInterstitial == true {
                print("***INTERSTITIAL SHOWING***")
                self.interstitial.present(fromRootViewController: self)
                showInterstitial = false
            }
        }
    }
    
    fileprivate func numberPadChanged() {
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
                //setDynamicBall("GOTYAH", color: SettingsTheme.theme01.arm, userinteractable: false)
            }
            else{
                setDynamicBall("Ready", color: SettingsTheme.theme01.ready, userinteractable: false)
            }
        }
    }
    
    @IBAction func numberPadChanged(_ sender: UITextField) {
        numberPadChanged()
    }
    
    @IBAction func AlarmButtonAction(_ sender: UIButton) {
        
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
    
    @IBAction func TouchIDButtonAction(_ sender: AnyObject) {
        
        // Touch ID available
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil){
            
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Unarming with Touch ID",
                                   reply: { (success: Bool, error: NSError?) -> Void in
                                    
                                    DispatchQueue.main.async(execute: {
                                        if success {
                                            // Show "the passcode" for a short time
                                            UIView.transition(with: self.numberPad, duration: 1.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                                                self.numberPad.text = self.passCode
                                                }, completion: { (success:Bool) -> Void in
                                                    self.alarmManager.setAlarmState(.Ready)
                                            })
                                        }
                                        
                                        if error != nil {
                                            var message : NSString
                                            var showAlert : Bool
                                            
                                            switch(error!.code) {
                                            case LAError.Code.authenticationFailed.rawValue:
                                                message = "There was a problem verifying your identity."
                                                showAlert = true
                                                break;
                                            case LAError.Code.userCancel.rawValue:
                                                message = "You pressed cancel."
                                                showAlert = true
                                                break;
                                            case LAError.Code.userFallback.rawValue:
                                                message = "You pressed password."
                                                showAlert = true
                                                break;
                                            default:
                                                showAlert = true
                                                message = "Touch ID may not be configured"
                                                break;
                                            }
                                            
                                            let alertView = UIAlertController(title: "Error",
                                                message: message as String, preferredStyle:.alert)
                                            let okAction = UIAlertAction(title: "Darn!", style: .default, handler: nil)
                                            alertView.addAction(okAction)
                                            if showAlert {
                                                self.present(alertView, animated: true, completion: nil)
                                            }
                                        }
                                    })
            } as! (Bool, Error?) -> Void)
        }
            // Touch ID not available
        else {
            let alertView = UIAlertController(title: "Error",
                                              message: "Touch ID not available" as String, preferredStyle:.alert)
            let okAction = UIAlertAction(title: "Darn!", style: .default, handler: nil)
            alertView.addAction(okAction)
            self.present(alertView, animated: true, completion: nil)
        }
    }
    
    @IBAction
    func hideButtonAction(_ sender: MonitorButton) {
        sender.animateTouchUpInside { () -> Void in
            self.hiddenBlackView.isHidden = false
            self.hideButton.isHidden = true
        }
    }
}

extension AlarmViewController : AlarmUIDelegate {
    func idle() {
        showInterstitials()
        stopClock()
 
        alarmCountDownLabel.isHidden = true
        context = nil;
        touchIDButton.isHidden = true
        numberPad.text = ""
        
        setDynamicBall("Ready", color: SettingsTheme.theme01.ready, userinteractable: false)
        
        touchIDButton.isHidden = true
        previewView.isHidden = true
        
        let appFrame = UIScreen.main.bounds
        
        UIView.animate(withDuration: 0.5, animations: {
            self.navigationController?.isNavigationBarHidden = false
            self.view.window?.frame = CGRect(x: 0, y: 0, width: appFrame.size.width, height: appFrame.size.height)
            self.hideButton.isHidden = true
        })
        
        appDelegate.hubs.notificationMessage = Constants.Notifications.IntruderMessage
    }
    
    func arming() {
        setDynamicBall("CANCEL", color: SettingsTheme.theme01.cancel, userinteractable: true)
    }
    
    func armed() {
        // Save passcode
        self.passCode = numberPad.text;
        
        let appFrame = UIScreen.main.bounds
        
        UIView.animate(withDuration: 0.5, animations: {
            self.navigationController?.isNavigationBarHidden = true
            self.view.window?.frame = CGRect(x: 0, y: 0, width: appFrame.size.width, height: appFrame.size.height)
            self.hiddenBlackView.isHidden = false;
        })
        
        setDynamicBall("ARMED", color: SettingsTheme.theme01.arm, userinteractable: false)
  
        numberPad.text = ""
        alarmCountDownLabel.text = String(0)
        alarmCountDownLabel.isHidden = true
   
        context = LAContext()
        
        // Show TouchID button if supported
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            touchIDButton.isHidden = false
        }
    }
    
    func alert() {
        startClock()
        self.hiddenBlackView.isHidden = true;
        self.hideButton.isHidden = true
    }
    
    func alerting() {
        let startCamera = UserDefaults.standard.bool(forKey: "kPhotoSwitchValue")
        let startVideo = UserDefaults.standard.bool(forKey: "kVideoSwitchValue")
        
        if startCamera || startVideo {
            previewView.isHidden = false
            let balls = dynamicBallsUIView.balls as! [UIButton]
            balls[0].addSubview(previewView)
        }
        numberPad.becomeFirstResponder()

        self.appDelegate.hubs.notificationMessage = Constants.Notifications.IntruderMessage
    }
}

extension AlarmViewController : DetectorProtol {
    func detectMotion(_ accelerometerData: CMAccelerometerData!, gyroData: CMGyroData!) {
        
        if (accelerometerData != nil && detectorManager.accelerometerData != nil){
            // Compare saved motion with current acceleration data
            if (accelerometerData! > detectorManager.accelerometerData) {
                intruderAlert()
            }
        }
        
        if (gyroData != nil && detectorManager.gyroData != nil){
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
        
        let deviceRegistered = UserDefaults.standard.bool(forKey: "kdeviceRegistered")
        
        if !deviceRegistered { return }
        
        appDelegate.hubs.sendToEnabledPlatforms()
    }
    
    func beep() {
        OperationQueue.main.addOperation({ () -> Void in
            
            let countTimer = self.timerManager.countDownTmer
            
            if (countTimer?.isRunning())! {
                self.alarmCountDownLabel.isHidden = false
                self.alarmCountDownLabel.text = String(describing: countTimer?.countDown)
            }
            else{
                self.alarmManager.setAlarmState(.Armed)
            }
        })
    }
    
    func tone() {
        OperationQueue.main.addOperation({ () -> Void in            
            let delayTimer = self.timerManager.delayTimer
            
            if (delayTimer?.isRunning())! {
                print("Alarming in \(delayTimer?.delayDown)")
            }
            else{
                self.alarmManager.setAlarmState(.Alerting)
            }
        })
    }
    
    func alarmWithNoise(){
    }
    
    func takePicture(){
        
        setDynamicBall("GOTYAH", color: SettingsTheme.theme01.arm, userinteractable: false)
        alarmManager.alertHandler.autoSnap.snapPhoto()
        numberPadChanged()
    }
    
    func recordVideo(){
        
        setDynamicBall("GOTYAH", color: SettingsTheme.theme01.arm, userinteractable: false)
        
        if (!alarmManager.alertHandler.autoSnap.isRecording()) {
            alarmManager.alertHandler.autoSnap.startRecording()
        }
        
        numberPadChanged()
    }
}

extension AlarmViewController : GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial!) {
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

func !=(newLocation: CLLocation?, oldLocation: CLLocation?) -> Bool {
    return (newLocation!.coordinate.latitude != oldLocation!.coordinate.latitude) || (newLocation!.coordinate.longitude != oldLocation!.coordinate.longitude)
}
