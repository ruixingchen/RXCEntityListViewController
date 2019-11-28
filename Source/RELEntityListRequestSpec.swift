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

    public var url:URL
    public var page:Int
    ///请求的类型, 头部还是底部
    public var requestType: RXCEntityListViewController.ListRequestType
    public var headers:[String:String]?
    public var method:RELHTTPMethod = .get
    public var body:Data?
    ///表单数据, 优先级高于body, 同时设置的情况下, 应该优先使用表单数据
    public var multipartFormData:RXCMultipartFormDataSpec?

    ///回调的queue, 为nil的话默认在main回调
    public var queue:DispatchQueue?
    ///解析器, 用于解析服务器返回的数据
    public var parser:RXCParserProtocol?
    ///进行数据解析的queue, 有时候解析必须在主线程执行, 默认nil的话会在后台queue执行
    public var parsingQueue:DispatchQueue?

    public init(url:URL, page:Int, requestType: RXCEntityListViewController.ListRequestType) {
        self.url = url
        self.page = page
        self.requestType = requestType
    }

}
