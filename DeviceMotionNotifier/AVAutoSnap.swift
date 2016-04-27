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
    
    var sessionQueue: dispatch_queue_t!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput!
    var stillImageOutput: AVCaptureStillImageOutput?
    
    
    var deviceAuthorized: Bool  = false
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.running != nil && self.deviceAuthorized )
        }
    }
    
    var runtimeErrorHandlingObserver: AnyObject?
    var lockInterfaceRotation: Bool = false
    
    var vc: AlarmViewController!
    
    init(vc: AlarmViewController){
        
        self.vc = vc

    }
    
    func initializeOnViewDidLoad(){
        
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        
        vc.previewView.session = session
        
        self.checkDeviceAuthorizationStatus()
        
        let sessionQueue: dispatch_queue_t = dispatch_queue_create("session queue",DISPATCH_QUEUE_SERIAL)
        
        self.sessionQueue = sessionQueue
        dispatch_async(sessionQueue, {
            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice! = AVAutoSnap.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.Front)
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
                    , preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.vc.presentViewController(alert, animated: true, completion: nil)
            }
            
            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    let orientation: AVCaptureVideoOrientation =  AVCaptureVideoOrientation(rawValue: self.vc.interfaceOrientation.rawValue)!

                    (self.vc.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResize
                    (self.vc.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                })
                
            }
            
            
            let audioDevice: AVCaptureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).first as! AVCaptureDevice
            
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
                    , preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.vc.presentViewController(alert, animated: true, completion: nil)
            }
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            
            
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                session.addOutput(movieFileOutput)
                
                
                let connection: AVCaptureConnection? = movieFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                let stab = connection?.supportsVideoStabilization
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
    
    func initializeOnViewWillAppear(){
        dispatch_async(self.sessionQueue, {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.Old , .New] , context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.Old , .New], context: &CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.Old , .New], context: &RecordingContext)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("subjectAreaDidChange:"), name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
            
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.session, queue: nil, usingBlock: {
                (note: NSNotification?) in
                let strongSelf: AVAutoSnap = weakSelf!
                dispatch_async(strongSelf.sessionQueue, {
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
        self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized")
        self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage")
        self.removeObserver(self, forKeyPath: "movieFileOutput.recording")
    }
    
    func snapPhoto(){
        print("snapStillImage")
        dispatch_async(self.sessionQueue, {
            // Update the orientation on the still image output video connection before capturing.
            
            let videoOrientation =  (self.vc.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            
            self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = videoOrientation
            
            // Flash set to Auto for Still Capture
            AVAutoSnap.setFlashMode(AVCaptureFlashMode.Auto, device: self.videoDeviceInput!.device)
            
            self.stillImageOutput!.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) in
                
                if error == nil {
                    let data:NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let image:UIImage = UIImage( data: data)!
                    
                    let libaray:ALAssetsLibrary = ALAssetsLibrary()
                    let orientation: ALAssetOrientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
                    libaray.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation, completionBlock: nil)
                    
                    print("save to album")
                    
                    
                    
                }else{
                    //                    print("Did not capture still image")
                    print(error)
                }
                
                
            })
            
            
        })
        
    }
    
    func startRecording() {
        dispatch_async(self.sessionQueue, {
            self.lockInterfaceRotation = true
            
            if UIDevice.currentDevice().multitaskingSupported {
                self.backgroundRecordId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
                
            }
            
            self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo).videoOrientation =
                AVCaptureVideoOrientation(rawValue: (self.vc.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
            
            // Turning OFF flash for video recording
            AVAutoSnap.setFlashMode(AVCaptureFlashMode.Off, device: self.videoDeviceInput!.device)
            
            let outputFilePath  =
            NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("movie.mov")
            
            //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
            
            self.movieFileOutput!.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
        })
    }
    
    func stopRecording() {
        if isRecording() {
            self.movieFileOutput!.stopRecording()
        }
    }
    
    func isRecording() -> Bool{
        if self.movieFileOutput != nil {
            self.movieFileOutput.recording
        }
        
        return false
    }
    
    func checkDeviceAuthorizationStatus(){
        let mediaType:String = AVMediaTypeVideo;
        
        AVCaptureDevice.requestAccessForMediaType(mediaType, completionHandler: { (granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
            }else{
                
                dispatch_async(dispatch_get_main_queue(), {
                    let alert: UIAlertController = UIAlertController(
                        title: "AVCam",
                        message: "AVCam does not have permission to access camera",
                        preferredStyle: UIAlertControllerStyle.Alert);
                    
                    let action: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                        (action2: UIAlertAction) in
                        exit(0);
                    } );
                    
                    alert.addAction(action);
                    
                    self.vc.presentViewController(alert, animated: true, completion: nil);
                })
                
                self.deviceAuthorized = false;
            }
        })
        
    }
    
    class func deviceWithMediaType(mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        
        var devices = AVCaptureDevice.devicesWithMediaType(mediaType);
        var captureDevice: AVCaptureDevice = devices[0] as! AVCaptureDevice;
        
        for device in devices{
            if device.position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
        
    }
    
    class func setFlashMode(flashMode: AVCaptureFlashMode, device: AVCaptureDevice){
        
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
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
  
        if context == &CapturingStillImageContext{
            let isCapturingStillImage: Bool = change![NSKeyValueChangeNewKey]!.boolValue
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
            
        }else if context  == &RecordingContext{
            let isRecording: Bool = change![NSKeyValueChangeNewKey]!.boolValue
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if isRecording {
                    
                    
                }else{

                    
                }
                
                
            })
            
            
        }
            
        else{
            return super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }

    func runStillImageCaptureAnimation(){
        dispatch_async(dispatch_get_main_queue(), {
            self.vc.previewView.layer.opacity = 0.0
            print("opacity 0")
            UIView.animateWithDuration(0.25, animations: {
                self.vc.previewView.layer.opacity = 1.0
                print("opacity 1")
            })
        })
    }
    
    }

extension AVAutoSnap: AVCaptureFileOutputRecordingDelegate{
    // MARK: File Output Delegate
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        if(error != nil){
            print(error)
        }
        
        self.lockInterfaceRotation = false
        
        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
        
        let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
        self.backgroundRecordId = UIBackgroundTaskInvalid
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileURL, completionBlock: {
            (assetURL:NSURL!, error:NSError!) in
            if error != nil{
                print(error)
                
            }
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
            } catch _ {
            }
            
            if backgroundRecordId != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(backgroundRecordId)
            }
            
        })
    }
}
