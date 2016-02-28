//
//  AlarmManager.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import Foundation

class AlarmManager: NSObject {
    var alarmProtocol: AlarmProtocol?
    
    init(alarmProtocol: AlarmProtocol){
        self.alarmProtocol = alarmProtocol
    }
    
    func startNotifyingRecipient(){
        alarmProtocol?.notifyRecipient()
    }
    
    func startMakingNoise(){
        alarmProtocol?.alarmWithNoise()
    }
}
