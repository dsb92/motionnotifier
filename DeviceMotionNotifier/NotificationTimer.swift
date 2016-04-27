//
//  NotificationTimer.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class NotificationTimer: NSObject, TimerDelegate {
    let startValue = UINT16_MAX
    var notificationTimer: NSTimer!
    var handler: AlertHandler!
    var notifyTo: Int32 {
        didSet {
            if notifyTo == 0 {
                stop()
            }
        }
    }
    
    override init(){
        notifyTo = startValue
    }
    
    func start(){
        self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(NotificationTimer.update), userInfo: nil, repeats: true)
    }
    
    func stop() {
        notificationTimer?.invalidate()
        notificationTimer = nil
        reset()
    }
    
    func reset() {
        notifyTo = UINT16_MAX
    }
    
    func update() {
        notifyTo -= 1
        handler.startNotifyingRecipient()
        handler.startMakingNoise()
        
        let startCamera = NSUserDefaults.standardUserDefaults().boolForKey("kPhotoSwitchValue")
        if startCamera {
            handler.startFrontCamera()
        }
        else{
            handler.startCaptureVideo()
        }
    }
    
    func isRunning() -> Bool {
        return notificationTimer != nil
    }
}
