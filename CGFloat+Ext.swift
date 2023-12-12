//
//  CGFloat+Ext.swift
//  MantisDebug
//
//  Created by Bianca Silvestro  on 11/12/23.
//

import CoreGraphics

extension CGFloat{
    
    static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
    }
    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return CGFloat.random() * (max - min ) + min
    }
    
    
}
