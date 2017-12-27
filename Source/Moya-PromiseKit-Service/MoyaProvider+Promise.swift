//
//  MoyaProvider+Promise.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import PromiseKit
import Moya

// Copy of Moya.CancellableWrapper class. Moya made it internal so this is the identical copy for the module
internal class CancellableWrapper: Cancellable {
    internal var innerCancellable: Cancellable = SimpleCancellable()
    
    var isCancelled: Bool { return innerCancellable.isCancelled }
    
    internal func cancel() {
        innerCancellable.cancel()
    }
}
// Copy of Moya.SimpleCancellable class. Moya made it internal so this is the identical copy for the module
internal class SimpleCancellable: Cancellable {
    var isCancelled = false
    func cancel() {
        isCancelled = true
    }
}

/// Simply a 'custom' Promise holding a cancellable token
public class MoyaCancellablePromise<T> : Promise<T>{
    var cancelToken: Cancellable = SimpleCancellable()
    
    public func cancel(){
        cancelToken.cancel()
    }
    
    public var isCancelled: Bool { return cancelToken.isCancelled}
    
    required public init(resolvers: (@escaping (T) -> Void, @escaping (Swift.Error) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
    
    required public init(value: T) {
        super.init(value: value)
    }
    
    public required init(error: Swift.Error) {
        super.init(error: error)
    }
    public class func FromPromise(promise: Promise<T>) -> MoyaCancellablePromise<T>{
        let p = MoyaCancellablePromise<T> { (f, r) in
            promise.then{v in
                f(v)
            }.catch(policy: .allErrors){error in
                r(error)
            }
        }
        return p
    }
    /// 'Recover' implementation with CancelledError check
    public func recoverWith(on q: DispatchQueue = .default, policy: CatchPolicy = .allErrorsExceptCancellation, execute body: @escaping (Swift.Error, Cancellable?) throws -> MoyaCancellablePromise<T>) -> MoyaCancellablePromise<T>{
        let p = MoyaCancellablePromise<T> { (f, r) in
            self.recover(on: q, policy: policy, execute: { (error) -> Promise<T> in
                if self.isCancelled {
                    throw (NSError.cancelledError())
                }
                return try body(error,self.cancelToken)
            }).then{v in
                f(v)
            }.catch(policy: .allErrors){error in
                r(error)
            }
        }
        p.cancelToken = self.cancelToken
        return p
    }
    
    /// 'Then' implementation. Chains the promise with the given closure and attaches the cancel token to the new output
    public func thenWith<U>(on q: DispatchQueue = .default, _ closure: @escaping (_ pValue: T) -> Promise<U>) -> MoyaCancellablePromise<U>{
        let p = MoyaCancellablePromise<U> { (f, r) in
            self.then(on: q){v in
                closure(v)
            }.then{ v2 in
                f(v2)
            }.catch(policy: .allErrors){error in
                r(error)
            }
        }
        p.cancelToken = self.cancelToken
        return p
    }
    
    /// 'Then' implementation without requiring Promise return value. Use this to modify the fulfilled value or reject during the process
    public func modifyWith(on q: DispatchQueue = .default, _ closure: @escaping (_ pValue: T,  _ fulfill: @escaping (T) -> Void,  _ reject: @escaping (Error) -> Void) -> Void) -> MoyaCancellablePromise{
        let p = MoyaCancellablePromise<T> { (f, r) in
            self.then(on: q){v in
                closure(v,f,r)
            }.catch(policy: .allErrors){error in
                r(error)
            }
        }
        p.cancelToken = self.cancelToken
        return p
    }
    
    /// Tap into the result when it is fulfilled. Check 'tap' feature of PromiseKit
    public func tapWhenFulfilled(on q: DispatchQueue = .default, _ closure: @escaping (_ pValue: T) -> Void) -> MoyaCancellablePromise{
        self.tap { (r) in
            if case let .fulfilled(v) = r{
                closure(v)
            }
        }
        return self
    }
    /// Promise.after() checking the cancel token
    public class func after(interval: TimeInterval, cancelToken: Cancellable?) -> MoyaCancellablePromise<Void> {
        let p = MoyaCancellablePromise<Void> { fulfill, reject in
            let when = DispatchTime.now() + interval
            DispatchQueue.global().asyncAfter(deadline: when, execute: {
                if cancelToken?.isCancelled ?? false{
                    reject(NSError.cancelledError())
                }
                else{
                    fulfill(())
                }
            })
        }
        return p
    }
    
}

public extension MoyaProvider {
    
    /// Promise value of moya request
    func requestPromise(target: Target,
                        queue: DispatchQueue? = nil,
                        progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        
        let token = CancellableWrapper()
        
        let p:MoyaCancellablePromise<Moya.Response> = MoyaCancellablePromise {fulfill,reject in
            token.innerCancellable = self.request(target, callbackQueue: queue, progress: progress, completion: { (result) in
                switch result {
                case let .success(response):
                    fulfill(response)
                case let .failure(error):
                    if error.isCancelledError{
                        reject(NSError.cancelledError())
                    }
                    else{
                        reject(error)
                    }
                }
            })
        }
        p.cancelToken = token
        return p
    }
}
