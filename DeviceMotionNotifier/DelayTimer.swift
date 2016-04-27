//
//  DelayTimer.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class DelayTimer : NSObject, TimerDelegate {
    let startValue = 3
    var delayTimer: NSTimer!
    var handler: AlertHandler!
    var delayDown: Int {
        didSet {
            if delayDown == 0 {
                stop()
            }
        }
    }
    
    override init(){
        delayDown = startValue
    }
    
    func start() {
        self.delayTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(DelayTimer.update), userInfo: nil, repeats: true)
    }
    
    func stop() {
        delayTimer?.invalidate()
        delayTimer = nil
        reset()
    }
    
    func update() {
        handler.startTone()
        delayDown -= 1
    }
    
    func reset(){
        delayDown = startValue
    }
    
    func isRunning() -> Bool {
        return delayTimer != nil
    }
}
