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
    var starttimeInSec: TimeInterval!
    var stoptimeInSec: TimeInterval!
    var timer: Foundation.Timer!
    
    var roundClockProtocol : RoundClockProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        displayLink = CADisplayLink(target: self, selector: #selector(setNeedsDisplay(_:)))
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)

        backgroundColor = UIColor.clear
    }
    
    func startCountDown() {
        if timer != nil {
            timer.invalidate()
        }
      
        starttimeInSec = Date.timeIntervalSinceReferenceDate
        stoptimeInSec = starttimeInSec + duration
        timer = Foundation.Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
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
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let borderRect = rect.insetBy(dx: 2, dy: 2)
        let context = UIGraphicsGetCurrentContext()
        context!.clear(borderRect)
        
        context!.setFillColor(SettingsTheme.theme01.arm.cgColor)
        
        let x = borderRect.origin.x + borderRect.size.width/2
        let y = borderRect.origin.y + borderRect.size.height/2
        
        let currentTimeSpend = Date.timeIntervalSinceReferenceDate - starttimeInSec
        let timeLeft = stoptimeInSec - starttimeInSec
        
        let currentFill = 2*M_PI * (currentTimeSpend / timeLeft) - M_PI_2
        context!.move(to: CGPoint(x: x, y: y))
        context!.addArc(center: CGPoint(x: x, y: y), radius: rect.size.width/2,
                    startAngle: CGFloat(-M_PI_2), endAngle: CGFloat(currentFill), clockwise: true)
        
        context!.fillPath()
    }
}
