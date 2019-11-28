//
//  RELCard.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
#if canImport(RXCDiffArray)
import RXCDiffArray
#endif

#if canImport(RXCDiffArray)
public protocol RELSectionCardProtocol: RDADiffableSectionElementProtocol {

    ///不采用范型, 这里直接采用Any, 后面自己做cast
    var rel_cardObjects:[Any]? {get set}

}
#else
public protocol RELSectionCardProtocol {

    ///不采用范型, 这里直接采用Any, 后面自己做cast
    var rel_cardObjects:[Any]? {get set}

}
#endif

///将RELCardProtocol包装成一个类
open class RELSectionCardProtocolWrapper: RELSectionCardProtocol {

    open var card:RELSectionCardProtocol

    open var rel_cardObjects: [Any]? {
        get {return self.card.rel_cardObjects}
        set {self.card.rel_cardObjects = newValue}
    }

    open var rda_diffIdentifier: AnyHashable {return self.card.rda_diffIdentifier}

    open var rda_diffableElements: [RDADiffableRowElementProtocol] {return self.card.rda_diffableElements}

    open var rda_elements: [Any] {
        get {return self.card.rda_elements}
        set {self.card.rda_elements = newValue}
    }

    public init(card:RELSectionCardProtocol) {
        self.card = card
    }

}
