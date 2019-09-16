//
//  RELRequestSpec.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 2019/9/16.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///描述一个列表页的请求
open class RELRequestSpec {
    
    open var method:String = "GET"
    open var url:URL
    open var header:[String:String] = [:]
    open var body:Data?
    open var multipartFormData:AnyObject?
    
    public init(url:URL) {
        self.url = url
    }
    
}

open class RELListRequestSpec: RELRequestSpec {
    
    open var requestType:RXCEntityListViewController.RequestType = RXCEntityListViewController.RequestType.headerRefresh
    
}
