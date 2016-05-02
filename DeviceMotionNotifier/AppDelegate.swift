//
//  AppDelegate.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var viewController: APPViewController!
    
    var hubs : Hubs!
    var mpcManager: MPCManager!
    static var userInteracted: Bool!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        hubs = Hubs()
        
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            print(error)
        }
        
        IAPManager.sharedInstance.startIAPCheck()
        
        mpcManager = MPCManager()
        
        let hasLaunchedBefore = NSUserDefaults.standardUserDefaults().boolForKey("kFirstTimeLaunch")
        
        if !hasLaunchedBefore {
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            self.viewController = APPViewController(nibName: "APPViewController", bundle: nil);
            self.window?.rootViewController = self.viewController
            self.window?.makeKeyAndVisible()
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "kFirstTimeLaunch")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        AppDelegate.userInteracted = false;
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        hubs.deviceToken = deviceToken;
        
        print("Device token: \(deviceToken)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // The message received
        let message = (userInfo as NSDictionary).objectForKey("aps")!.valueForKey("alert") as! String
        
        // Seperate the message into sender and what message
        let fullMessage = message.componentsSeparatedByString(":")
        let firstComponent = fullMessage[0]
        let secondComponent = fullMessage[1]
        
        // Get sender user name (Device with the alarm)
        let senderUserName = firstComponent.stringByReplacingOccurrencesOfString("From ", withString: "")
        
        // Get the alert message
        let alertMessage = secondComponent.stringByReplacingOccurrencesOfString(" ", withString: "") // Remove empty spaces
        
        let vc = UIWindow.getVisibleViewControllerFrom(window!.rootViewController)
        
        print("Remote Notification received: " + message)

        switch alertMessage {
        case "__ARM__":
            
            break
            
        case "__DISARM__":
            
            AlarmManager.sharedInstance.setAlarmState(.Ready)
            
            self.hubs.recipientName = senderUserName
            self.hubs.notificationMessage = "__DISARMED__"
            self.hubs.SendToEnabledPlatforms()
            
            break
            
        case "__ARMED__":
            
            break
            
        case "__DISARMED__":

            if !AppDelegate.userInteracted {
                
                AppDelegate.userInteracted = true
                
                let alertVC = UIAlertController(title: "ALARM", message: "Alarm has been remotely disarmed", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
                    
                    AppDelegate.userInteracted = false
                }

                alertVC.addAction(okAction)
                vc!.presentViewController(alertVC, animated: true, completion: nil)
            }
            
            break
 
        default:
            if !AppDelegate.userInteracted {
                
                AppDelegate.userInteracted = true
                
                let alertVC = UIAlertController(title: "ALARM", message: message, preferredStyle: .Alert)
                let remoteAction = UIAlertAction(title: "REMOTE DISARM ALARM", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
                    
                    // Disarm alarm
                    // Send push message back to sender(Device with the alarm)
                    self.hubs.recipientName = senderUserName
                    self.hubs.notificationMessage = "__DISARM__"
                    self.hubs.SendToEnabledPlatforms()
                    
                    AppDelegate.userInteracted = false
                }
                
                let okAction = UIAlertAction(title: "OK...", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
                    
                    AppDelegate.userInteracted = false
                    
                }
                
                alertVC.addAction(remoteAction)
                alertVC.addAction(okAction)
                vc!.presentViewController(alertVC, animated: true, completion: nil)
            }
            
            break
        }
    }
    
    class func simpleMessage(title title:String, message:String, image: UIImage?, uiViewController:UIViewController) {
        
        // The Custom iOS Alert
        
        let alertView = JSSAlertView().show(uiViewController, title: title, text: message, buttonTexts: ["OK"], color: UIColor.blackColor().colorWithAlphaComponent(0.7), iconImage: image)
        
        alertView.addAction({
            
            
            
        })
        
        alertView.setTitleFont("ClearSans-Bold")
        alertView.setTextFont("ClearSans")
        alertView.setButtonFont("ClearSans-Light")
        alertView.setTextTheme(.Golden)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

