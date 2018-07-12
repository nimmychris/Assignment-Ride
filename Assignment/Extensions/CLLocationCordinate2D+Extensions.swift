//
//  CLLocationCordinate2D+Extensions.swift
//  Assignment
//
//  Created by Christi John on 11/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    
    func compare(with location:CLLocationCoordinate2D) -> Bool {
        
        if self.latitude == location.latitude && self.longitude == location.longitude {
            return true
        }
        return false
    }
    
}
