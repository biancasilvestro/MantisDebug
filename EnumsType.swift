//
//  EnumsType.swift
//  MantisDebug
//
//  Created by Bianca Silvestro  on 11/12/23.
//

import Foundation

//group of related values, sono i vari casi che is possono presentare
enum SequenceType: Int{
    case OneNoBomb, One, TwoWithOneBomb, Two, Three, Four, Five, Six
}


// non c'è, c'è, normale random
enum ForceBomb {
    case Never, Always, Defaults
}
