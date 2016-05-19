//
//  FDDisplayModeAdditions.swift
//  FruitzOfDojo
//
//  Created by C.W. Betts on 5/18/16.
//  Copyright © 2016 C.W. Betts. All rights reserved.
//

import Foundation
import FruitzOfDojo

extension FDDisplayMode: Comparable {
    
}

public func ==(lhs: FDDisplayMode, rhs: FDDisplayMode) -> Bool {
    return lhs.isEqualTo(rhs)
}

public func <(lhs:FDDisplayMode, rhs: FDDisplayMode) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}

public func >(lhs:FDDisplayMode, rhs: FDDisplayMode) -> Bool {
    return lhs.compare(rhs) == .OrderedDescending
}
