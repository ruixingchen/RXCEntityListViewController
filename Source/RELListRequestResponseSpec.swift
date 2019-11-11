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

    open var data:Data?
    open var response:URLResponse?
    open var error:Error?

    open var result:Swift.Result<T, Error>

    public init(data:Data, response:URLResponse?, error:Error?, result: Swift.Result<T, Error>) {
        self.data = data
        self.response = response
        self.error = error
        self.result = result
    }

    open var isSuccess:Bool {
        return (try? self.result.get()) != nil
    }

}
