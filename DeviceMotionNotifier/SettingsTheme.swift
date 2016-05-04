//
//  SettingsTheme.swift
//  StarWarsAnimations
//
//  Created by Artem Sidorenko on 10/5/15.
//  Copyright © 2015 Yalantis. All rights reserved.
//

import UIKit

@objc class SettingsTheme : NSObject{
    
    static var theme01: SettingsTheme {
        return SettingsTheme()
    }
    
    let backgroundColor: UIColor
    let separatorColor: UIColor
    let topImage: UIImage
    
    let cellTitleColor: UIColor
    let cellTextFieldColor: UIColor
    let blueColor: UIColor
    let blackColor: UIColor
    let redColor: UIColor
    let greenColor: UIColor
    
    // alarm colors
    let ready: UIColor
    let arm: UIColor
    let disarm: UIColor
    let cancel: UIColor
    
    override init() {
        backgroundColor = UIColor(string: "#f8f8f8") // lighter lightgrey
        separatorColor = UIColor(string: "#ededed") // lightgrey
        topImage = UIImage(named: "devices")!
        cellTitleColor = UIColor(string: "#8e8e8e") // darkgrey
        cellTextFieldColor = UIColor(string: "#55606f") // darker darkgrey
        blueColor = UIColor(string: "#0288d1") // light blue
        blackColor = UIColor.blackColor()
        redColor = UIColor(string: "#ef5350") // light red
        greenColor = UIColor(string: "#3cb371") // light green
        
        // alarm colors
        ready = blueColor
        arm = redColor
        disarm = greenColor
        cancel = separatorColor
    }
    
}