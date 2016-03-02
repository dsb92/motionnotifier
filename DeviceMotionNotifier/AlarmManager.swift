//
//  AlarmManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

class AlarmManager: NSObject {
    var alarmProtocol: AlarmProtocol?
    var intruderSoundPlayer: AVAudioPlayer!

    var autoSnap: AVAutoSnap!

    init(alarmProtocol: AlarmProtocol){
        self.alarmProtocol = alarmProtocol
    }
    
    func startNotifyingRecipient(){
        alarmProtocol?.notifyRecipient()
    }
    
    func startMakingNoise(){
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)){
            
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            if (self.intruderSoundPlayer == nil){
                let intruderSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("intruder_alarm", ofType: "wav")!)
                
                do {
                    self.intruderSoundPlayer = try AVAudioPlayer(contentsOfURL: intruderSound)
                    self.intruderSoundPlayer.volume = 1.0
                    self.intruderSoundPlayer.prepareToPlay()
                }
                catch{
                    print(error)
                }
            }
            else{
                
                if self.intruderSoundPlayer.playing == false {
                    self.intruderSoundPlayer.play()
                }
            }
        }
        
        
        alarmProtocol?.alarmWithNoise()
    }
    
    func stopMakingNoise(){
        if intruderSoundPlayer != nil {
            intruderSoundPlayer.stop()
        }
    }
    
    func startFrontCamera() {
        
        alarmProtocol?.takePicture()
    }
}
