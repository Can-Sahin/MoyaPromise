//
//  Protocols.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Moya

// In general, developer-generated 'target's are passed through the layers (Dataservice - Moya) that carries the necessary data to form the network request. Since they are enums - they dont necessarily need to be but for the unity I assume target classes are desired to be 'enums'- so, they can only have associated values that is binded with their state (case) and they cant have stored properties. Stored properties might be needed to carry the required data that can be used-modified through layers (rare cases like custom Auth processes that has several states and steps)

// To enable these a 'Wrapper' must be implemented. This wrapper will add any desired functionality that is not limited with enums and value type semantics.

// Before implementing a Wrapper for custom operations consider doing it in the Moya or even in Alamofire layer. Moya provides very flexible ways to modify Targets,UrlRequests,Callbacks and informative delegates.

// For the example, check the CustomCarService and CarTarget

/// Protocol for enabling conversion to a Wrapper
public protocol TargetConvertible{
    associatedtype ConvertibleTo: TargetWrapable
    func wrap() -> ConvertibleTo
}

/// Protocol for Wrappers of a specific 'TargetType'
public protocol TargetWrapable: TargetType{
    associatedtype WrappedType: TargetType
    var target : WrappedType { get set}
}

// Passthrough the default values
extension TargetWrapable{
    
    public var path: String {
        return target.path
    }
    
    public var baseURL: URL {
        return target.baseURL
    }
    
    public var method: Moya.Method {
        return target.method
    }
    
    public var sampleData: Data {
        return target.sampleData
    }
    
    public var task: Task {
        return target.task
    }
    
    public var validate: Bool {
        return target.validate
    }
    
    public var headers: [String : String]?{
        return target.headers
    }

}
