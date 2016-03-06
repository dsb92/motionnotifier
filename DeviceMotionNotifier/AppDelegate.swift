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
    
    var hubs : Hubs!
    
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
        
        
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        hubs.deviceToken = deviceToken;
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // The message received
        let message = (userInfo as NSDictionary).objectForKey("aps")!.valueForKey("alert") as! String
        
        // Get Sender user name (Device with the alarm)
        let beginMessage = message.componentsSeparatedByString(":")[0]
        
        let senderUserName = beginMessage.stringByReplacingOccurrencesOfString("From ", withString: "")
        
        print("Remote Notification received: %@", message)
        
        // If message has not been seen by recipient
        if (!message.containsString("MESSAGE_SEEN") ) {
            // Alarm start her
            let alertVC = UIAlertController(title: "ALARM", message: message, preferredStyle: .Alert)
            let callAction = UIAlertAction(title: "RING 112", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
                
                // Start phone call
                
                // Send push message back to sender(Device with the alarm)
                self.hubs.recipientName = senderUserName
                self.hubs.notificationMessage = "MESSAGE_SEEN"
                self.hubs.SendToEnabledPlatforms()
            }
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
                
                // Other actions
                // Send push message back to sender(Device with the alarm)
                self.hubs.recipientName = senderUserName
                self.hubs.notificationMessage = "MESSAGE_SEEN"
                self.hubs.SendToEnabledPlatforms()
            }
            
            alertVC.addAction(callAction)
            alertVC.addAction(okAction)
            
            let vc = self.window?.rootViewController
            
            vc!.presentViewController(alertVC, animated: true, completion: nil)
        }
        else{
            hubs.notificationSeen = true
        }
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

