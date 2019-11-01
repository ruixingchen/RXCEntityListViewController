//
//  RELCellSelectorPriority.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 9/5/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public struct RELCellSelectorPriority: ExpressibleByIntegerLiteral, Equatable, Comparable {
    
    public static func < (lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value < rhs.value
    }

    public static func <= (lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value <= rhs.value
    }

    public static func > (lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value > rhs.value
    }

    public static func >= (lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value >= rhs.value
    }

    public static func == (lhs: RELCellSelectorPriority, rhs: RELCellSelectorPriority) -> Bool {
        return lhs.value == rhs.value
    }

    public static var max: RELCellSelectorPriority {
        return RELCellSelectorPriority(IntegerLiteralType.max)
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

    public static var lowest: RELCellSelectorPriority {
        return RELCellSelectorPriority(IntegerLiteralType.min)
    }

    public typealias ValueType = UInt16
    public typealias IntegerLiteralType = UInt16

    public let value: ValueType

    public init(integerLiteral value: Self.IntegerLiteralType) {
        self.value = value
    }

    public init(_ value: ValueType) {
        self.value = value
    }

}
