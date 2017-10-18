//
//  CountDownTimer.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class CountDownTimer : NSObject, TimerDelegate {
    let startValue = Int(kCountDownDelay)
    var countTimer: Foundation.Timer!
    var handler: AlertHandler!
    
    var countDown: Int {
        didSet{
            if countDown == 0 {
                stop()
            }
        }
    }
    
    override init() {
        countDown = startValue
    }
    
    func start() {
        countTimer = Foundation.Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CountDownTimer.update), userInfo: nil, repeats: true)
    }
    
    func stop(){
        countTimer?.invalidate()
        countTimer = nil
        reset()
    }
    
    func update() {
        handler.startBeep()
        countDown -= 1
    }
    
    func isRunning() -> Bool {
        return countTimer != nil
    }
    
    func reset() {
        countDown = startValue
    }
}
