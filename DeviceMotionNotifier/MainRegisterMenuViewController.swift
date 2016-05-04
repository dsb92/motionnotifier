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
    private var cellTitleLabels: [UILabel]!
    
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
            restorePurchasesButton.setTitleColor(theme.blackColor, forState: UIControlState.Normal)
            aboutButton.borderColor = theme.blueColor
            aboutButton.setTitleColor(theme.blackColor, forState: UIControlState.Normal)
            contactButton.borderColor = theme.blueColor
            contactButton.setTitleColor(theme.blackColor, forState: UIControlState.Normal)
            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }
            
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        theme = SettingsTheme.theme01
        
        setLayout()
        setSettings()
    }
    
    private func setLayout() {
        self.logoImage.clipsToBounds = true
        self.logoImage.layer.cornerRadius = self.logoImage.frame.size.width/2
    }
    
    private func setSettings() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let savedRemoveAdsValue = userDefaults.boolForKey("kRemoveAdsSwitchValue")
        
        removeAdsSwitch.setOn(savedRemoveAdsValue, animated: false)
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
                
                if productId == IAPManager.sharedInstance.products.RemoveAds {
                    if product.productIdentifier == IAPManager.sharedInstance.products.RemoveAds {
                        
                        message = "Remove Ads"
                        
                        buttonTexts.append(titleString)
                        
                        break
                    }
                    
                }
            }
            
            buttonTexts.append(NSLocalizedString("Cancel", comment: "Cancel"))
            
            let alertView = JSSAlertView().show(self, title: "Store", text: message, buttonTexts: buttonTexts, color: SettingsTheme.theme01.blueColor.colorWithAlphaComponent(0.7))
            
            alertView.setTitleFont("ClearSans-Bold")
            alertView.setTextFont("ClearSans")
            alertView.setButtonFont("ClearSans-Light")
            alertView.setTextTheme(.Golden)
            
            alertView.addAction({
                if alertView.getButtonId() == 1 && productId == IAPManager.sharedInstance.products.RemoveAds {
                    IAPManager.sharedInstance.purchase(IAPManager.sharedInstance.products.RemoveAds, purchaseProtocol: self)
                }
            })
            
            alertView.addCancelAction({
                
                if productId == IAPManager.sharedInstance.products.RemoveAds {
                    self.enableAds(true)
                }
            })
        }
    }
    
    private func enableAds(enable: Bool) {
        removeAdsSwitch.setOn(!enable, animated: true)
        
        NSUserDefaults.standardUserDefaults().setObject(!enable, forKey: "kRemoveAdsSwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        NSNotificationCenter().postNotificationName("onAdsEnabled", object: nil)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    @IBAction
    func removeAdsSwitchValueChanged(sender: UISwitch) {
        
        let removeAdsEnabled = IAPManager.sharedInstance.userDefaults.boolForKey("removeads_enabled")
        
        if !removeAdsEnabled {
            showPurchaseAlertView(IAPManager.sharedInstance.products.RemoveAds)
        }
        else {
            NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kRemoveAdsSwitchValue")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            NSNotificationCenter().postNotificationName("onAdsEnabled", object: nil)
        }
    }
    
    @IBAction
    func restorePurchasesButtonAction(sender: MonitorButton) {
        sender.animateTouchUpInside { 
            IAPManager.sharedInstance.restorePurchases()
        }
    }
    
    @IBAction
    func contactButtonAction(sender: MonitorButton) {
        sender.animateTouchUpInside { 
            
        }
    }
    
    @IBAction
    func aboutButtonAction(sender: MonitorButton) {
        sender.animateTouchUpInside {
            // Show welcome screen
            let welcomeVC = APPViewController(nibName: "APPViewController", bundle: nil);
            self.presentViewController(welcomeVC, animated: true, completion: nil)
        }
    }
}

extension MainRegisterMenuViewController : PurchaseProtocol {
    func errorPurchase(productId: String, errorMsg: String) {
        if productId == IAPManager.sharedInstance.products.RemoveAds {
            enableAds(true)
        }
        
        JSSAlertView().danger(self, title: "Error", text: errorMsg, buttonText:"OK")
    }
    
    func successPurchase(productId: String) {
        var productMessage : String!
        if productId == IAPManager.sharedInstance.products.RemoveAds {
            enableAds(false)
            productMessage = "Ads are now removed from the app!"
        }
        
        JSSAlertView().success(self, title: "Success", text: productMessage, buttonText:"OK")
    }
}
