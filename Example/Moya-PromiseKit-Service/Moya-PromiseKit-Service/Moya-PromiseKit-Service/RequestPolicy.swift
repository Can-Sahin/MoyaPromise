//
//  RetryPolicy.swift
//  PromiseKitAlamofireTest
//
//  Created by Can Sahin on 29/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation

import Alamofire
import Moya

/*
 
 Alamofire Retrier is disabled. Cancelling the request when its in its coolDown interval does NOT cancel the trigger after the interval

public class RequestAlamofireRetryPolicy: RequestRetrier{
    public var retryCount: Int
    public var coolDownInterval: Double
 
    private var retryCounter:Int = 0
 
    var errorClosure: ((SessionManager, Request, Swift.Error) -> Bool)

    public required init (retryCount rCount: Int, coolDownInterval cDown: Double, onError error: @escaping(SessionManager, Request, Swift.Error) -> Bool){
        self.errorClosure = error
        self.retryCount = rCount
        self.coolDownInterval = cDown
    }
    public func should(_ manager: SessionManager, retry request: Request, with error: Swift.Error, completion: @escaping RequestRetryCompletion) {
        if error.isCancelledError {
            completion(false,0)
            return
        }
        retryCounter = retryCounter + 1
        guard self.retryCounter <= retryCount else{
            completion(false,0)
            return
        }
        if self.errorClosure(manager, request, error){
            completion(true,coolDownInterval)
        }
        else{
            completion(false, 0)
        }
    }
}
 
 */

public enum RetrievePolicy{
    case storeAsSampleData
}
public enum RetryPolicy{
    case sampleDataOnFailure
    case requestRetry(RequestMoyaRetryPolicy)
}

public class RequestMoyaRetryPolicy {

    var errorClosure: ((Swift.Error) -> Bool)
    public var retryCount: Int
    public var coolDownInterval: Double
    
    public required init (retryCount rCount: Int, coolDownInterval cDown: Double, onError error: @escaping(Swift.Error) -> Bool){
        self.errorClosure = error
        self.retryCount = rCount
        self.coolDownInterval = cDown
    }
}
