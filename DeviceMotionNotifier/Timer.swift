//
//  Timer.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class Timer : NSObject {
    var armedHandler : ArmedHandler!
    
    override init() {
        self.armedHandler = ArmedHandler()
    }
}
