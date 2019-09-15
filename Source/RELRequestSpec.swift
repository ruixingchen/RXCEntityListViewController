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
    
    var method:String = "GET"
    let url:URL
    var header:[String:String] = [:]
    var body:Data?
    
    init(url:URL) {
        self.url = url
    }
    
    
}
