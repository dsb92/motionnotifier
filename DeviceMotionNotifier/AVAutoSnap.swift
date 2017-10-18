//
//  AVAutoSnap.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 02/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"
var RecordingContext = "RecordingContext"

class AVAutoSnap: NSObject {
    // MARK: property
    
    var sessionQueue: DispatchQueue!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput!
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewView: AVCamPreviewView!
    
    var deviceAuthorized: Bool  = false
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.isRunning != nil && self.deviceAuthorized )
        }
    }
    
    var runtimeErrorHandlingObserver: AnyObject?
    var lockInterfaceRotation: Bool = false
    
    var vc: UIViewController!
    
    init(previewView: AVCamPreviewView){
        
        self.previewView = previewView
        self.vc = (UIApplication.shared.delegate as! AppDelegate).window?.visibleViewController
    }
    
    func initializeOnViewDidLoad() throws{
        
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        
        previewView!.session = session
        
        self.checkDeviceAuthorizationStatus()
        
        let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue",attributes: [])
        
        self.sessionQueue = sessionQueue
        sessionQueue.async(execute: {
            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice! = AVAutoSnap.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.front)
            var error: NSError? = nil
            
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error1 as NSError {
                error = error1
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if (error != nil) {
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.vc.present(alert, animated: true, completion: nil)
            }
            
            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async(execute: {
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    let orientation: AVCaptureVideoOrientation =  AVCaptureVideoOrientation(rawValue: self.vc.interfaceOrientation.rawValue)!

                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResize
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                })
                
            }
            
            
            let audioDevice: AVCaptureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio).first as! AVCaptureDevice
            
            var audioDeviceInput: AVCaptureDeviceInput?
            
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            } catch let error2 as NSError {
                error = error2
                audioDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if error != nil{
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.vc.present(alert, animated: true, completion: nil)
            }
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            
            
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                session.addOutput(movieFileOutput)
                
                
                let connection: AVCaptureConnection? = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
                let stab = connection?.isVideoStabilizationSupported
                if (stab != nil) {
                    //connection!.preferredVideoStabilizationMode = true
                }
                
                self.movieFileOutput = movieFileOutput
                
            }
            
            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput){
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                
                self.stillImageOutput = stillImageOutput
            }
        })
        
        
    }
    
    func initializeOnViewWillAppear() throws{
        self.sessionQueue.async(execute: {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.old , .new] , context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.old , .new], context: &CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.old , .new], context: &RecordingContext)
            
            NotificationCenter.default.addObserver(self, selector: Selector("subjectAreaDidChange:"), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
            
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.session, queue: nil, using: {
                (note: Notification?) in
                let strongSelf: AVAutoSnap = weakSelf!
                strongSelf.sessionQueue.async(execute: {
                    //                    strongSelf.session?.startRunning()
                    if let sess = strongSelf.session{
                        sess.startRunning()
                    }
                    //                    strongSelf.recordButton.title  = NSLocalizedString("Record", "Recording button record title")
                })
                
            })
            
            self.session?.startRunning()
            
        })

    }
    
    func deinitialize() {
        self.sessionQueue.async(execute: {
            
            if let sess = self.session{
                sess.stopRunning()
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
                NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
                
                self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
                
                self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
                self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: &RecordingContext)
                
                
            }
        })
    }
    
    func snapPhoto(){
        print("snapStillImage")
        self.sessionQueue.async(execute: {
            // Update the orientation on the still image output video connection before capturing.
            
            let videoOrientation =  (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            
            self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation = videoOrientation
            
            // Flash set to Auto for Still Capture
            AVAutoSnap.setFlashMode(AVCaptureFlashMode.auto, device: self.videoDeviceInput!.device)
            
            self.stillImageOutput!.captureStillImageAsynchronously(from: self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer?, error: Error?) in
                
                if error == nil {
                    let data:Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let image:UIImage = UIImage( data: data)!
                    
                    let libaray:ALAssetsLibrary = ALAssetsLibrary()
                    let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
                    libaray.writeImage(toSavedPhotosAlbum: image.cgImage, orientation: orientation, completionBlock: nil)
                    
                    print("save to album")
                    
                    
                    
                }else{
                    //                    print("Did not capture still image")
                    print(error)
                }
                
                
            })
            
            
        })
        
    }
    
    func startRecording() {
        self.sessionQueue.async(execute: {
            self.lockInterfaceRotation = true
            
            if UIDevice.current.isMultitaskingSupported {
                self.backgroundRecordId = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
                
            }
            
            self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation =
                AVCaptureVideoOrientation(rawValue: (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
            
            print(self.movieFileOutput.description)
            
            // Turning OFF flash for video recording
            AVAutoSnap.setFlashMode(AVCaptureFlashMode.off, device: self.videoDeviceInput!.device)
            
            let outputFilePath  =
            URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("movie.mov")
            
            //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
            
            self.movieFileOutput!.startRecording( toOutputFileURL: outputFilePath, recordingDelegate: self)
        })
    }
    
    func stopRecording() {
        if isRecording() {
            self.movieFileOutput!.stopRecording()
        }
    }
    
    func isRecording() -> Bool{
        if self.movieFileOutput != nil {
            self.movieFileOutput.isRecording
        }
        
        return false
    }
    
    func checkDeviceAuthorizationStatus(){
        let mediaType:String = AVMediaTypeVideo;
        
        AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: { (granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
            }else{
                
                DispatchQueue.main.async(execute: {
                    let alert: UIAlertController = UIAlertController(
                        title: "AVCam",
                        message: "AVCam does not have permission to access camera",
                        preferredStyle: UIAlertControllerStyle.alert);
                    
                    let action: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                        (action2: UIAlertAction) in
                        exit(0);
                    } );
                    
                    alert.addAction(action);
                    
                    self.vc.present(alert, animated: true, completion: nil);
                })
                
                self.deviceAuthorized = false;
            }
        })
        
    }
    
    class func deviceWithMediaType(_ mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        
        var devices = AVCaptureDevice.devices(withMediaType: mediaType);
        var captureDevice: AVCaptureDevice = devices![0] as! AVCaptureDevice;
        
        for device in devices!{
            if (device as AnyObject).position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
        
    }
    
    class func setFlashMode(_ flashMode: AVCaptureFlashMode, device: AVCaptureDevice){
        
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
            } catch let error1 as NSError {
                error = error1
                print(error)
            }
        }
        
    }
    
    //    observeValueForKeyPath:ofObject:change:context:
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
  
        if context == &CapturingStillImageContext{
            let isCapturingStillImage: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
            
        }else if context  == &RecordingContext{
            let isRecording: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            
            DispatchQueue.main.async(execute: {
                
                if isRecording {
                    
                    
                }else{

                    
                }
                
                
            })
            
            
        }
            
        else{
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }

    func runStillImageCaptureAnimation(){
        DispatchQueue.main.async(execute: {
            self.previewView.layer.opacity = 0.0
            print("opacity 0")
            UIView.animate(withDuration: 0.25, animations: {
                self.previewView.layer.opacity = 1.0
                print("opacity 1")
            })
        })
    }
    
    }

extension AVAutoSnap: AVCaptureFileOutputRecordingDelegate{
    // MARK: File Output Delegate
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        if(error != nil){
            print(error)
        }
        
        self.lockInterfaceRotation = false
        
        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
        
        let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
        self.backgroundRecordId = UIBackgroundTaskInvalid
        
        ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: outputFileURL, completionBlock: {
            (assetURL:URL?, error:Error?) in
            if error != nil{
                print(error)
                
            }
            
            do {
                try FileManager.default.removeItem(at: outputFileURL)
            } catch _ {
            }
            
            if backgroundRecordId != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(backgroundRecordId)
            }
            
        })
    }
}
