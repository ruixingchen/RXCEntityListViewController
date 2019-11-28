//
//  RELDataBindableObjectProtocol.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation
import RXCSwiftComponents

///描述一个可以进行数据绑定的对象
public typealias RELDataBindableObjectProtocol = RXCBindableObjectProtocol

//public protocol RELDataBindableObjectProtocol {
//
//    func bindData(object:Any?, userInfo:[AnyHashable:Any]?)
//
//}

public typealias RELDataBindableModelStorageObjectProtocol = RXCBindableModelStorageObjectProtocol

extension RELDataBindableModelStorageObjectProtocol {

    public func getEntity<T>()->T? {
        let entity = self.rxc_bindedData
        if let wrapper = entity as? RELRowEntityProtocolWrapper {
            return wrapper.entity as? T
        }else if let wrapper = entity as? RELSectionCardProtocolWrapper {
            return wrapper.card as? T
        }
        return entity as? T
    }

}
