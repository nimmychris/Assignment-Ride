//
//  SideMenuViewController.swift
//  Assignment
//
//  Created by Christi John on 11/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import Foundation
import InteractiveSideMenu

class MenuItemCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
}

class SideMenuViewController: MenuViewController {
    
    @IBOutlet weak var tableView: UITableView!

    let menuOptions = ["Plan Your Journey", "Your Trips", "Payment", "Help", "Settings"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 1))
        tableView.tableFooterView = footer
    }
}

extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell") as! MenuItemCell
        cell.titleLabel?.text = menuOptions[indexPath.row]
        return cell
    }
}

extension SideMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
