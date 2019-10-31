//
//  EntityListRequestSpecV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/19/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

public extension RXCEntityListViewController {
    /*
    ///新的列表页的列表页请求描述，和正常的请求描述对象差不多，但是多了requestType属性
    struct EntityListRequestSpecV2 {

        public var requestType: RXCEntityListViewController.ListRequestType
        public var url:URL

        public var headers:[String:String]?
        public var method:RXCHTTPMethod = .get
        public var body:Data?
        public var multipartFormData:RXCMultipartFormDataSpec?

        ///回调的queue
        public var queue:DispatchQueue?
        ///解析器, 用于解析服务器返回的数据
        public var parser:RXCParserV2?
        ///进行数据解析的queue
        public var parsingQueue:DispatchQueue?

        public init(url:URL, requestType: RXCEntityListViewController.ListRequestType) {
            self.url = url
            self.requestType = requestType
        }

        public func toApiRequestSpec()->ApiRequestSpecV2 {
            var spec = ApiRequestSpecV2(url: url)
            spec.headers = self.headers
            spec.method = self.method
            spec.body = self.body
            spec.multipartFormData = self.multipartFormData
            spec.queue = self.queue
            spec.parser = self.parser
            spec.parsingQueue = self.parsingQueue
            return spec
        }

    }
     */
}
