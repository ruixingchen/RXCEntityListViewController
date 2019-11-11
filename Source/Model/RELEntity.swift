//
//  RELEntity.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/18/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
#if canImport(RXCDiffArray)
import RXCDiffArray
#endif

///表示一个
public protocol RELEntityProtocol {

}

#if canImport(RXCDiffArray)
public protocol RELRowEntityProtocol: RELEntityProtocol, RDADiffableRowElementProtocol {

}
#else
public protocol RELRowEntityProtocol: RELEntityProtocol {

}
#endif

///将RELEntityProtocol包装成一个类
open class RELRowEntityProtocolWrapper: RELRowEntityProtocol {

    open var entity:RELRowEntityProtocol

    public var rda_diffIdentifier: AnyHashable {return self.entity.rda_diffIdentifier}

    public init(entity:RELRowEntityProtocol) {
        self.entity = entity
    }

}
