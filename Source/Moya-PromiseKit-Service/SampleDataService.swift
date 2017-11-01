//
//  CustomTargets.swift
//  IMCFramework
//
//  Created by Can Sahin on 30/10/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import Moya

// Repository for this is available in GitHub

/// Very basic MockRestAPI service which backend is implemented by/with AWS Serverless. (Simple Lambda function behind the APIGateway that stores and servers static files in S3 that contains sample data). However, you can implement your own logic for serving remote sample data
/// Optional to use
class SampleDataService: DefaultDataService<SampleDataTarget>{
    
    public func makeSampleRequest(target: SampleDataTarget,queue: DispatchQueue? = nil) -> MoyaCancellablePromise<Moya.Response>{
        return self.request(target: target, queue: queue)
    }
}


enum SampleDataTarget : TargetType{
    case Get(TargetType)
    case Put(TargetType,String)

    public var baseURL: URL { return URL(string: "https://{YOUR_APIGATEWAY_URL}")! }
    
    public var method: Moya.Method {
        switch self {
        case .Get:
            return .post
        case .Put:
            return .put
        }
    }
    
    public var path: String {
        return ""
    }
    public var headers: [String: String]? {
        return nil
    }
    
    public var parameterEncoding : ParameterEncoding{
        return Alamofire.JSONEncoding.default
    }
    
    
    public var parameters: [String: Any] {
        switch self {
        case .Get(let sourceTarget):
            return ["Application": Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String, "URL": constructUrlField(sourceTarget: sourceTarget)]
        case .Put(let sourceTarget, let data):
            return ["Application": Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String, "URL": constructUrlField(sourceTarget: sourceTarget), "ResponseData": data]
        }
    }
    private func constructUrlField(sourceTarget: TargetType) -> String{
        var url = ""
        if sourceTarget.path.isEmpty {
            url = sourceTarget.baseURL.absoluteString
        } else {
            url = sourceTarget.baseURL.appendingPathComponent(sourceTarget.path).absoluteString
        }
        return url
    }
    public var task: Task {
        return .requestParameters(parameters: self.parameters, encoding: self.parameterEncoding)
    }
    
    public var validate: Bool{
        return true
    }
    public var sampleData: Data {
        return "Sample Data".data(using: String.Encoding.utf8)!
    }
}
