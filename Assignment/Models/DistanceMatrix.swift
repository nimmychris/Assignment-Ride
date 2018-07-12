//
//  DistanceMatrix.swift
//  Assignment
//
//  Created by Christi John on 11/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import Foundation

class DistanceMatrix: NSObject {
    
    var distanceText: String?
    var distanceValue: Float?
    var durationText: String?
    var durationValue: Float?
    
    public init(response: [String: AnyObject]) {
        guard let rows = response["rows"] as? [[String: AnyObject]] else {
            return
        }
        
        if let row = rows.first,
            let elements = row["elements"] as? [[String: AnyObject]] {
            
            let element = elements.first
            
            if let distance = element?["distance"] {
                distanceText = distance["text"] as? String
                distanceValue = distance["value"] as? Float
            }
            
            durationText = element?["duration"]?["text"] as? String
            durationValue = element?["duration"]?["value"] as? Float
        }
    }
}

