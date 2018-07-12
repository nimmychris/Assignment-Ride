//
//  RootViewController.swift
//  Assignment
//
//  Created by Christi John on 08/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import UIKit
import InteractiveSideMenu

class RootViewController: MenuContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuViewController = self.storyboard!.instantiateViewController(withIdentifier: "menuVC") as! MenuViewController
        contentViewControllers = [self.storyboard!.instantiateViewController(withIdentifier: "rideVC")]
        selectContentViewController(contentViewControllers.first!)
    }
    
    
    
    
}
