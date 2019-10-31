//
//  KARemoteEntityParserV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/20/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation
import SwiftyJSON

///远程数据解析，将服务器传来的JSON数据解析成本地Model，本类只可以接受单个Entity和Swift数组类型的范型，其他范型暂不支持
public struct KARemoteEntityParserV2<D>: RXCParserV2 {

    ///如果要求的解析值是一个集合类型，服务器传来了空的数组，那么将返回这个默认集合，如果这个集合为nil，则会返回一个失败对象
    fileprivate let defaultCollection:D?

    /// 如果出错，那么错误类型一定是普通的错误类型
    /// - Parameter object: 服务器传来的JSON对象，必须经过了status验证，必须是原始对象，不得做任何修改
    public func parse<T>(_ object: Any?, userInfo: [AnyHashable : Any]?) -> Swift.Result<T, Error> {
        guard let json = object as? SwiftyJSON.JSON else {
            let className = object == nil ? "" : String.init(describing: type(of: object!))
            return Swift.Result.failure(RXCMessagedError(message: "数据解析失败，请重试", debugMessage: "传入了不合适的类型，要求JSON，传入了\(className)"))
        }
        let dataJson = json["data"]
        if dataJson.isEmpty {
            //如果这是一个合法的JSON，没有读取到数据，且要求的数据类型是一个数组，那么应该返回一个空数组
            //为了兼容部分接口只会返回一对花括号的API

        }

    }

}

extension KARemoteEntityParserV2 where D:Collection {

    init(defaultCollection:D?) {
        self.defaultCollection = defaultCollection
    }

}
