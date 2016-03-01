//
//  DetectorManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import CoreMotion

let motionThreshold = 0.50

class DetectorManager: NSObject {

    var detectorProtocol: DetectorProtol?
    var movementManager: CMMotionManager!
    var accelerometerData: CMAccelerometerData!
    var gyroData: CMGyroData!
    
    var audioRecorder: ARAudioRecognizer!
    var timesAudioRecognized = 0
    var audioRecognizedThreshold = 10
    
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
            
            dispatch_async(dispatch_get_main_queue()){
                self.detectorProtocol?.detectMotion(accelerometerData, gyroData: nil)
            }
        }
        
        movementManager.startGyroUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
            
            if (NSError != nil){
                print("\(NSError)")
            }
            
            if (self.gyroData == nil) {
                self.gyroData = gyroData
            }
            
            dispatch_async(dispatch_get_main_queue()){
                self.detectorProtocol?.detectMotion(nil, gyroData: gyroData)
            }
        })
    }
    
    func stopDetectingMotions(){
        movementManager.stopAccelerometerUpdates()
        movementManager.stopGyroUpdates()
    }
    
    func startDetectingNoise(){
        audioRecorder = ARAudioRecognizer()
        audioRecorder.delegate = self
    }
    
    func stopDetectingNoise() {
        audioRecorder.levelTimer.invalidate()
        audioRecorder = nil
        timesAudioRecognized = 0
    }
}

extension DetectorManager: ARAudioRecognizerDelegate {
    func audioRecognized(recognizer: ARAudioRecognizer!) {
        ++timesAudioRecognized
        
        if timesAudioRecognized == audioRecognizedThreshold {
            self.detectorProtocol?.detectNoise()
        }
    }
}
