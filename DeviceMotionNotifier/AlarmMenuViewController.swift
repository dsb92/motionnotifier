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
    fileprivate var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    weak var photoSwitch: UISwitch!
    
    @IBOutlet
    weak var videoSwitch: UISwitch!
    
    @IBOutlet
    weak var soundSwitch: UISwitch!

    @IBOutlet
    weak var sensitivityTableCell: UITableViewCell!
    
    @IBOutlet
    weak var sensitivitySegmentControl: UISegmentedControl!
    
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
        setupIAP()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
//        tableView.contentOffset = CGPoint(x: 0, y: -appearOffset)
//        
//        UIView.animateWithDuration(0.5, animations: {
//            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
//        })
    }
    
    fileprivate func setSettings() {
        let userDefaults = UserDefaults.standard

        let savedPhotoSwitchValue = userDefaults.bool(forKey: "kPhotoSwitchValue")
        let savedVideoSwitchValue = userDefaults.bool(forKey: "kVideoSwitchValue")
        let savedSoundSwitchValue = userDefaults.bool(forKey: "kSoundSwitchValue")
        let savedSensitivityValue = userDefaults.integer(forKey: "kSensitivityIndex")
        
        photoSwitch.setOn(savedPhotoSwitchValue, animated: false)
        videoSwitch.setOn(savedVideoSwitchValue, animated: false)
        soundSwitch.setOn(savedSoundSwitchValue, animated: false)
        
        photoSwitch.isEnabled = videoSwitch.isOn ? false : true
        videoSwitch.isEnabled = photoSwitch.isOn ? false : true
        
        sensitivityTableCell.isHidden = soundSwitch.isOn ? false : true
        sensitivitySegmentControl.selectedSegmentIndex = savedSensitivityValue
    }
    
    fileprivate func setupIAP() {
        IAPManager.sharedInstance.purchaseProtocol = self
        IAPManager.sharedInstance.vc = self
    }
    
    fileprivate func showPurchaseAlertView(_ productId : String) {
        if IAPManager.sharedInstance.canMakePayments {
            var titleString:String!
            var message:String!
            
            var buttonTexts = [String]()
            
            if IAPManager.sharedInstance.list.count == 0 {
                JSSAlertView().danger(self, title: "Error", text: "Cannot connect to Apple's server. Check your connection and try again")
                if productId == IAPManager.sharedInstance.products.VideoCapture {
                    enableVideo(false)
                }
                else if productId == IAPManager.sharedInstance.products.SoundRegonition {
                    enableSound(false)
                }
                return
            }
            // For each in-app product: display a buy button with title and price labeled and call purchase function with the product identifier as argument.
            for product in IAPManager.sharedInstance.list {
                
                // Product title
                let title = product.localizedTitle
                
                // Format the price to local currency price
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = product.priceLocale
                
                // The localized price
                let price = formatter.string(from: product.price)
                
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
            
            let alertView = JSSAlertView().show(self, title: "Store", text: message, buttonTexts: buttonTexts, color: SettingsTheme.theme01.blueColor.withAlphaComponent(0.7))
            
            alertView.setTitleFont("ClearSans-Bold")
            alertView.setTextFont("ClearSans")
            alertView.setButtonFont("ClearSans-Light")
            alertView.setTextTheme(.golden)
            
            alertView.addAction({
                
                IJProgressView.shared.showProgressView(self.view)
                
                if alertView.getButtonId() == 1 && productId == IAPManager.sharedInstance.products.VideoCapture {
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.VideoCapture)
                }
                else {
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.SoundRegonition)
                }
                
            })
            
            alertView.addCancelAction({
                
                if productId == IAPManager.sharedInstance.products.VideoCapture {
                    self.enableVideo(false)
                }
                else {
                    self.enableSound(false)
                }
            })
        }
        else{
            JSSAlertView().warning(self, title: "You're not authorized to make payments!")
        }
    }
    
    fileprivate func enableVideo(_ enable: Bool) {
        videoSwitch.setOn(enable, animated: true)
        photoSwitch.isEnabled = !enable
        
        UserDefaults.standard.set(enable, forKey: "kVideoSwitchValue")
        UserDefaults.standard.synchronize()
    }
    
    fileprivate func enableSound(_ enable: Bool) {
        soundSwitch.setOn(enable, animated: true)
        sensitivityTableCell.isHidden = !enable
        
        UserDefaults.standard.set(enable, forKey: "kSoundSwitchValue")
        UserDefaults.standard.synchronize()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    @IBAction
    func photoSwitchValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "kPhotoSwitchValue")
        UserDefaults.standard.synchronize()
        
        videoSwitch.isEnabled = sender.isOn ? false : true
    }
    
    @IBAction
    func videoSwitchValueChanged(_ sender: UISwitch) {
        
        let videoCaptureEnabled = IAPManager.sharedInstance.userDefaults.bool(forKey: "videocapture_enabled")
        
        if !videoCaptureEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.VideoCapture)
        }
        else {
            UserDefaults.standard.set(sender.isOn, forKey: "kVideoSwitchValue")
            UserDefaults.standard.synchronize()
            
            photoSwitch.isEnabled = sender.isOn ? false : true
        }
    }
    
    @IBAction
    func soundSwitchValueChanged(_ sender: UISwitch) {
        
        let soundRecognitionEnabled = IAPManager.sharedInstance.userDefaults.bool(forKey: "soundrecognition_enabled")
        
        if !soundRecognitionEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.SoundRegonition)
        }
        else{
            UserDefaults.standard.set(sender.isOn, forKey: "kSoundSwitchValue")
            UserDefaults.standard.synchronize()
            
            sensitivityTableCell.isHidden = !sender.isOn
        }
    }
    
    @IBAction
    func sensitivityValueChanged(_ sender: UISegmentedControl) {
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "kSensitivityIndex")
        UserDefaults.standard.synchronize()
    }
}
extension AlarmMenuViewController : PurchaseProtocol {
    func errorPurchase(_ productId: String, errorMsg: String) {
        if productId == IAPManager.sharedInstance.products.VideoCapture {
            enableVideo(false)
        }
        else if productId == IAPManager.sharedInstance.products.SoundRegonition {
            enableSound(false)
        }
        
        IJProgressView.shared.hideProgressView()
    }
    
    func successPurchase(_ productId: String) {
        if productId == IAPManager.sharedInstance.products.VideoCapture {
            enableVideo(true)
        }
        else if productId == IAPManager.sharedInstance.products.SoundRegonition {
            enableSound(true)
        }
        
        IJProgressView.shared.hideProgressView()
    }
}
