//
//  RELNeedBindDataObject.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 7/19/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

public protocol RELNeedBindDataObject {

    func bindData(object:Any?, userInfo:[AnyHashable:Any]?)

}
