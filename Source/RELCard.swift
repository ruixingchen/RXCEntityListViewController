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

public protocol RELCard: RELEntity, SectionElementProtocol, DifferentiableSection {

    ///不采用范型, 这里直接采用Any, 后面自己做cast
    var rel_cardObjects:[Any]? {get set}

}

public class AnyCard: RELCard {

    var card:RELCard

    public var rel_cardObjects: [Any]? {
        get {return self.card.rel_cardObjects}
        set {self.card.rel_cardObjects = newValue}
    }

    public var rda_elements: [Any] {
        get {
            return self.card.rel_cardObjects ?? []
        }
        set {
            self.card.rel_cardObjects = newValue
        }
    }

    public var elements: [Differentiable] {return self.card.elements}

    public required init<C>(source: DifferentiableSection, elements: C) where C : Collection, C.Element == Differentiable {
        if var c = source as? RELCard {
            c.rel_cardObjects = [Differentiable].init(elements)
            self.card = c
        }
        fatalError("INVALID TYPE")
    }

    public var differenceIdentifier: AnyHashable {return self.card.differenceIdentifier}

    public func isContentEqual(to source: Any) -> Bool {
        return self.card.isContentEqual(to: source)
    }

    init(card:RELCard) {
        self.card = card
    }

}
