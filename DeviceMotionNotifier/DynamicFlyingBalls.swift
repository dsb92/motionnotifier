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
        let button = UIButton(type: UIButtonType.Custom)
        button.frame = CGRectMake(0, 0, 160, 160)
        button.backgroundColor = UIColor.greenColor()
        button.titleLabel?.textColor = UIColor.greenColor()
        button.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        button.titleLabel?.textAlignment = NSTextAlignment.Center
        button.titleLabel?.font = UIFont(name: "GothamPro", size: 20)
        button.setTitle("Ready", forState: UIControlState.Normal)
        button.layer.cornerRadius = button.frame.width/2 // or height
        button.clipsToBounds = true
        button.alpha = 1.0
        button.userInteractionEnabled = false
        
        self.addSubview(button)
        self.balls.append(button)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func associateVC(vc: AlarmViewController){
        self.vc = vc

        for ball in self.balls as! [UIButton]{
            ball.addTarget(vc, action: "AlarmButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        }

        self.addSubview(vc.numberPad)
        self.addSubview(vc.touchIDButton)
        self.addSubview(vc.hiddenBlackView)
        self.addSubview(vc.hideButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if framesSet == false {
            print("Layout")
            
            animator = UIDynamicAnimator(referenceView: self)
            
            let field1 = UIFieldBehavior.vortexField()
            field1.region = UIRegion(radius: self.bounds.size.width/2)
            field1.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)
            field1.strength = 1
            
            let field2 = UIFieldBehavior.noiseFieldWithSmoothness(1.0, animationSpeed: 0.5)
            field2.region = UIRegion(size: self.bounds.size)
            field2.position = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)
            field2.strength = 1
            
            for label in self.balls {
                
                let randomWidth = (arc4random() % (UInt32(self.bounds.size.width) - UInt32(label.bounds.size.width)))
                let randomHeight = (arc4random() % (UInt32(self.bounds.size.height) - UInt32(label.bounds.size.height)))
                let xPos = UInt32(randomWidth) + UInt32(label.bounds.size.width/2)
                let yPos = UInt32(randomHeight) + UInt32(label.bounds.size.height/2)
                
                label.center = CGPointMake(CGFloat(xPos), CGFloat(yPos))
                
                field1.addItem(label)
                field2.addItem(label)
            }
            
            let behavior1 = UIDynamicItemBehavior(items: balls)
            behavior1.elasticity = 0.4
            behavior1.allowsRotation = true
            self.animator.addBehavior(behavior1)
            
            let behavior2 = UIDynamicItemBehavior(items: [self.vc.numberPad, self.vc.hideButton])
            behavior2.anchored = true
            self.animator.addBehavior(behavior2)
            
            // Create a new array to keep balls array ALL of same type (UIButton)
            var collisionArray = self.balls
            collisionArray.append(self.vc.numberPad)
            
            let collision = UICollisionBehavior(items: collisionArray)
            collision.translatesReferenceBoundsIntoBoundary = true
            self.animator.addBehavior(collision)
            
            self.animator.addBehavior(field1)
            self.animator.addBehavior(field2)
            
            //self.animator.setValue(true, forKey: "debugEnabled")
            
            framesSet = true
        }
    }
}
