# Moya-PromiseKit-Service

A **'DataService'** layer implemented with [PromiseKit] on the top of [Moya] with extra functionalities using the power of PromiseKit, especially for JSON-oriented RestAPI calls. 

# What is it good for?
  - To logically group, isolate and modify the collection of network requests
  - To strictly bind the targets with their providers
  - To use the power of PromiseKit
    * Implement any custom desired generic functionality at any step of the execution
    * Custom error handling and propagation
    ##### Extra functionalities
    - Conditionally re-try a request
    - Response serialization (or implement your own custom serialization)
    - Remote Sample Data implementation
    - Provides an example Public Key Pinning implementation on Alamofire 

# Usage
`Source files available. Import the folder that is in the Source into your project and replace "YOUR_*" strings with your values and you are good to go.
No pod for now`

# Example
Make **getCarItem** request where the response is serialized to an object
```swift
let carDataService = CarDataService()
carDataService.getCarItem("carId").then{carItem in
     print(carItem.Name)
}.catch{error in
    print(error)
}
```

where **CarDataService** is
```swift
public class CarDataService: DefaultDataService<CarAPI>{
    public func getCarItem(_ id:String) -> Promise<DummyCarItem>  {
        return self.request(target: CarAPI.Car(id)).asParsedObject()
    }
    public func getDriver(_ carId:String ) -> Promise<String>  {
        return self.request(target: CarAPI.Driver(carId)).asString()
    }
}
```
Handle various errors either thrown by you or by the network during the request
```swift
carDataService.getCar("someId").then{carString in
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
