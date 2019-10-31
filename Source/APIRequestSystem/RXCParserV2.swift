//
//  RXCParserV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/17/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

///解析器协议, 传入一个数据, 将该数据解析成另一个数据
public protocol RXCParserV2 {

    func parse<T>(_ object:Any?, userInfo:[AnyHashable:Any]?)->Swift.Result<T, Error>

}

///must be careful about force cast
public struct RXCAnyParserV2<R>: RXCParserV2 {

    private let closure:(Any?)->Swift.Result<R, Error>

    init(closure:@escaping (Any?)->Swift.Result<R, Error>) {
        self.closure = closure
    }

    public func parse<T>(_ object: Any?, userInfo: [AnyHashable : Any]?) -> Swift.Result<T, Error> {
        let result = closure(object)
        ///careful force cast
        return result.map({$0 as! T})
    }

}
