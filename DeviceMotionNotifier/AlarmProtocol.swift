//
//  AlarmProtocol.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import AVFoundation

protocol AlarmProtocol {
    func notifyRecipient()
    func alarmWithNoise()
    func takePicture()
    func recordVideo()
    func saveToCloud()
}
