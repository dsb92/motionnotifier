//
//  MainRegisterMenuViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 11/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

class MainRegisterMenuViewController: UITableViewController {
    
    @IBOutlet
    fileprivate var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    weak var removeAdsSwitch: UISwitch!
    
    @IBOutlet
    weak var restorePurchasesButton: MonitorButton!
    
    @IBOutlet
    weak var contactButton: MonitorButton!
    
    @IBOutlet
    weak var aboutButton: MonitorButton!
    
    @IBOutlet
    weak var logoImage: UIImageView!
    
    var theme: SettingsTheme! {
        didSet {
            tableView.separatorColor = theme.separatorColor
            tableView.backgroundColor = theme.backgroundColor
            restorePurchasesButton.borderColor = theme.blueColor
            restorePurchasesButton.setTitleColor(theme.blackColor, for: UIControlState())
            aboutButton.borderColor = theme.blueColor
            aboutButton.setTitleColor(theme.blackColor, for: UIControlState())
            contactButton.borderColor = theme.blueColor
            contactButton.setTitleColor(theme.blackColor, for: UIControlState())
            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }
            
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let userInfo = ["open" : true]
        NotificationCenter.default.post(name: Notification.Name(rawValue: "menuToggled"), object: self, userInfo: userInfo)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let userInfo = ["open" : false]
        NotificationCenter.default.post(name: Notification.Name(rawValue: "menuToggled"), object: self, userInfo: userInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        theme = SettingsTheme.theme01
        setLayout()
        setSettings()
        setupIAP()
    }
    
    fileprivate func setLayout() {
        self.logoImage.clipsToBounds = true
        self.logoImage.layer.cornerRadius = self.logoImage.frame.size.width/2
    }
    
    fileprivate func setSettings() {
        let userDefaults = UserDefaults.standard
        
        let savedRemoveAdsValue = userDefaults.bool(forKey: "kRemoveAdsSwitchValue")
        
        removeAdsSwitch.setOn(savedRemoveAdsValue, animated: false)
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
                self.enableAds(true)
                return;
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
                
                if productId == IAPManager.sharedInstance.products.RemoveAds {
                    if product.productIdentifier == IAPManager.sharedInstance.products.RemoveAds {
                        
                        message = "Remove Ads"
                        
                        buttonTexts.append(titleString)
                        
                        break
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
                if alertView.getButtonId() == 1 && productId == IAPManager.sharedInstance.products.RemoveAds {
                    IJProgressView.shared.showProgressView(self.view)
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.RemoveAds)
                }
            })
            
            alertView.addCancelAction({
                
                if productId == IAPManager.sharedInstance.products.RemoveAds {
                    self.enableAds(true)
                }
            })
        }
        else{
            JSSAlertView().warning(self, title: "You're not authorized to make payments!")
        }
    }
    
    fileprivate func enableAds(_ enable: Bool) {
        removeAdsSwitch.setOn(!enable, animated: true)
        
        UserDefaults.standard.set(!enable, forKey: "kRemoveAdsSwitchValue")
        UserDefaults.standard.synchronize()
        
        NotificationCenter().post(name: Notification.Name(rawValue: "onAdsEnabled"), object: nil)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    @IBAction
    func removeAdsSwitchValueChanged(_ sender: UISwitch) {
        
        let removeAdsEnabled = IAPManager.sharedInstance.userDefaults.bool(forKey: "removeads_enabled")
        
        if !removeAdsEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.RemoveAds)
        }
        else {
            UserDefaults.standard.set(sender.isOn, forKey: "kRemoveAdsSwitchValue")
            UserDefaults.standard.synchronize()
            
            NotificationCenter().post(name: Notification.Name(rawValue: "onAdsEnabled"), object: nil)
        }
    }
    
    @IBAction
    func restorePurchasesButtonAction(_ sender: MonitorButton) {
        sender.animateTouchUpInside {
            IJProgressView.shared.showProgressView(self.view)
            IAPManager.sharedInstance.restorePurchases()
        }
    }
    
    @IBAction
    func contactButtonAction(_ sender: MonitorButton) {
        sender.animateTouchUpInside {
            UIApplication.shared.openURL(URL(string: kAboutUrl)!)
        }
    }
    
    @IBAction
    func aboutButtonAction(_ sender: MonitorButton) {
        sender.animateTouchUpInside {
            // Show welcome screen
            let welcomeVC = APPViewController(nibName: "APPViewController", bundle: nil);
            self.present(welcomeVC, animated: true, completion: nil)
        }
    }
}

extension MainRegisterMenuViewController : PurchaseProtocol {
    func errorPurchase(_ productId: String, errorMsg: String) {
        if productId == IAPManager.sharedInstance.products.RemoveAds {
            enableAds(true)
        }
        
        IJProgressView.shared.hideProgressView()
    }
    
    func successPurchase(_ productId: String) {
        if productId == IAPManager.sharedInstance.products.RemoveAds {
            enableAds(false)
        }
        
        IJProgressView.shared.hideProgressView()
    }
}
