//
//  SettingsViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import MultipeerConnectivity

private var tableViewOffset: CGFloat = UIScreen.main.bounds.height < 600 ? 215 : 225
private let beforeAppearOffset: CGFloat = 400

class MainRegisterSettingsViewController: UITableViewController {

    @IBOutlet
    fileprivate var backgroundHolder: UIView!
    
    @IBOutlet
    fileprivate weak var backgroundImageView: UIImageView!
    
    @IBOutlet
    fileprivate weak var backgroundHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundHolderTop: NSLayoutConstraint!
    
    @IBOutlet
    fileprivate weak var backgroundWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet
    fileprivate weak var silentSwitch: UISwitch!
    
    @IBOutlet
    fileprivate var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    fileprivate var cellTextFields: [UITextField]!
    
    @IBOutlet
    weak var nameOfDeviceToMonitorTextField: UITextField!
    
    @IBOutlet
    weak var nameOfDeviceToNotifyTextField: UITextField!
    
    @IBOutlet
    weak var continueWithout: UIButton!
    
    @IBOutlet
    weak var findingDeviceSpinner: UIActivityIndicatorView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            tableViewOffset = UIScreen.main.bounds.height < 600 ? (215+150) : (225+150)
            backgroundHolderTop.constant = 60
        }
        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -beforeAppearOffset)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
        })
        
        setSettings()
        setupDeviceNames()
        
        let tapGestureImage = UITapGestureRecognizer(target: self, action: #selector(MainRegisterSettingsViewController.bluetoothImageTapped))
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.addGestureRecognizer(tapGestureImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameOfDeviceToMonitorTextField.delegate = self
        nameOfDeviceToNotifyTextField.delegate = self
        
        theme = SettingsTheme.theme01
        tableView.backgroundView = backgroundHolder
        
        if UserDefaults.standard.object(forKey: "kSilentValue") == nil {
            setDefaults()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainRegisterSettingsViewController.menuToggled(_:)), name: NSNotification.Name(rawValue: "menuToggled"), object: nil)
        
        self.nameOfDeviceToNotifyTextField.becomeFirstResponder()
    }
    
    fileprivate func setDefaults() {
        UserDefaults.standard.set(false, forKey: "kSilentValue")
        UserDefaults.standard.synchronize()
    }
    
    fileprivate func setSettings() {
        let savedSilentValue = UserDefaults.standard.bool(forKey: "kSilentValue")
        
        silentSwitch.setOn(savedSilentValue, animated: false)
    }
    
    fileprivate func setupDeviceNames() {
        
        self.nameOfDeviceToMonitorTextField.text = UIDevice.current.name
        
        let deviceToNotify = UserDefaults.standard.string(forKey: "kdeviceToNotiy")
        
        if (deviceToNotify != nil){
            self.nameOfDeviceToNotifyTextField.text = deviceToNotify
        }
        else{
            findingDeviceSpinner.startAnimating()
        }
        
        appDelegate.mpcManager.delegate = self
        startBrowsingPeers()
    }
    
    func menuToggled(_ notification: Notification){
        if notification.name.rawValue == "menuToggled" {
            let userInfo = notification.userInfo
            let isOpen = userInfo!["open"] as! Bool
            menuOpen = isOpen
        }
    }
    
    func startBrowsingPeers() {
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
        
        let url = Bundle.main.url(forResource: "bluetooth", withExtension: "gif")
        backgroundImageView.image = UIImage.animatedImage(withAnimatedGIFURL: url!)
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
        
        let alertView = JSSAlertView().show(self, title: "Bluetooth", text: "Nearby device(s)", buttonTexts: buttonTexts, color: SettingsTheme.theme01.blueColor.withAlphaComponent(0.7), iconImage: UIImage(named: "bluetooth"))
        
        alertView.setTitleFont("ClearSans-Bold")
        alertView.setTextFont("ClearSans")
        alertView.setButtonFont("ClearSans-Light")
        alertView.setTextTheme(.golden)
        
        alertView.addAction({
            self.findingDeviceSpinner.stopAnimating()
            let peerIndex = alertView.getButtonId()
            let deviceNameFound = peers[peerIndex-1].displayName
            self.nameOfDeviceToNotifyTextField.text = deviceNameFound
            
            UserDefaults.standard.set(deviceNameFound, forKey: "kdeviceToNotiy")
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        backgroundHeightConstraint.constant = max(navigationController!.navigationBar.bounds.height + scrollView.contentInset.top - scrollView.contentOffset.y, 0)
        backgroundWidthConstraint.constant = navigationController!.navigationBar.bounds.height - scrollView.contentInset.top - scrollView.contentOffset.y * 0.8
    }
    
    @IBAction
    fileprivate func silentValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "kSilentValue")
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func continueWithoutAction(_ sender: UIButton) {
        let alarmSB = UIStoryboard(name: "Alarm", bundle: nil)
        let initialVC = alarmSB.instantiateInitialViewController()
        self.present(initialVC!, animated: true, completion: nil)
    }
}

extension MainRegisterSettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
}
