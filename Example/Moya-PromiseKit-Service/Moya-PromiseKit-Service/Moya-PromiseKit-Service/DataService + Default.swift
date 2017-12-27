//
//  DataService + Default.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import Moya

public struct DataServiceProperties{
    public static var RequestSampleDataOnFail = false
    public static var SaveAllAsSampleData = false
}

/// Concrete class for default implementations
public class DefaultDataService<Target: TargetType> : DataServiceProtocol {
    public typealias MoyaTarget = Target

    public var moyaProvider: MoyaProvider<Target>
    
    init(){
        self.moyaProvider = MoyaProvider<Target>()
    }
    convenience init(moyaProvider: MoyaProvider<Target>) {
        self.init()
        self.moyaProvider = moyaProvider
    }
    
}

/// Protocol for every DataService types
public protocol DataServiceProtocol{
    associatedtype MoyaTarget: TargetType
    var moyaProvider: MoyaProvider<MoyaTarget> { get set}
    var retryPolicy: RetryPolicy? {get set}
    var retrievePolicy: RetrievePolicy? {get set}
    //Override this when writing a custom DataService
    func makeRequest(target: MoyaTarget,queue: DispatchQueue?,progress: Moya.ProgressBlock?) -> MoyaCancellablePromise<Moya.Response>
}

// Default implementations for the protocol
extension DataServiceProtocol{
    public var retryPolicy: RetryPolicy?{ get{return nil} set{}}
    public var retrievePolicy: RetrievePolicy?{ get{return nil} set{}}

    public func cancelAllTasks(){
        moyaProvider.manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() } }
    }
    
    
    public func request(target: MoyaTarget,
                            retryPolicy: RetryPolicy? = nil,
                            queue: DispatchQueue? = nil,
                            progress: Moya.ProgressBlock? = nil,
                            retrievePolicy: RetrievePolicy? = nil) -> MoyaCancellablePromise<Moya.Response>{
        var changedRetryPolicy = retryPolicy
        var changedRetrievePolicy = retrievePolicy

        #if DEBUG
            if DataServiceProperties.RequestSampleDataOnFail{
                changedRetryPolicy = RetryPolicy.sampleDataOnFailure
            }
            if DataServiceProperties.SaveAllAsSampleData {
                changedRetrievePolicy = RetrievePolicy.storeAsSampleData
            }
        #endif
        if let policy = pickNonNil(changedRetryPolicy, self.retryPolicy){
            return retry(policy: policy, target: target) { 
                return self.makeRequest(target: target, queue: queue, progress: progress).completeWithRetrievePolicy(target: target, policy: changedRetrievePolicy)
            }
        }
        else{
            return makeRequest(target: target, queue: queue, progress: progress).completeWithRetrievePolicy(target: target, policy: changedRetrievePolicy)
        }

    }


    public func makeRequest(target: MoyaTarget,
                                       queue: DispatchQueue? = nil,
                                       progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        return self.makeRequestWithPromise(target: target, queue: queue, progress: progress)
    
    }
    public func makeRequestWithPromise(target: MoyaTarget,
                                         queue: DispatchQueue? = nil,
                                         progress: Moya.ProgressBlock? = nil) ->  MoyaCancellablePromise<Moya.Response>{
        return self.moyaProvider.requestPromise(target: target, queue: queue, progress: progress)
        
    }

    
    @discardableResult
    private func retry(policy retryPolicy : RetryPolicy?, target targetToRetry: MoyaTarget, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
        
        guard let policy = retryPolicy else{
            return body()
        }
        
        switch policy {
        case .sampleDataOnFailure:
            #if DEBUG
                return retryWithSampleData(target: targetToRetry, body)
            #else
                return body()
            #endif
        case .requestRetry(let moyaPolicy):
            return retryRequest(p: moyaPolicy, body)
        }
    
    }
    @discardableResult
    private func retryWithSampleData(target targetToRetry: MoyaTarget, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
        
        return body().recoverWith(policy: CatchPolicy.allErrorsExceptCancellation) { error, token -> MoyaCancellablePromise<Moya.Response> in
            let p: MoyaCancellablePromise<Moya.Response> = MoyaCancellablePromise{(f, r) in
                SampleDataService().makeSampleRequest(target: SampleDataTarget.Get(targetToRetry)).then{ (rsp) -> Void in
                    print("Sample Data is found")
                    f(rsp)
                }.catch{errorLast in
                    if let moyaError = errorLast as? MoyaError, moyaError.isStatusCodeError(code:404).0{
                        print("Sample data cannot be found! ")
                    }
                    else{
                        print("Cannot get sample data: " + errorLast.localizedDescription)
                    }
                    r(error)
                }
            }
            if let cancelToken = token{
                p.cancelToken = cancelToken
            }
            return p
        }
    }
    @discardableResult
    private func retryRequest(p policy : RequestMoyaRetryPolicy, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
   
        var retryCounter = 0
        let times = policy.retryCount
        let coolDown = policy.coolDownInterval
        
        func attempt() -> MoyaCancellablePromise<Moya.Response> {
            return body().recoverWith(policy: CatchPolicy.allErrorsExceptCancellation) { error, token -> MoyaCancellablePromise<Moya.Response> in
                retryCounter += 1
                guard retryCounter <= times else {
                    throw error
                }
                if !policy.errorClosure(error){
                    throw error
                }
                return MoyaCancellablePromise<Void>.after(interval: coolDown, cancelToken: token).thenWith(attempt)
            }
        }
        return attempt()
    }
}
extension MoyaCancellablePromise where T: Moya.Response{
    func completeWithRetrievePolicy(target: TargetType, policy: RetrievePolicy?) -> Self{
        guard let retrievePolicy = policy else{
            return self
        }
        if retrievePolicy == .storeAsSampleData{
            return storeAsSampleData(target: target)
        }
        return self
    }
    private func storeAsSampleData(target: TargetType) -> Self{
        #if DEBUG
        self.thenWith { moyaResponse in
            moyaResponse.responseString().then{data -> Void in
                SampleDataService().makeSampleRequest(target: SampleDataTarget.Put(target,data)).catch{error in
                    print("Cannot write sample data: " + error.localizedDescription)
                }
            }
        }.catch{_ in}
        #endif
        return self
    }
}

extension MoyaCancellablePromise where T: Moya.Response{
    func asParsedObject<T:Codable>() -> MoyaCancellablePromise<T>{
        return self.thenWith(on: DispatchQueue.global(qos: .background)) { moyaResponse in
            return moyaResponse.responseObject()
        }
    }
    
    func asString() -> MoyaCancellablePromise<String>{
        return self.thenWith { moyaResponse in
            return moyaResponse.responseString()
        }
    }
    func asData() -> MoyaCancellablePromise<Data>{
        return self.thenWith { moyaResponse in
            return moyaResponse.responseData()
        }
    }
    func asJson() -> MoyaCancellablePromise<Any>{
        return self.thenWith { moyaResponse in
            return moyaResponse.responseJSON()
        }
    }
    func asJsonDictionary() -> MoyaCancellablePromise<[String: Any]>{
        return self.thenWith { moyaResponse in
            return moyaResponse.responseJsonDictionary()
        }
    }
}

