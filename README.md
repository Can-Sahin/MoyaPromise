# MoyaPromise

A **'DataService'** layer implemented with [PromiseKit] on the top of [Moya] with extra functionalities using the power of PromiseKit, especially for JSON-oriented RestAPI calls. 

# What is it good for?
  - To use Moya requests with Promise pattern
    * Implement any custom desired generic functionality at any step of the execution
    * Custom error handling and propagation
  - To logically group, isolate and modify the collection of network requests
  - To strictly bind the targets with their providers
    ##### Extra functionalities
    - Conditionally re-try a request
    - Response serialization
      * Out of the box `Codable object`, `String`, `Data` , `[String: Any]`serialization
      * Flexible to implement your own custom serialization
    - Example project provides an example Public Key Pinning implementation on Alamofire 

# Dependencies

Currently build upon following pods and version 

`Alamofire (4.7.0)`

`Moya (11.0.1)`

`PromiseKit (6.2.1)`

# Installation
### CocoaPods

Add following pod to your podfile

```rb
pod 'MoyaPromise'
```

Then run `pod install`.

Don't forget to
import the framework to swift files like `import MoyaPromise`.
### SwiftPM
MoyaPromise ban be installed via the official Swift Package Manager.

In Xcode:  File -> Swift Packages -> Add Package Dependency...
and add https://github.com/Can-Sahin/MoyaPromise.git.

# Example

Example Project in the repository provides examples of how to do the requests and how to structure your code.  
Its not ready-to-run since `MoyaTarget`s are dummy ones. Its mainly for examining and providing the library use cases. To run it,

first `pod install`

then modify the `MoyaTargets` and modify `ViewController`'s default functions to call various requests.



Some basic code examples

## Example code

Make **getCarItem** request where the response is serialized to an object
```swift
let carDataService = CarDataService()
carDataService.getCarItem("carId").done{carItem in
     print(carItem.Name)
}.catch{error in
    print(error)
}
```

where **CarDataService** is
```swift
public class CarDataService: DefaultDataService<CarAPI>{
    public func getCarItem(_ id:String) -> Promise<DummyCarItem>  {
        return self.request(target: CarAPI.Car(id)).asParsedObject().promise
    }
    public func getDriver(_ carId:String ) -> Promise<String>  {
        return self.request(target: CarAPI.Driver(carId)).asString().promise
    }
}
```
Handle various errors either thrown by you or by the network during the request
```swift
carDataService.getCar("someId").done{carString in
        print(carString)
}.catch{error in
    // Custom error handling
    if let err = error as? SomeCustomError{
        if case .Unauthorized = err{
            print("Not authorized")
            // Go to login
        }
    }
}.always {
    //UIActivityIndicatorView.stopAnimating()
}
```

**Check the example project to see more of the abilities**

# License
MIT

[Moya]: <https://github.com/Moya/Moya>
[PromiseKit]: <https://github.com/mxcl/PromiseKit>
