//
//  RELEntityListRequestSpec.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/19/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation
import RXCSwiftComponents

public enum RELHTTPMethod:String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

///描述一个列表页数据请求
public struct RELEntityListRequestSpec {

    public var requestType: RXCEntityListViewController.ListRequestType
    public var url:URL

    public var headers:[String:String]?
    public var method:RELHTTPMethod = .get
    public var body:Data?
    public var multipartFormData:RXCMultipartFormDataSpec?

    ///回调的queue, 为nil的话默认在main回调
    public var queue:DispatchQueue?
    ///解析器, 用于解析服务器返回的数据
    public var parser:RXCParserProtocol?
    ///进行数据解析的queue, 有时候解析必须在主线程执行, 默认nil的话会在后台queue执行
    public var parsingQueue:DispatchQueue?

    public init(url:URL, requestType: RXCEntityListViewController.ListRequestType) {
        self.url = url
        self.requestType = requestType
    }

}
