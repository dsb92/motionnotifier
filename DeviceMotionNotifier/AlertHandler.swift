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
        
        let silent = UserDefaults.standard.bool(forKey: "kSilentValue")
        
        if !silent {
            if self.intruderSoundPlayer != nil && self.intruderSoundPlayer.isPlaying == false {
                self.intruderSoundPlayer.play()
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
        let silent = UserDefaults.standard.bool(forKey: "kSilentValue")
        
        if !silent {
            let priority = DispatchQueue.GlobalQueuePriority.default
            DispatchQueue.global(priority: priority).async{
                
                if self.beepSoundPlayer != nil && self.beepSoundPlayer.isPlaying == false {
                    
                    self.beepSoundPlayer.play()
                }
            }
        }
        
        alarmOnDelegate?.beep()
    }
    
    func startTone() {
        
        let silent = UserDefaults.standard.bool(forKey: "kSilentValue")
        
        if !silent {
            let priority = DispatchQueue.GlobalQueuePriority.default
            DispatchQueue.global(priority: priority).async{
                
                if self.toneSoundPlayer != nil && self.toneSoundPlayer.isPlaying == false {
                    self.toneSoundPlayer.play()
                }
            }
        }
        
        alarmOnDelegate?.tone()
    }
    
    func startFrontCamera() {
        
        alarmOnDelegate?.takePicture()
    }
    
    func startCaptureVideo() {
        alarmOnDelegate?.recordVideo()
    }
    
    func stopCaptureVideo() {
        autoSnap?.stopRecording()
    }
    
    func prepareToPlaySounds() {
        if (self.intruderSoundPlayer == nil){
            let intruderSound = URL(fileURLWithPath: Bundle.main.path(forResource: "intruder_alarm", ofType: "wav")!)
            
            do {
                self.intruderSoundPlayer = try AVAudioPlayer(contentsOf: intruderSound)
                self.intruderSoundPlayer.volume = 1.0
                self.intruderSoundPlayer.prepareToPlay()
            }
            catch{
                print(error)
            }
        }
        
        if (self.beepSoundPlayer == nil){
            let beepSound = URL(fileURLWithPath: Bundle.main.path(forResource: "beep", ofType: "wav")!)
            
            do {
                self.beepSoundPlayer = try AVAudioPlayer(contentsOf: beepSound)
                self.beepSoundPlayer.volume = 1.0
                self.beepSoundPlayer.prepareToPlay()
            }
            catch{
                print(error)
            }
        }
        
        if (self.toneSoundPlayer == nil){
            let toneSound = URL(fileURLWithPath: Bundle.main.path(forResource: "tone", ofType: "wav")!)
            
            do {
                self.toneSoundPlayer = try AVAudioPlayer(contentsOf: toneSound)
                self.toneSoundPlayer.volume = 1.0
                self.toneSoundPlayer.prepareToPlay()
            }
            catch{
                print(error)
            }
        }
    }
}

