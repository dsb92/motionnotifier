//
//  RoundClock.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 22/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

protocol RoundClockProtocol {
    func timerDidFinish()
}

class RoundClock: UIView {

    var displayLink: CADisplayLink!

    var duration: Double!
    var starttimeInSec: NSTimeInterval!
    var stoptimeInSec: NSTimeInterval!
    var timer: NSTimer!
    
    var roundClockProtocol : RoundClockProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        displayLink = CADisplayLink(target: self, selector: #selector(setNeedsDisplay))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)

        backgroundColor = UIColor.clearColor()
    }
    
    func startCountDown() {
        if timer != nil {
            timer.invalidate()
        }
      
        starttimeInSec = NSDate.timeIntervalSinceReferenceDate()
        stoptimeInSec = starttimeInSec + duration
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
    }
    
    func stopCountDown() {
        if timer != nil {
            timer.invalidate()
        }
        
        timer = nil
    }
    
    func timerFired() {
        roundClockProtocol?.timerDidFinish()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let borderRect = CGRectInset(rect, 2, 2)
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, borderRect)
        
        CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
        
        let x = borderRect.origin.x + borderRect.size.width/2
        let y = borderRect.origin.y + borderRect.size.height/2
        
        let currentTimeSpend = NSDate.timeIntervalSinceReferenceDate() - starttimeInSec
        let timeLeft = stoptimeInSec - starttimeInSec
        
        let currentFill = 2*M_PI * (currentTimeSpend / timeLeft) - M_PI_2
        CGContextMoveToPoint(context, x, y)
        CGContextAddArc(context, x, y, rect.size.width/2, CGFloat(-M_PI_2), CGFloat(currentFill), 1)
        CGContextFillPath(context)
    }
}
