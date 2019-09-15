//
//  RELListRequestDataProcessorProtocol.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 2019/9/16.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public protocol RELListRequestDataProcessorProtocol: AnyObject {
    
    ///对服务器传来的数据进行处理, 过滤, 预计算什么的, 返回处理之后的数据
    func process(newObjects:[Any], userInfo:[AnyHashable:Any]?)->[Any]
    
}
