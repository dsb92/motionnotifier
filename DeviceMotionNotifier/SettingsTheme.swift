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
    //let topImage: UIImage
    
    let cellTitleColor: UIColor
    let cellTextFieldColor: UIColor
    let primaryColor: UIColor
    let secondaryColor: UIColor

    override init() {
        backgroundColor = UIColor(string: "#f8f8f8") // lighter lightgrey
        separatorColor = UIColor(string: "#ededed") // lightgrey
        //topImage = UIImage(named: "PicNameHere")!
        cellTitleColor = UIColor(string: "#8e8e8e") // darkgrey
        cellTextFieldColor = UIColor(string: "#55606f") // darker darkgrey
        primaryColor = UIColor(string: "#0288d1") // blue
        secondaryColor = UIColor.blackColor()
    }
    
}