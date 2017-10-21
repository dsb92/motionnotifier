//
//  TimerManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

protocol TimerDelegate {
    func start()
    func stop()
    func reset()
    func update()
    func isRunning() -> Bool
}

class TimerManager {
    
    var countDownTmer: CountDownTimer?
    var delayTimer: DelayTimer!
    var notificationTimer: NotificationTimer!
    
    init(handler: AlertHandler) {
        countDownTmer = CountDownTimer()
        delayTimer = DelayTimer()
        notificationTimer = NotificationTimer()
        
        countDownTmer?.handler = handler
        delayTimer.handler = handler
        notificationTimer.handler = handler
    }
}
