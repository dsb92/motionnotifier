//
//  MenuViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 06/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

//private let tableViewOffset: CGFloat = UIScreen.mainScreen().bounds.height < 600 ? 108 : 113
//private let appearOffset: CGFloat = 100

class AlarmMenuViewController: UITableViewController {

    @IBOutlet
    private var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    weak var slider: UISlider!
    
    @IBOutlet
    weak var sliderValueLabel: UILabel!
    
    @IBOutlet
    weak var photoSwitch: UISwitch!
    
    @IBOutlet
    weak var videoSwitch: UISwitch!
    
    @IBOutlet
    weak var delaySwitch: UISwitch!
    
    @IBOutlet
    weak var soundSwitch: UISwitch!

    @IBOutlet
    weak var sensitivityTableCell: UITableViewCell!
    
    var theme: SettingsTheme! {
        didSet {
            tableView.separatorColor = theme.separatorColor

            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }

            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        theme = SettingsTheme.theme01
        
        setSettings()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
//        tableView.contentOffset = CGPoint(x: 0, y: -appearOffset)
//        
//        UIView.animateWithDuration(0.5, animations: {
//            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
//        })
    }
    
    private func setSettings() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let savedTimerValue = userDefaults.integerForKey("kTimerValue")
        let savedPhotoSwitchValue = userDefaults.boolForKey("kPhotoSwitchValue")
        let savedVideoSwitchValue = userDefaults.boolForKey("kVideoSwitchValue")
        let savedDelaySwitchValue = userDefaults.boolForKey("kDelaySwitchValue")
        let savedSoundSwitchValue = userDefaults.boolForKey("kSoundSwitchValue")
        
        slider.value = Float(savedTimerValue)
        sliderValueLabel.text = String(savedTimerValue)
        photoSwitch.setOn(savedPhotoSwitchValue, animated: false)
        videoSwitch.setOn(savedVideoSwitchValue, animated: false)
        delaySwitch.setOn(savedDelaySwitchValue, animated: false)
        soundSwitch.setOn(savedSoundSwitchValue, animated: false)
        
        photoSwitch.enabled = videoSwitch.on ? false : true
        videoSwitch.enabled = photoSwitch.on ? false : true
        
        sensitivityTableCell.hidden = soundSwitch.on ? false : true
    }
    
    private func showPurchaseAlertView(productId : String) {
        if IAPManager.sharedInstance.canMakePayments {
            var titleString:String!
            var message:String!
            
            var buttonTexts = [String]()
            
            // For each in-app product: display a buy button with title and price labeled and call purchase function with the product identifier as argument.
            for product in IAPManager.sharedInstance.list {
                
                // Product title
                let title = product.localizedTitle
                
                // Format the price to local currency price
                let formatter = NSNumberFormatter()
                formatter.numberStyle = .CurrencyStyle
                formatter.locale = product.priceLocale
                
                // The localized price
                let price = formatter.stringFromNumber(product.price)
                
                titleString = title + "\t" + price!
                
                if productId == IAPManager.sharedInstance.products.VideoCapture {
                    if product.productIdentifier == IAPManager.sharedInstance.products.VideoCapture {
                        
                        message = "Video Capture"
                        
                        buttonTexts.append(titleString)
                        
                        break
                    }
                    
                }
                else {
                    if product.productIdentifier == IAPManager.sharedInstance.products.SoundRegonition {
                        message = "Sound Recognition"
                        buttonTexts.append(titleString)
                    }
                }
            }
            
            buttonTexts.append(NSLocalizedString("Cancel", comment: "Cancel"))
            
            let alertView = JSSAlertView().show(self, title: "Store", text: message, buttonTexts: buttonTexts, color: UIColor.blackColor().colorWithAlphaComponent(0.7))
            
            alertView.setTitleFont("ClearSans-Bold")
            alertView.setTextFont("ClearSans")
            alertView.setButtonFont("ClearSans-Light")
            alertView.setTextTheme(.Golden)
            
            alertView.addAction({
                
                if alertView.getButtonId() == 1 && productId == IAPManager.sharedInstance.products.VideoCapture {
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.VideoCapture, purchaseProtocol: self)
                }
                else {
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.SoundRegonition, purchaseProtocol: self)
                }
                
            })
            
            alertView.addCancelAction({
                
                if productId == IAPManager.sharedInstance.products.VideoCapture {
                    self.videoSwitch.setOn(false, animated: true)
                }
                else {
                    self.soundSwitch.setOn(false, animated: true)
                    self.sensitivityTableCell.hidden = true
                }
            })
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    @IBAction
    func timerSliderValueChanged(sender: UISlider) {
        sliderValueLabel.text = String(Int(sender.value))
        NSUserDefaults.standardUserDefaults().setObject(Int(sender.value), forKey: "kTimerValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction
    func photoSwitchValueChanged(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kPhotoSwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        videoSwitch.enabled = sender.on ? false : true
    }
    
    @IBAction
    func videoSwitchValueChanged(sender: UISwitch) {
        
        let videoCaptureEnabled = IAPManager.sharedInstance.userDefaults.boolForKey("videocapture_enabled")
        
        if !videoCaptureEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.VideoCapture)
        }
        
        NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kVideoSwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        photoSwitch.enabled = sender.on ? false : true
    }
    
    @IBAction
    func delaySwitchValueChanged(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kDelaySwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction
    func soundSwitchValueChanged(sender: UISwitch) {
        
        let soundRecognitionEnabled = IAPManager.sharedInstance.userDefaults.boolForKey("soundrecognition_enabled")
        
        if !soundRecognitionEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.SoundRegonition)
        }
        
        NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kSoundSwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        sensitivityTableCell.hidden = !sender.on
    }
    
    @IBAction
    func sensitivityValueChanged(sender: UISegmentedControl) {
        NSUserDefaults.standardUserDefaults().setObject(sender.selectedSegmentIndex, forKey: "kSensitivityIndex")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
extension AlarmMenuViewController : PurchaseProtocol {
    func errorPurchase(productId: String, errorMsg: String) {
        if productId == IAPManager.sharedInstance.products.VideoCapture {
            videoSwitch.setOn(false, animated: true)
        }
        else if productId == IAPManager.sharedInstance.products.SoundRegonition {
            soundSwitch.setOn(false, animated: true)
            sensitivityTableCell.hidden = true
        }
        
        JSSAlertView().danger(self, title: "Error", text: errorMsg, buttonText:"OK")
    }
    
    func successPurchase(productId: String) {
        
    }
}
