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

class SettingsViewController: UITableViewController {

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
    
    @IBAction
    private func silentValueChanged(sender: AnyObject) {
        let center = self.tableView.convertPoint(silentSwitch.center, fromView: silentSwitch.superview)

    }
    
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
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = theme.backgroundColor
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        backgroundHeightConstraint.constant = max(navigationController!.navigationBar.bounds.height + scrollView.contentInset.top - scrollView.contentOffset.y, 0)
        backgroundWidthConstraint.constant = navigationController!.navigationBar.bounds.height - scrollView.contentInset.top - scrollView.contentOffset.y * 0.8
    }
}

extension SettingsViewController : UITextFieldDelegate {
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
