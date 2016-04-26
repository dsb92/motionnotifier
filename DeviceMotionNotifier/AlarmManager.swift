//
//  Alarm.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 28/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

public enum State : String {
    case Ready = "Ready"
    case Arming = "Arming"
    case Armed = "Armed"
    case Alarming = "Alarming"
    case Alarm = "Intruder alert"
}

protocol AlarmUIDelegate {
    func idle ()
    func arming()
    func armed ()
    func alarming ()
    func alarm ()
}

class AlarmManager {
    static let sharedInstance = AlarmManager()
    
    var timerManager: TimerManager!
    var detectorManager: DetectorManager!
    
    var armedHandler : ArmedHandler!
    var vc : AlarmViewController!
    var alarmUIDelegate : AlarmUIDelegate!
    
    var state : State{
        didSet{
            print("Alarm state changed from "+oldValue.rawValue+" to "+state.rawValue)
            
            switch state {
                
            case .Ready:
                print("Ready")
                detectorManager?.stopDetectingMotions()
                detectorManager?.stopDetectingNoise()
                armedHandler?.stopMakingNoise()
                armedHandler?.stopCaptureVideo()
                timerManager.countDownTmer.stop()
                timerManager.delayTimer.stop()
                timerManager.notificationTimer.stop()
                
                alarmUIDelegate?.idle()
                break
                
            case .Arming:
                print("Arming")
                alarmUIDelegate?.arming()
                timerManager.countDownTmer.start()
                break
                
            case .Armed:
                print("Armed")
                // Start detecting motion
                detectorManager?.startDetectingMotion()
                
                // Start detecting noise if enabled
                let detectNoise = NSUserDefaults.standardUserDefaults().boolForKey("kSoundSwitchValue")
                if detectNoise {
                    detectorManager.startDetectingNoise()
                }
                
                alarmUIDelegate?.armed()
                break
                
            case .Alarming:
                alarmUIDelegate.alarming()
                timerManager.delayTimer.start()
                break
                
            case .Alarm:
                print("Intruder alert!")
                alarmUIDelegate.alarm()
                timerManager.notificationTimer.start()
                break
            }
            
        }
    }
    
    private init() {
        state = .Ready
        armedHandler = ArmedHandler()
        timerManager = TimerManager(handler: armedHandler)
    }
    
    func assoicateVC(vc: AlarmViewController){
        self.vc = vc
        armedHandler.alarmOnDelegate = vc
        alarmUIDelegate = vc
        self.detectorManager = DetectorManager(detectorProtocol: vc)
    }
    
    func initializeAlarm() {
        armedHandler.prepareToPlaySounds()
        
        armedHandler.autoSnap = AVAutoSnap(vc: self.vc)
        armedHandler.autoSnap.initializeOnViewDidLoad()
        armedHandler.autoSnap.initializeOnViewWillAppear()
        
    }
    
    func setAlarmState(state: State){
        self.state = state
    }
    
    func getAlarmState() -> State {
        return self.state
    }
}
