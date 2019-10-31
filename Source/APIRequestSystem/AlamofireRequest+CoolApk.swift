//
//  AlamofireRequest+CoolApk.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/19/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension Alamofire.DataResponse {

    ///检查错误，如果是一个失败的请求，返回一个错误，否则返回nil
    func checkError()->ApiRequestErrorV2? {
        let result = self.result
        if result.isSuccess {return nil}

        switch result {
        case .success(_):
            return nil
        case .failure(let error):
            if let apiError = error as? ApiRequestErrorV2 {
                return apiError
            }
            let code = (error as NSError).code
            let domain = (error as NSError).domain
            if domain == URLError.errorDomain && code == URLError.cancelled.rawValue {
                //这是一个被取消的请求
                return ApiRequestErrorV2.cancelled
            }else {
                //其他错误类型，归类为请求失败
                return ApiRequestErrorV2.requestFailed(error, nil)
            }
        }
    }

}

public extension Alamofire.DataRequest {

    ///将请求的回应Data转换为JSON，这里我们不做任何处理，直接原样返回JSON, 且返回的Result的Error一定是ApiRequestError
    private static var swiftyJSONResponseSerializer:DataResponseSerializer = DataResponseSerializer.init { (request, response, data, error) -> Alamofire.Result<SwiftyJSON.JSON> in
        guard let validData = data, request != nil, response != nil, error == nil else {
            let message = R.string.newLocalizable.str_request_failed_and_retry()
            let apiError:ApiRequestErrorV2
            if error != nil {
                //请求本身就是失败的
                if error!.isURLRequestCancelledError {
                    apiError = ApiRequestErrorV2.cancelled
                }else {
                    apiError = ApiRequestErrorV2.requestFailed(error!, nil)
                }
            }else if response == nil {
                let error = RXCMessagedError(message: message, debugMessage: "服务器没有返回response")
                apiError = ApiRequestErrorV2.requestFailed(error, nil)
            }else if data == nil {
                let error = RXCMessagedError(message: message, debugMessage: "服务器没有返回Data")
                apiError = ApiRequestErrorV2.requestFailed(error, nil)
            }else if request == nil {
                let error = RXCMessagedError(message: message, debugMessage: "服务器没有返回Data")
                apiError = ApiRequestErrorV2.requestFailed(error, nil)
            }else {
                let error = RXCMessagedError(message: message, debugMessage: "未知原因")
                apiError = ApiRequestErrorV2.requestFailed(error, nil)
            }
            return Alamofire.Result.failure(apiError)
        }
        do {
            let json = try JSON.init(data: validData)
            return Alamofire.Result.success(json)
        }catch {
            ///JSON解析失败
            let apiError = ApiRequestErrorV2.serializingFailed(error, nil)
            return Alamofire.Result.failure(apiError)
        }
    }

    ///返回一个JSON对象，这个对象一定是JSON格式的，但是里面的内容是未经任何验证的
    @discardableResult
    func responseSwiftyJSON(queue:DispatchQueue?, parseQueue:DispatchQueue?, completion:@escaping (DataResponse<JSON>)->Void)->Self{

        let serializer = DataRequest.swiftyJSONResponseSerializer

        //数据的转换放在parseQueue中进行， 回调放在queue中进行
        self.response(queue: parseQueue ?? DispatchQueue.global(), responseSerializer: serializer, completionHandler: {
            (dr:DataResponse<JSON>) in
            //将请求的结果交给后期处理器进行处理, 比如处理forwardUrl, 后期处理也可以对其中的某些数据进行修改(不推荐这么做)
            ///在设置的queue中回调
            (queue ?? DispatchQueue.main).async {
                //APIRequestResultPostPrecessor.onRequestResponse(dr)
                completion(dr)
            }
        })
        return self
    }

    ///返回一个经过验证的JSON数据，这个JSON一定是合法的, 且status也是正确的
    @discardableResult
    func responseCoolApkJSONV2(queue:DispatchQueue?, parseQueue:DispatchQueue?, completion:@escaping (ApiRequestResultV2<JSON>)->Void)->Alamofire.DataRequest {

        self.responseSwiftyJSON(queue: parseQueue ?? DispatchQueue.global(), parseQueue: parseQueue ?? DispatchQueue.global()) { (dr:DataResponse<JSON>) in

            ///方便后面调用completion的时候无需每次都queue.async
            let _completion:(ApiRequestResultV2<JSON>)->Void = { (result) in
                let q:DispatchQueue = queue ?? DispatchQueue.main
                q.async(execute: { () in
                    completion(result)
                })
            }

            switch dr.result {
            case .failure(let error):
                if let apiError = error as? ApiRequestErrorV2 {
                    _completion(ApiRequestResultV2.init(error: apiError))
                }else {
                    LogUtil.warning("responseSwiftyJSON 接口的Error不是ApiRequestErrorV2类型")
                    if error.isURLRequestCancelledError {
                        let apiError = ApiRequestErrorV2.cancelled
                        _completion(ApiRequestResultV2.init(error: apiError))
                    }else{
                        let apiError = ApiRequestErrorV2.requestFailed(error, nil)
                        _completion(ApiRequestResultV2.init(error: apiError))
                    }
                }
                return
            case .success(let json):
                if let error = APIServiceV2.validateJSONStatusCode(json: json) {
                    //服务器传来了状态码错误🙅
                    let apiError = ApiRequestErrorV2.serverStatusError(error, nil)
                    _completion(ApiRequestResultV2.init(error: apiError))
                    return
                }else {
                    _completion(ApiRequestResultV2.init(data: json))
                }
                return
            }
        }
        return self
    }

    ///直接返回解析后的数据，适合没有特殊处理的请求, 适合绝大部分接口, 且如果解析出来的数据和预期的数据类型不相符，则判断为序列化失败
    @discardableResult
    func responseCoolApkParsedObject<T>(queue:DispatchQueue?, parseQueue:DispatchQueue?, parser:RXCParserV2, completion:@escaping (ApiRequestResultV2<T>)->Void)->DataRequest {

        self.responseCoolApkJSONV2(queue: parseQueue ?? DispatchQueue.global(), parseQueue: parseQueue ?? DispatchQueue.global()) { (jsonRequestResult:ApiRequestResultV2<JSON>) in

            ///方便后面调用completion的时候无需每次都queue.async
            let _completion:(ApiRequestResultV2<T>)->Void = { (result) in
                let q:DispatchQueue = queue ?? DispatchQueue.main
                q.async(execute: { () in
                    completion(result)
                })
            }

            switch jsonRequestResult.result {
            case .failure(let error):
                //请求失败
                _completion(ApiRequestResultV2.init(error: error))
                return
            case .success(_):
                //请求成功， 开始解析数据
                break
            }

            //开始解析数据

            let parsingResult:Swift.Result<T, Error> = parser.parse(jsonRequestResult.data!, userInfo: nil)
            switch parsingResult {
            case .failure(let error):
                if let apiError = error as? ApiRequestErrorV2 {
                    _completion(ApiRequestResultV2.init(error: apiError))
                }else {
                    let apiError = ApiRequestErrorV2.serializingFailed(error, nil)
                    _completion(ApiRequestResultV2.init(error: apiError))
                }
                return
            case .success(let object):
                //解析成功
                _completion(ApiRequestResultV2.init(data: object))
                return
            }
        }
        return self
    }


}
