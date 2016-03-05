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
        var string = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString

        if string.hasPrefix("#") {
            string = (string as NSString).substringFromIndex(1)
        }
        
        if string.characters.count != 6 {
            fatalError()
        }
        
        let rString = (string as NSString).substringToIndex(2)
        let gString = ((string as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        let bString = ((string as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        NSScanner(string: rString).scanHexInt(&r)
        NSScanner(string: gString).scanHexInt(&g)
        NSScanner(string: bString).scanHexInt(&b)
        
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
    }
}