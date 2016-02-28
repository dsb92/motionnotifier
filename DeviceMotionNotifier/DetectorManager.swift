//
//  DetectorManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import CoreMotion

let threshold = 0.50

class DetectorManager: NSObject {

    var detectorProtocol: DetectorProtol?
    var movementManager: CMMotionManager!
    var accelerometerData: CMAccelerometerData!
    var gyroData: CMGyroData!
    
    init(detectorProtocol: DetectorProtol){
        self.detectorProtocol = detectorProtocol
        movementManager = CMMotionManager()
        movementManager.accelerometerUpdateInterval = 1.0
    }
    
    func startDetectingMotion(){
        movementManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!) { (accelerometerData: CMAccelerometerData?, NSError) -> Void in
        
            if(NSError != nil) {
                print("\(NSError)")
            }
            
            if (self.accelerometerData == nil){
                self.accelerometerData = accelerometerData
            }
            
            self.detectorProtocol?.detectMotion(accelerometerData, gyroData: nil)
        }
        
        movementManager.startGyroUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
            
            if (NSError != nil){
                print("\(NSError)")
            }
            
            if (self.gyroData == nil) {
                self.gyroData = gyroData
            }
            
            self.detectorProtocol?.detectMotion(nil, gyroData: gyroData)
            
        })
    }
    
    func startDetectingNoise(){
        
        self.detectorProtocol?.detectNoise()
    }

}
