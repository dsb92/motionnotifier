//
//  DynamicFlyingBalls.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 06/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class DynamicFlyingBalls: UIView {
    
    var animator : UIDynamicAnimator!
    var balls : [UIView]!
    var vc: AlarmViewController!
    var framesSet = false
    
    override init(frame: CGRect){
        super.init(frame: frame)
        
        self.balls = [UIView]()
        
        // Initialize amount of balls
        let button = UIButton(type: UIButtonType.custom)
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 160)
        button.backgroundColor = UIColor.green
        button.titleLabel?.textColor = UIColor.green
        button.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        button.titleLabel?.textAlignment = NSTextAlignment.center
        button.titleLabel?.font = UIFont(name: "GothamPro", size: 20)
        button.setTitle("Ready", for: UIControlState())
        button.layer.cornerRadius = button.frame.width/2 // or height
        button.clipsToBounds = true
        button.alpha = 1.0
        button.isUserInteractionEnabled = false
        
        self.addSubview(button)
        self.balls.append(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func associateVC(_ vc: AlarmViewController){
        self.vc = vc
        
        for ball in self.balls as! [UIButton]{
            ball.addTarget(vc, action: Selector("AlarmButtonAction:"), for: UIControlEvents.touchUpInside)
        }
        
        self.addSubview(vc.numberPad)
        self.addSubview(vc.alarmCountDownLabel)
        self.addSubview(vc.touchIDButton)
        self.addSubview(vc.hiddenBlackView)
        self.addSubview(vc.hideButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if framesSet == false {
            animator = UIDynamicAnimator(referenceView: self)
            
            let radialGravity = UIFieldBehavior.noiseField(smoothness: 1.0, animationSpeed: 0.5)
            radialGravity.region = UIRegion(size: self.bounds.size)
            radialGravity.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
            radialGravity.strength = 1.5
            
            let vortex = UIFieldBehavior.vortexField()
            vortex.region = UIRegion(radius: self.bounds.size.width/2)
            vortex.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
            vortex.strength = 1
            
            for ball in self.balls {
                
                let randomWidth = (arc4random() % (UInt32(self.bounds.size.width) - UInt32(ball.bounds.size.width)))
                let randomHeight = (arc4random() % (UInt32(self.bounds.size.height) - UInt32(ball.bounds.size.height)))
                let xPos = UInt32(randomWidth) + UInt32(ball.bounds.size.width/2)
                let yPos = UInt32(randomHeight) + UInt32(ball.bounds.size.height/2)
                
                ball.center = CGPoint(x: CGFloat(xPos), y: CGFloat(yPos))
                
                radialGravity.addItem(ball)
                vortex.addItem(ball)
            }
            
            let behavior1 = UIDynamicItemBehavior(items: balls)
            behavior1.elasticity = 0.4
            behavior1.allowsRotation = false
            self.animator.addBehavior(behavior1)
            
            let behavior2 = UIDynamicItemBehavior(items: [self.vc.alarmCountDownLabel, self.vc.numberPad, self.vc.hideButton])
            behavior2.isAnchored = true
            self.animator.addBehavior(behavior2)
            
            // Create a new array to keep balls array ALL of same type (UIButton)
            var collisionArray = self.balls
            collisionArray?.append(self.vc.numberPad)
            
            let collision = UICollisionBehavior(items: collisionArray!)
            collision.translatesReferenceBoundsIntoBoundary = true
            self.animator.addBehavior(collision)
            
            self.animator.addBehavior(vortex)
            self.animator.addBehavior(radialGravity)
            
            //self.animator.setValue(Bool(kDebugLayout), forKey: "debugEnabled")
          
            framesSet = true
        }
    }
}
