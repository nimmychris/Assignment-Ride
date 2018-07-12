//
//  MapIconView.swift
//  Assignment
//
//  Created by Christi John on 10/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import UIKit

class MapIconView: UIView {
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var holderView: UIView!
    @IBOutlet weak var durationLabelWidthConstriant: NSLayoutConstraint!
    
    override func awakeFromNib() {
        holderView.addShadow(radius: 5.0, opacity: 1.0)
    }
    
    /// This method is used to update duration label, once we get Distance matrix API response.
    /// durationText has space between duration and its unit.
    /// We have to make value and unit in separate lines

    func updateDurationLabel(duration: String) {
        var duration = duration
        duration = duration.replacingOccurrences(of: " ", with: "\n")
        self.durationLabel.text = duration.uppercased()
        durationLabelWidthConstriant.constant = 35.0
        self.layoutIfNeeded()
    }
    
}
