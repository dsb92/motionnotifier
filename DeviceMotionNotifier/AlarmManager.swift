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
    var captureSession: AVCaptureSession!
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
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
        
        if (captureSession == nil){
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            
            let devices = AVCaptureDevice.devices()
            
            // Loop through all the capture devices on this phone
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the back camera
                    if(device.position == AVCaptureDevicePosition.Front) {
                        captureDevice = device as? AVCaptureDevice
                        if captureDevice != nil {
                            print("Capture device found")
                            beginSession()
                        }
                    }
                }
            }
        }
    }
    
    private func beginSession() {
        configureDevice()
        
        do{
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(deviceInput)
        }
        catch {
            print(error)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        alarmProtocol?.takePicture(previewLayer!, captureSession: captureSession)

    }
    
    private func configureDevice() {
        if let device = captureDevice {
            do{
                try device.lockForConfiguration()
                //device.focusMode = .Locked
                device.unlockForConfiguration()
            }
            catch {
                print(error)
            }
        }
    }
}
