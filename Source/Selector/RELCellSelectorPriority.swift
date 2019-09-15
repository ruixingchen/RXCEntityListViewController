//
//  RELCellSelectorPriority.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 9/5/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public struct RELCellSelectorPriority : ExpressibleByIntegerLiteral, Equatable {

    public typealias PriorityValueType = UInt16
    public typealias IntegerLiteralType = UInt16
    public typealias Stride = UInt16

    public let value: PriorityValueType

    public init(integerLiteral value: IntegerLiteralType) {
        self.value = value
    }

    public init(_ value: PriorityValueType) {
        self.value = value
    }

    public static var max: RELCellSelectorPriority {
        return 1000
    }

    public static var high: RELCellSelectorPriority {
        return 750
    }

    public static var medium: RELCellSelectorPriority {
        return 500
    }

    public static var low: RELCellSelectorPriority {
        return 250
    }

    public static func ==(lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value == rhs.value
    }

}
