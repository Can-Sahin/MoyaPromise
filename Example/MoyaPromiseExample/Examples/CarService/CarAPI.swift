//
//  CarTarget.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Moya
import Alamofire

public enum CarAPI{
    case Car(String)
    case License(String,Int)
    case Wheels
}

extension CarAPI: TargetType {
    public var baseURL: URL { return URL(string: "{YOUR_API_URL}")! }

    
    public var method: Moya.Method {
        switch self {
        case .Car:
            return .get
        default:
            return .get
        }
        
    }
    
    // Path will be added to BaseUrl
    public var path: String {
        switch self {
        case .Car:
            return ""
        default:
            return ""
        }
    }
    public var headers: [String: String]? {
        return nil
    }
    
    public var parameterEncoding : ParameterEncoding{
        switch self {
        case .Car:
            return URLEncoding.default
        default:
            return  URLEncoding.default
        }
    }
    
    
    public var parameters: [String: Any] {
        switch self {
        default:
            return [:]
        }
    }
    public var task: Task {
        return .requestParameters(parameters: self.parameters, encoding: self.parameterEncoding)
    }
    
    public var validationType: ValidationType{
        return .successCodes
    }
    
    public var sampleData: Data {
        return "Sample Data".data(using: String.Encoding.utf8)!
        
    }
}
