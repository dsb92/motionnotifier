//
//  SettingsViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import MultipeerConnectivity

private var tableViewOffset: CGFloat = UIScreen.mainScreen().bounds.height < 600 ? 215 : 225
private let beforeAppearOffset: CGFloat = 400

class MainRegisterSettingsViewController: UITableViewController {

    @IBOutlet
    private var backgroundHolder: UIView!
    
    @IBOutlet
    private weak var backgroundImageView: UIImageView!
    
    @IBOutlet
    private weak var backgroundHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundHolderTop: NSLayoutConstraint!
    
    @IBOutlet
    private weak var backgroundWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet
    private weak var silentSwitch: UISwitch!
    
    @IBOutlet
    private var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    private var cellTextFields: [UITextField]!
    
    @IBOutlet
    weak var nameOfDeviceToMonitorTextField: UITextField!
    
    @IBOutlet
    weak var nameOfDeviceToNotifyTextField: UITextField!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var isAdvertising: Bool!
    
    var theme: SettingsTheme! {
        didSet {
            backgroundImageView.image = theme.topImage
            tableView.separatorColor = theme.separatorColor
            backgroundHolder.backgroundColor = theme.backgroundColor
            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }
            for label in cellTextFields { label.textColor = theme.cellTextFieldColor }
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            tableViewOffset += 150
            backgroundHolderTop.constant = 60
        }
        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -beforeAppearOffset)
        
        UIView.animateWithDuration(0.5, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
        })
        
        self.nameOfDeviceToNotifyTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameOfDeviceToMonitorTextField.delegate = self
        nameOfDeviceToNotifyTextField.delegate = self
        
        theme = SettingsTheme.theme01
        tableView.backgroundView = backgroundHolder
        
        if NSUserDefaults.standardUserDefaults().objectForKey("kSilentValue") == nil {
            setDefaults()
        }
        
        setSettings()
        setupDeviceNames()
    }
    
    private func setDefaults() {
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "kSilentValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func setSettings() {
        let savedSilentValue = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        silentSwitch.setOn(savedSilentValue, animated: false)
    }
    
    private func setupDeviceNames() {
        self.nameOfDeviceToMonitorTextField.text = UIDevice.currentDevice().name
        
        appDelegate.mpcManager.delegate = self
        
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
        
        isAdvertising = true

    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        backgroundHeightConstraint.constant = max(navigationController!.navigationBar.bounds.height + scrollView.contentInset.top - scrollView.contentOffset.y, 0)
        backgroundWidthConstraint.constant = navigationController!.navigationBar.bounds.height - scrollView.contentInset.top - scrollView.contentOffset.y * 0.8
    }
    
    @IBAction
    private func silentValueChanged(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setObject(sender.on, forKey: "kSilentValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

extension MainRegisterSettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameOfDeviceToMonitorTextField {
            nameOfDeviceToNotifyTextField.becomeFirstResponder()
        }
        if textField == nameOfDeviceToNotifyTextField {
            nameOfDeviceToNotifyTextField.resignFirstResponder()
        }
        
        return true
    }
}

extension MainRegisterSettingsViewController : MPCManagerDelegate {
    // MARK: MPCManagerDelegate method implementation
    
    func foundPeer() {
        
        let peers = appDelegate.mpcManager.foundPeers
        var buttonTexts = [String]()
 
        for peer in peers {
            if !buttonTexts.contains(peer.displayName) {
                buttonTexts.append(peer.displayName)
            }
        }
        
        buttonTexts.append(NSLocalizedString("Cancel", comment: "Cancel"))
        
        let alertView = JSSAlertView().show(self, title: "Nearby device(s)", text: "Device(s)", buttonTexts: buttonTexts, color: UIColor.blackColor().colorWithAlphaComponent(0.7))
        
        alertView.setTitleFont("ClearSans-Bold")
        alertView.setTextFont("ClearSans")
        alertView.setButtonFont("ClearSans-Light")
        alertView.setTextTheme(.Golden)
        
        alertView.addAction({
            let peerIndex = alertView.getButtonId()-1
            self.nameOfDeviceToNotifyTextField.text = peers[peerIndex].displayName
        })
        
        alertView.addCancelAction({
            
            
        })
    }
    
    
    func lostPeer() {
        
    }
//
//    func invitationWasReceived(fromPeer: String) {
//        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
//        
//        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
//            self.appDelegate.mpcManager.invitationHandler(true, self.appDelegate.mpcManager.session)
//        }
//        
//        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
//            self.appDelegate.mpcManager.invitationHandler(false, self.appDelegate.mpcManager.session)
//        }
//        
//        alert.addAction(acceptAction)
//        alert.addAction(declineAction)
//        
//        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
//            self.presentViewController(alert, animated: true, completion: nil)
//        }
//    }
//    
//    
//    func connectedWithPeer(peerID: MCPeerID) {
//        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
//            self.performSegueWithIdentifier("idSegueChat", sender: self)
//        }
//    }

}
