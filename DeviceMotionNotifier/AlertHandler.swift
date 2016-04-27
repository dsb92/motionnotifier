//
//  ArmedHandler.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 26/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

protocol AlarmOnDelegate {
    func notifyRecipient()
    func beep()
    func tone()
    func alarmWithNoise()
    func takePicture()
    func recordVideo()
}

class AlertHandler {
    var alarmOnDelegate: AlarmOnDelegate?
    var intruderSoundPlayer: AVAudioPlayer!
    var beepSoundPlayer: AVAudioPlayer!
    var toneSoundPlayer: AVAudioPlayer!
    var autoSnap: AVAutoSnap!
    
    func startNotifyingRecipient(){
        alarmOnDelegate?.notifyRecipient()
    }
    
    func startMakingNoise(){
        
        let silent = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        if !silent {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                
                if self.intruderSoundPlayer.playing == false {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.intruderSoundPlayer.play()
                }
            }
        }
        
        alarmOnDelegate?.alarmWithNoise()
    }
    
    func stopMakingNoise(){
        if intruderSoundPlayer != nil {
            intruderSoundPlayer.stop()
        }
    }
    
    func startBeep() {
        
        let silent = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        if !silent {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                
                if self.beepSoundPlayer.playing == false {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.beepSoundPlayer.play()
                }
            }
        }
        
        alarmOnDelegate?.beep()
    }
    
    func startTone() {
        
        let silent = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        if !silent {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                
                if self.toneSoundPlayer.playing == false {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.toneSoundPlayer.play()
                }
            }
        }
        
        alarmOnDelegate?.tone()
    }
    
    func startFrontCamera() {
        
        //alarmProtocol?.takePicture()
    }
    
    func startCaptureVideo() {
        //alarmProtocol?.recordVideo()
    }
    
    func stopCaptureVideo() {
        autoSnap?.stopRecording()
    }
    
    func prepareToPlaySounds() {
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
        
        if (self.beepSoundPlayer == nil){
            let beepSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("beep", ofType: "wav")!)
            
            do {
                self.beepSoundPlayer = try AVAudioPlayer(contentsOfURL: beepSound)
                self.beepSoundPlayer.volume = 1.0
                self.beepSoundPlayer.prepareToPlay()
            }
            catch{
                print(error)
            }
        }
        
        if (self.toneSoundPlayer == nil){
            let toneSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("tone", ofType: "wav")!)
            
            do {
                self.toneSoundPlayer = try AVAudioPlayer(contentsOfURL: toneSound)
                self.toneSoundPlayer.volume = 1.0
                self.toneSoundPlayer.prepareToPlay()
            }
            catch{
                print(error)
            }
        }
    }
}

