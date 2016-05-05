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
    
    @IBOutlet
    weak var continueWithout: UIButton!
    
    @IBOutlet
    weak var findingDeviceSpinner: UIActivityIndicatorView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var blueToothOn: Bool = true
    
    var menuOpen: Bool = false {
        didSet{
            if !menuOpen {
                peerFoundHandler()
            }
        }
    }
    
    var theme: SettingsTheme! {
        didSet {
            tableView.separatorColor = theme.separatorColor
            backgroundHolder.backgroundColor = theme.blueColor
            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }
            for label in cellTextFields { label.textColor = theme.cellTextFieldColor }
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            tableViewOffset = UIScreen.mainScreen().bounds.height < 600 ? (215+150) : (225+150)
            backgroundHolderTop.constant = 60
        }
        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -beforeAppearOffset)
        
        UIView.animateWithDuration(0.5, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
        })
        
        setSettings()
        setupDeviceNames()
        
        let tapGestureImage = UITapGestureRecognizer(target: self, action: "bluetoothImageTapped")
        backgroundImageView.userInteractionEnabled = true
        backgroundImageView.addGestureRecognizer(tapGestureImage)
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "menuToggled:", name: "menuToggled", object: nil)
        
        self.nameOfDeviceToNotifyTextField.becomeFirstResponder()
    }
    
    private func setDefaults() {
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "kSilentValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func setSettings() {
        let savedSilentValue = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        silentSwitch.setOn(savedSilentValue, animated: false)
        
        let deviceRegistered = NSUserDefaults.standardUserDefaults().boolForKey("kdeviceRegistered")
        
        continueWithout.enabled = !deviceRegistered
    }
    
    private func setupDeviceNames() {
        
        self.nameOfDeviceToMonitorTextField.text = UIDevice.currentDevice().name
        
        let deviceToNotify = NSUserDefaults.standardUserDefaults().stringForKey("kdeviceToNotiy")
        
        if (deviceToNotify != nil){
            self.nameOfDeviceToNotifyTextField.text = deviceToNotify
        }
        else{
            findingDeviceSpinner.startAnimating()
        }
        
        appDelegate.mpcManager.delegate = self
        startBrowsingPeers()
    }
    
    func menuToggled(notification: NSNotification){
        if notification.name == "menuToggled" {
            let userInfo = notification.userInfo
            let isOpen = userInfo!["open"] as! Bool
            menuOpen = isOpen
        }
    }
    
    func startBrowsingPeers() {
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
        
        let url = NSBundle.mainBundle().URLForResource("bluetooth", withExtension: "gif")
        backgroundImageView.image = UIImage.animatedImageWithAnimatedGIFURL(url!)
    }
    
    func stopBrowsingPeers() {
        appDelegate.mpcManager.browser.stopBrowsingForPeers()
        appDelegate.mpcManager.advertiser.stopAdvertisingPeer()
        
        backgroundImageView.image = UIImage(named: "bluetooth-off")
    }
    
    func peerFoundHandler() {

        let peers = appDelegate.mpcManager.foundPeers
        
        // If there are any peers
        if peers.count == 0 { return }
        
        // Prevent show peers dialog to many times
        stopBrowsingPeers()
        
        findingDeviceSpinner.startAnimating()
        var buttonTexts = [String]()
        for peer in peers {
            if !buttonTexts.contains(peer.displayName) {
                buttonTexts.append(peer.displayName)
            }
        }
        
        buttonTexts.append(NSLocalizedString("Cancel", comment: "Cancel"))
        
        let alertView = JSSAlertView().show(self, title: "Bluetooth", text: "Nearby device(s)", buttonTexts: buttonTexts, color: SettingsTheme.theme01.blueColor.colorWithAlphaComponent(0.7), iconImage: UIImage(named: "bluetooth"))
        
        alertView.setTitleFont("ClearSans-Bold")
        alertView.setTextFont("ClearSans")
        alertView.setButtonFont("ClearSans-Light")
        alertView.setTextTheme(.Golden)
        
        alertView.addAction({
            self.findingDeviceSpinner.stopAnimating()
            let peerIndex = alertView.getButtonId()
            let deviceNameFound = peers[peerIndex-1].displayName
            self.nameOfDeviceToNotifyTextField.text = deviceNameFound
            
            NSUserDefaults.standardUserDefaults().setObject(deviceNameFound, forKey: "kdeviceToNotiy")
            // Dialog closed, you can start browsing again
            self.startBrowsingPeers()
        })
        
        alertView.addCancelAction({
            self.findingDeviceSpinner.stopAnimating()
            // Dialog closed, you can start browsing again
            self.startBrowsingPeers()
        })

    }
    
    func bluetoothImageTapped(){
        blueToothOn = !blueToothOn
        
        if blueToothOn {
            startBrowsingPeers()
        }
        else{
            stopBrowsingPeers()
        }
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
    
    @IBAction func continueWithoutAction(sender: UIButton) {
        let alarmSB = UIStoryboard(name: "Alarm", bundle: nil)
        let initialVC = alarmSB.instantiateInitialViewController()
        self.presentViewController(initialVC!, animated: true, completion: nil)
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
        
        if !menuOpen {
            peerFoundHandler()
        }
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
