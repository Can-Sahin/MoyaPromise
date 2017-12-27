//
//  Serialization.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire


class Serialization {
    enum ErrorCode: Int {
        case noData = 1
        case DecodingError = 2
    }
    
    static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "com.responseSerialization.error"
        
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        
        return returnError
    }
    
    class ObjectCoder{
        public static func CodableSerializer<T:Codable>() -> DataResponseSerializer<T> {
            return DataResponseSerializer { _, response, data, error in
                if let err = error{
                    return .failure(err)
                }
                guard let _ = data else{
                    let failureReason = "Data could not be serialized. Input data was nil."
                    let error = Serialization.newError(.noData, failureReason: failureReason)
                    return .failure(error)
                }
                let decoder = JSONDecoder()
                do {
                    let obj =  try decoder.decode(T.self, from: data!)
                    return .success(obj)
                }
                catch{
                    let failureReason = "Data could not be decoded."
                    let error = Serialization.newError(.DecodingError, failureReason: failureReason)
                    return .failure(error)
                }
                
            }
        }
    }
}
