//
//  DetectorManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

protocol DetectorProtol {
    func detectMotion(_ accelerometerData: CMAccelerometerData!, gyroData: CMGyroData!)
    func detectNoise()
}

let motionThreshold = 0.50

class DetectorManager: NSObject {

    var detectorProtocol: DetectorProtol?
    var movementManager: CMMotionManager!
    var accelerometerData: CMAccelerometerData!
    var gyroData: CMGyroData!
    
    var audioRecorder: ARAudioRecognizer!
    var timesAudioRecognized = 0
    var audioRecognizedThreshold = 10

    var currentLocation: CLLocation?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    init(detectorProtocol: DetectorProtol){
        self.detectorProtocol = detectorProtocol
        movementManager = CMMotionManager()
        movementManager.accelerometerUpdateInterval = 1.0
    }
    
    func startDetectingMotion(){
        
        movementManager.startAccelerometerUpdates(to: OperationQueue.main) { (accelerometerData: CMAccelerometerData?, NSError) -> Void in
        
            if(NSError != nil) {
                print("\(NSError)")
            }
            
            if (self.accelerometerData == nil){
                self.accelerometerData = accelerometerData
            }
   
            DispatchQueue.main.async{
//                print(accelerometerData!.acceleration.x)
//                print(accelerometerData!.acceleration.y)
//                print(accelerometerData!.acceleration.z)
                self.detectorProtocol?.detectMotion(accelerometerData, gyroData: nil)
            }
        }
        
        movementManager.startGyroUpdates(to: OperationQueue.main, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
            
            if (NSError != nil){
                print("\(NSError)")
            }
            
            if (self.gyroData == nil) {
                self.gyroData = gyroData
            }
            
            DispatchQueue.main.async{
                self.detectorProtocol?.detectMotion(nil, gyroData: gyroData)
            }
        })
    }
    
    func stopDetectingMotions(){
        self.accelerometerData = nil
        self.gyroData = nil
        movementManager?.stopAccelerometerUpdates()
        movementManager?.stopGyroUpdates()
    }
    
    func startDetectingNoise(){
        audioRecorder = ARAudioRecognizer()
        audioRecorder.delegate = self
    }
    
    func stopDetectingNoise() {
        audioRecorder?.levelTimer.invalidate()
        audioRecorder = nil
        timesAudioRecognized = 0
    }
}

extension DetectorManager: ARAudioRecognizerDelegate {
    func audioRecognized(_ recognizer: ARAudioRecognizer!) {
        timesAudioRecognized += 1
        
        if timesAudioRecognized == audioRecognizedThreshold {
            self.detectorProtocol?.detectNoise()
        }
    }
}
