//
//  SettingsTheme.swift
//  StarWarsAnimations
//
//  Created by Artem Sidorenko on 10/5/15.
//  Copyright © 2015 Yalantis. All rights reserved.
//

import UIKit

class SettingsTheme {
    
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

    init() {
        backgroundColor = UIColor(string: "#f8f8f8")
        separatorColor = UIColor(string: "#ededed")
        //topImage = UIImage(named: "PicNameHere")!
        cellTitleColor = UIColor(string: "#8e8e8e")
        cellTextFieldColor = UIColor(string: "#55606f")
        primaryColor = UIColor(string: "#0288d1")
        secondaryColor = UIColor.blackColor()
    }
    
}