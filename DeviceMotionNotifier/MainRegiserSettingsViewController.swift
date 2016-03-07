//
//  SettingsViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 05/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

private let tableViewOffset: CGFloat = UIScreen.mainScreen().bounds.height < 600 ? 215 : 225
private let beforeAppearOffset: CGFloat = 400

class MainRegisterSettingsViewController: UITableViewController {

    @IBOutlet
    private var backgroundHolder: UIView!
    
    @IBOutlet
    private weak var backgroundImageView: UIImageView!
    
    @IBOutlet
    private weak var backgroundHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet
    private weak var backgroundWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet
    private weak var silentSwitch: UISwitch!
    
    @IBOutlet
    private var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    private var cellTextFields: [UITextField]!
    
    @IBOutlet
    weak var nameOfDeviceTextField: UITextField!
    
    @IBOutlet
    weak var nameOfDeviceToMonitorTextField: UITextField!
    
    var theme: SettingsTheme! {
        didSet {
            //backgroundImageView.image = theme.topImage
            tableView.separatorColor = theme.separatorColor
            backgroundHolder.backgroundColor = theme.backgroundColor
            for label in cellTitleLabels { label.textColor = theme.cellTitleColor }
            for label in cellTextFields { label.textColor = theme.cellTextFieldColor }
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -beforeAppearOffset)
        
        UIView.animateWithDuration(0.5, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -tableViewOffset)
        })
        
        self.nameOfDeviceTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameOfDeviceTextField.delegate = self
        nameOfDeviceToMonitorTextField.delegate = self
        
        theme = SettingsTheme.theme01
        tableView.backgroundView = backgroundHolder
        
        if NSUserDefaults.standardUserDefaults().objectForKey("kSilentValue") == nil {
            setDefaults()
        }
        
        setSettings()
    }
    
    private func setDefaults() {
        NSUserDefaults.standardUserDefaults().setObject(false, forKey: "kSilentValue")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func setSettings() {
        let savedSilentValue = NSUserDefaults.standardUserDefaults().boolForKey("kSilentValue")
        
        silentSwitch.setOn(savedSilentValue, animated: false)
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
        if textField == nameOfDeviceTextField {
            nameOfDeviceToMonitorTextField.becomeFirstResponder()
        }
        if textField == nameOfDeviceToMonitorTextField {
            nameOfDeviceToMonitorTextField.resignFirstResponder()
        }
        
        return true
    }
}
