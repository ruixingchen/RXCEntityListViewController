//
//  RELCellSelectorPriority.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 9/5/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public struct RELCellSelectorPriority: ExpressibleByIntegerLiteral, Strideable, Equatable, Comparable {

    public typealias ValueType = Int16
    public typealias Stride = Int16
    public typealias IntegerLiteralType = Int16
    
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
        return RELCellSelectorPriority(ValueType.max)
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

    public static var min: RELCellSelectorPriority {
        return RELCellSelectorPriority(ValueType.min)
    }

    public let value: ValueType

    public init(_ value: ValueType) {
        self.value = value
    }

    public init(integerLiteral value: RELCellSelectorPriority.ValueType) {
        self.value = value
    }

    public func advanced(by n: RELCellSelectorPriority.Stride) -> RELCellSelectorPriority {
        return RELCellSelectorPriority(self.value + n)
    }

    public func distance(to other: RELCellSelectorPriority) -> RELCellSelectorPriority.Stride {
        return other.value - self.value
    }

}
