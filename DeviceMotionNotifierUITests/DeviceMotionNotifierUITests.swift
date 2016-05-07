//
//  DeviceMotionNotifierUITests.swift
//  DeviceMotionNotifierUITests
//
//  Created by David Buhauer on 06/05/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import XCTest

class DeviceMotionNotifierUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testWelcome() {
//        // Use recording to get started writing UI tests.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        
//        XCUIDevice.sharedDevice().orientation = .FaceUp
//        XCUIDevice.sharedDevice().orientation = .FaceUp
//        
//        snapshot("01")
//        
//        let app = XCUIApplication()
//        app.alerts["“DeviceMotionNotifier” vil gerne sende dig meddelelser"].collectionViews.buttons["OK"].tap()
//        app.images["page1.png"].swipeLeft()
//        app.images["page2.png"].tap()
//        
//        let window = app.childrenMatchingType(.Window).elementBoundByIndex(0)
//        let element = window.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element
//        element.childrenMatchingType(.Other).element.tap()
//        app.images["page4.jpg"].swipeLeft()
//        app.buttons["Ok, Let's begin"].tap()
//        
//        snapshot("02")
//        
//        element.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
//        app.tables.buttons["Continue without notifications"].tap()
//        
//        snapshot("03")
//        
//        window.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element.tap()
//        app.navigationBars["Alarm"].buttons["Menu icn"].tap()
//        
//    }
    
    func testNotWelcome() {
        XCUIDevice.sharedDevice().orientation = .FaceUp
        
        snapshot("01")
        
        let app = XCUIApplication()

        app.tables.buttons["Continue without notifications"].tap()
        
        sleep(5)
        snapshot("02")
        app.navigationBars["Alarm"].buttons["Menu icn"].tap()
        
        sleep(2)
        snapshot("03")
        
    }
    
    func testDeviceDetected() {
        
        let app = XCUIApplication()

        sleep(2)
        snapshot("01")
        
        app.tables.buttons["Continue without notifications"].tap()
        
        sleep(3)
        snapshot("02")
        app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.tap()
        app.navigationBars["Alarm"].buttons["Menu icn"].tap()
        
        sleep(2)
        snapshot("03")
    }
    
    func testDeviceNotDetected() {
        
        let app = XCUIApplication()
        
        snapshot("01")
        app.tables.buttons["Continue without notifications"].tap()
        
        sleep(5)
        snapshot("02")
        
        app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.tap()
        app.navigationBars["Alarm"].buttons["Menu icn"].tap()
        
        sleep(2)
        snapshot("03")
    }
}
