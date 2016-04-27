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
    case Alert = "Alert"
    case Alerting = "Alerting"
}

protocol AlarmUIDelegate {
    func idle () // Ready
    func arming() // Arming, beep...
    func armed () // Armed
    func alert () // Alert, tone...
    func alerting () // Alerting, alarm...
}

class AlarmManager {
    static let sharedInstance = AlarmManager()
    
    var timerManager: TimerManager!
    var detectorManager: DetectorManager!
    
    var armedHandler : AlertHandler!
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
                
                deinitialize()
                
                alarmUIDelegate?.idle()
                break
                
            case .Arming:
                print("Arming")

                // Initialize what ever needs to be initialized (in a thread)
                initialize()
                
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
                
            case .Alert:
                alarmUIDelegate.alert()
                timerManager.delayTimer.start()
                break
                
            case .Alerting:
                print("Intruder alert!")
                alarmUIDelegate.alerting()
                timerManager.notificationTimer.start()
                break
            }
            
        }
    }
    
    private init() {
        state = .Ready
        armedHandler = AlertHandler()
        timerManager = TimerManager(handler: armedHandler)
    }
    
    func assoicateVC(vc: AlarmViewController){
        self.vc = vc
        armedHandler.alarmOnDelegate = vc
        alarmUIDelegate = vc
        self.detectorManager = DetectorManager(detectorProtocol: vc)
    }
    
    func initialize() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            
            self.armedHandler.prepareToPlaySounds()
            
            if self.armedHandler.autoSnap == nil {
                self.armedHandler.autoSnap = AVAutoSnap(vc: self.vc)
            }
            
            self.armedHandler.autoSnap?.initializeOnViewDidLoad()
            self.armedHandler.autoSnap?.initializeOnViewWillAppear()
            
            dispatch_async(dispatch_get_main_queue()) {
                // update some UI
            }
        }
    }
    
    func deinitialize() {
        armedHandler.autoSnap?.deinitialize()
        armedHandler.autoSnap = nil
    }
    
    func setAlarmState(state: State){
        self.state = state
    }
    
    func getAlarmState() -> State {
        return self.state
    }
}
