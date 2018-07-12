//
//  UIViewExtension.swift
//  Assignment
//
//  Created by Christi John on 08/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import UIKit

@IBDesignable extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = (newValue > 0) ? true : false
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var needDashedBorder: Bool {
        set{
            if newValue == true {
                addDashedBorder()
            }
        }
        get {
            return true
        }
    }
    
    
    
}


extension UIView {
    
    /// This UIView extension is used to add shadow under UIView instance.
    ///
    func addShadow(radius: CGFloat, opacity: Float) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shadowOffset = .zero
        self.layer.masksToBounds = false
    }
    
    func addDashedBorder() {
        //Create a CAShapeLayer
        let shapeLayer = CAShapeLayer()
        if #available(iOS 11.0, *) {
            shapeLayer.strokeColor = UIColor(named: "microPhoneColor")!.cgColor
        } else {
            // Fallback on earlier versions
            shapeLayer.strokeColor = UIColor.microphoneColor.cgColor
        }
        shapeLayer.lineWidth = 2
        
        // passing an array with the values [2,3] sets a dash pattern that alternates between a 2-user-space-unit-long painted segment and a 3-user-space-unit-long unpainted segment
        shapeLayer.lineDashPattern = [3,3]
        
        let path = CGMutablePath()
        path.addLines(between: [CGPoint(x: 0, y: 0),
                                CGPoint(x: 0, y: self.frame.height)])
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
    }
    
    
}
