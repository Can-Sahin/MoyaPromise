//
//  DataServiceExtensions.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import Moya


extension Swift.Error{
    var isMoyaUnderlyingError: Bool{
        if let err = self as? MoyaError{
            if case MoyaError.underlying(_,_) = err{
                return true
            }
        }
        return false
    }
}

extension MoyaError{
    var isCancelledError: Bool {
        switch self {
        case .underlying(let error,_):
            return error.isCancelled
        default:
            return false
        }
    }
    var innerError: (Swift.Error?, Moya.Response?)?{
        switch self {
        case .underlying(let error, let rsp):
            return (error,rsp)
        default:
            return nil
        }
    }
    public func isStatusCodeError(code errorCode: Int) -> (Bool,Response?){
        if case let MoyaError.underlying(err,data) = self, case let AFError.responseValidationFailed(reason) = err, case let AFError.ResponseValidationFailureReason.unacceptableStatusCode(code) = reason, code == errorCode{
            return (true,data)
        }
        return (false,nil)
    }
}


extension Data{
    public func asString() -> String?{
        return String(data: self, encoding: String.Encoding.utf8)
    }
}

// Serializers for the response
extension Moya.Response{
    private func serializeWithPromise<T> (_ serializer: DataResponseSerializer<T>) -> Promise<T>{
        return Promise { seal in
            self.serialize(responseSerializer: serializer) { (result) in
                switch result {
                case .success(let value):
                    seal.fulfill(value)
                case .failure(let error):
                    seal.reject(error)
                }
            }
            
        }
    }
    
    @discardableResult
    private func serialize<T: DataResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: T,
        completionHandler: @escaping (Alamofire.Result<T.SerializedObject>) -> Void)
        -> Self
    {
        let result = responseSerializer.serializeResponse(
            self.request,
            self.response,
            self.data,
            nil
        )
        (queue ?? DispatchQueue.main).async { completionHandler(result) }
        return self
    }

    public func responseObject<T:Codable>(queue: DispatchQueue? = nil,
                                          encoding: String.Encoding? = nil) -> Promise<T> {
        let serializer : DataResponseSerializer<T> = Serialization.ObjectCoder.CodableSerializer()
        return serializeWithPromise(serializer)
    }
    
    public func response() -> Promise<(URLRequest, HTTPURLResponse, Data)> {
        return Promise { seal in
            if let a = self.request, let b = self.response{
                seal.fulfill((a,b,self.data))
            } else {
                seal.reject(PMKError.invalidCallingConvention)
            }
            
        }
    }
    public func responseString(queue: DispatchQueue? = nil,
                               encoding: String.Encoding? = nil) -> Promise<String> {
        let serializer = DataRequest.stringResponseSerializer(encoding: encoding)
        return serializeWithPromise(serializer)
    }
    
    
    public func responseData() -> Promise<Data> {
        let serializer =  DataRequest.dataResponseSerializer()
        return serializeWithPromise(serializer)
      
    }
    
    public func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments) -> Promise<Any> {
        let serializer = DataRequest.jsonResponseSerializer(options: options)
        return serializeWithPromise(serializer)
    }
    
    public func responseJsonDictionary(options: JSONSerialization.ReadingOptions = .allowFragments) -> Promise<[String: Any]> {
        let serializer = DataRequest.jsonResponseSerializer(options: options)
        return serializeWithPromise(serializer).map{json -> [String: Any] in
            if let value = json as? [String: Any]{
                return value
            }
            else{
                return [:]
            }
        }
        
    }
}
public func pickNonNil<T>(_ params: T?...) -> T?{
    for item in params {
        if item != nil { return item}
    }
    return nil
}

