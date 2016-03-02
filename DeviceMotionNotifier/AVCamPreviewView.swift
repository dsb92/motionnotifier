//
//  AVCamPreviewView.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 02/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class AVCamPreviewView: UIView {
    var session: AVCaptureSession? {
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session;
        }
        set(session){
            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
        }
    };
    
    
    
    override class func layerClass() ->AnyClass{
        return AVCaptureVideoPreviewLayer.self;
    }
}
