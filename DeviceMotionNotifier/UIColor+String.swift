//
//  UIColor+String.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 25/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit


extension UIColor {
    convenience init(string: String) {
        var string = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if string.hasPrefix("#") {
            string = (string as NSString).substring(from: 1)
        }
        
        if string.characters.count != 6 {
            fatalError()
        }
        
        let rString = (string as NSString).substring(to: 2)
        let gString = ((string as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bString = ((string as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string: rString).scanHexInt32(&r)
        Scanner(string: gString).scanHexInt32(&g)
        Scanner(string: bString).scanHexInt32(&b)
        
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
}
