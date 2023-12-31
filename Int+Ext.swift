//
//  Int+Ext.swift
//  MantisDebug
//
//  Created by Bianca Silvestro  on 11/12/23.
//

import Foundation


extension Int {
    static func random (min: Int, max: Int) -> Int{
        assert(min < max)
        return Int(arc4random_uniform(UInt32(max - min + 1))) + min
    }
}
