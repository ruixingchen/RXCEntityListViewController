//
//  ApiRequestSpecV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/17/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

///描述一个请求
public struct ApiRequestSpecV2 {

    public var url:URL
    public var headers:[String:String]?
    public var method:RXCHTTPMethod = .get
    public var body:Data?
    ///回调的queue
    public var queue:DispatchQueue?
    ///进行数据解析的queue
    public var parsingQueue:DispatchQueue?
    ///解析器, 用于解析服务器返回的数据
    public var parser:RXCParserV2?
    public var multipartFormData:RXCMultipartFormDataSpec?

    public init(url:URL) {
        let headers = APIService.Util.makeHeader()
        self.init(url: url, headers: headers)
    }

    public init(url:URL, headers:[String:String]?) {
        self.url = url
        self.headers = headers
    }

}
