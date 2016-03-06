//
//  MenuViewController.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 06/03/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit

private let tableViewOffset: CGFloat = UIScreen.mainScreen().bounds.height < 600 ? 215 : 225
private let appearOffset: CGFloat = 200

class AlarmMenuViewController: UITableViewController {

    @IBOutlet
    private var cellTitleLabels: [UILabel]!
    
    @IBOutlet
    weak var sliderValueLabel: UILabel!
    
    @IBOutlet
    weak var photoSwitch: UISwitch!
    
    @IBOutlet
    weak var videoSwitch: UISwitch!
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.contentInset = UIEdgeInsets(top: tableViewOffset, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -appearOffset)
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
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: "kVideoSwitchValue")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        photoSwitch.enabled = sender.on ? false : true
    }
}
