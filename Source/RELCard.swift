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

public protocol RELCard: AnyObject, RELEntity, SectionElementProtocol {

    ///不采用范型, 这里直接采用Any, 后面自己做cast
    var rel_cardObjects:[Any]? {get set}

}
