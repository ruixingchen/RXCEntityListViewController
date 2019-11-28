//
//  RELListRequestResponseSpec.swift
//  RXCEntityListViewController
//
//  Created by ruixingchen on 11/4/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

///列表页请求回复的抽象
open class RELListRequestResponseSpec<T> {

    open var data:T?
    ///response对象,例如URLResponse
    open var response:Any?
    open var error:Error?

    public init(data:T?, response:URLResponse?, error:Error?) {
        self.data = data
        self.response = response
        self.error = error
    }

    open var result:Swift.Result<T?, Error> {
        if let e = self.error {
            return .failure(e)
        }else {
            return .success(self.data)
        }
    }

    open var isSuccess:Bool {
        return self.error == nil
    }

}
