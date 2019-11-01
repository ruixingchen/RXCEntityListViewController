//
//  RELCard.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
import RXCDiffArray

public protocol RELCardProtocol: RELEntityProtocol {

    ///不采用范型, 这里直接采用Any, 后面自己做cast
    var rel_cardObjects:[Any]? {get set}

}

//public class SimpleCard: RELCardProtocol {
//
//    var card:RELCard
//
//    public var rel_cardObjects: [Any]? {
//        get {return self.card.rel_cardObjects}
//        set {self.card.rel_cardObjects = newValue}
//    }
//
//    public var rda_elements: [Any] {
//        get {
//            return self.card.rel_cardObjects ?? []
//        }
//        set {
//            self.card.rel_cardObjects = newValue
//        }
//    }
//
//}
