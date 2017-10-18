//
//  AppDelegate.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import AVFoundation
import Fabric
import Crashlytics
import CoreLocation
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var viewController: APPViewController!
    
    var hubs : Hubs!
    var mpcManager: MPCManager!
    var userInteracted: Bool!
    
    enum AlertMessage : String {
        case ARM = "__ARM__"
        case DISARM = "__DISARM__"
        case ARMED = "__ARMED__"
        case DISARMED = "__DISARMED__"
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setFabric()
        setApplicationRegistrations()
        
        initializeNotificationHub()
        initializeAudio()
        initializeMPCManager()
        startIAPCheck()

        setFirstTimeLaunch()
        
        userInteracted = false;

        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: kConfigAdAppId)
        
        return true
    }
    
    fileprivate func setFabric() {
        Fabric.with([Crashlytics.self])
    }
    
    fileprivate func setApplicationRegistrations() {
        let settings = UIUserNotificationSettings(types: [UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    fileprivate func initializeNotificationHub() {
        hubs = Hubs()
    }
    
    fileprivate func initializeAudio() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print(error)
        }
    }
    
    fileprivate func initializeMPCManager() {
        mpcManager = MPCManager()
    }
    
    fileprivate func startIAPCheck() {
        IAPManager.sharedInstance.startIAPCheck()
    }
    
    fileprivate func setFirstTimeLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "kFirstTimeLaunch")
        
        if !hasLaunchedBefore {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.viewController = APPViewController(nibName: "APPViewController", bundle: nil);
            self.window?.rootViewController = self.viewController
            self.window?.makeKeyAndVisible()
            
            UserDefaults.standard.set(true, forKey: "kFirstTimeLaunch")
            UserDefaults.standard.synchronize()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        hubs.deviceToken = deviceToken;
        
        print("Device token: \(deviceToken)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If the message has to do with alarm alerting
        if let message = ((userInfo as NSDictionary).object(forKey: "aps")! as AnyObject).value(forKey: "alert"){
            handleAlert(message as! String)
        }
        
    }
    
    func handleAlert(_ message: String){
        // Seperate the message into sender and what message
        let fullMessage = message.components(separatedBy: ":")
        let firstComponent = fullMessage[0]
        let secondComponent = fullMessage[1]
        
        // Get sender user name (Device with the alarm)
        let senderUserName = firstComponent.replacingOccurrences(of: "From ", with: "")
        
        // Get the alert message, remove empty spaces
        let alertMessage = secondComponent.replacingOccurrences(of: " ", with: "")
        
        let vc = UIWindow.getVisibleViewControllerFrom(window!.rootViewController)
        
        // e.g. Davids-iPhone with Davids iPhone
        let msg = message.replacingOccurrences(of: "-", with: " ")
        
        print("Remote Notification received: " + message)
        
        switch alertMessage {
        case AlertMessage.ARM.rawValue:
            
            break
            
        case AlertMessage.DISARM.rawValue:
            
            AlarmManager.sharedInstance.setAlarmState(.Ready)
            
            self.hubs.recipientName = senderUserName
            self.hubs.notificationMessage = AlertMessage.DISARMED.rawValue
            self.hubs.sendToEnabledPlatforms()
            
            break
            
        case AlertMessage.ARMED.rawValue:
            
            break
            
        case AlertMessage.DISARMED.rawValue:
            
            if !userInteracted {
                
                IJProgressView.shared.hideProgressView()
                
                userInteracted = true
                // *Remote disarm set, waitForRemoteAlarm finished...
                self.hubs.remoteDisarmAlarm = false

                let alertView = JSSAlertView().success(vc!, title: "Alarm has been remotely disarmed!")
                
                alertView.setTitleFont("ClearSans-Bold")
                alertView.setTextFont("ClearSans")
                alertView.setButtonFont("ClearSans-Light")
                alertView.setTextTheme(.golden)
                
                alertView.addAction({
                    self.userInteracted = false
                })
            }
            
            break
         // Intruder alert!
        default:
            if !userInteracted && !self.hubs.remoteDisarmAlarm {
                
                userInteracted = true
                
                let buttonTexts = ["Remote disarm alarm", "OK..."]
                let alertView = JSSAlertView().show(vc!, title: "Alarm!", text: msg, buttonTexts: buttonTexts, color: SettingsTheme.theme01.blueColor.withAlphaComponent(0.7), iconImage: UIImage(named: "alert-icon"))
                
                alertView.setTitleFont("ClearSans-Bold")
                alertView.setTextFont("ClearSans")
                alertView.setButtonFont("ClearSans-Light")
                alertView.setTextTheme(.golden)
                
                alertView.addAction({
                    if alertView.getButtonId() == 1{
                        // Disarm alarm
                        // Send push message back to sender(Device with the alarm)
                        self.hubs.recipientName = senderUserName
                        self.hubs.notificationMessage = AlertMessage.DISARM.rawValue
                        self.hubs.sendToEnabledPlatforms()
                        
                        self.userInteracted = false
                        self.hubs.remoteDisarmAlarm = true
                        
                        // *Wait until message has been received on other device or try again
                        
                        let waitForRemoteDisarm = DispatchQueue(label: "waitForRemoteAlarm", attributes: [])
                        let waitingTime = 5
                        var counter = 0
                        
                        IJProgressView.shared.showProgressView(vc!.view)
                        waitForRemoteDisarm.async(execute: {
                            while self.hubs.remoteDisarmAlarm == true && counter != waitingTime {
                                print("Waiting for remote alarm to be disarmed")
                                
                                sleep(1)
                                counter += 1
                            }
                            
                            
                            DispatchQueue.main.async{
                                // Wait 5 seconds...and if still true try again
                                if self.hubs.remoteDisarmAlarm == true {
                                    self.hubs.remoteDisarmAlarm = false
                                    IJProgressView.shared.hideProgressView()
                                }
                            }
                        })
                    }
                    else{
                        self.userInteracted = false
                    }
                })

            }
            
            break
        }
    }
    
    class func simpleMessage(title:String, message:String, image: UIImage?, uiViewController:UIViewController) {
        
        // The Custom iOS Alert
        
        let alertView = JSSAlertView().show(uiViewController, title: title, text: message, buttonTexts: ["OK"], color: SettingsTheme.theme01.blueColor.withAlphaComponent(0.7), iconImage: image)
        
        alertView.addAction({
            
            
            
        })
        
        alertView.setTitleFont("ClearSans-Bold")
        alertView.setTextFont("ClearSans")
        alertView.setButtonFont("ClearSans-Light")
        alertView.setTextTheme(.golden)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

