
Pod::Spec.new do |s|


  s.name         = "MoyaPromise"
  s.version      = "0.1.1"
  s.summary      = "PromiseKit-oriented 'DataService' layer on top of Moya"

  s.description  = <<-DESC
    A 'DataService' layer implemented with PromiseKit on the top of Moya with extra functionalities using the power of PromiseKit, especially for JSON-oriented RestAPI calls. Includes several serialization, conditional re-try mechanism.
    DESC

  s.homepage     = "https://github.com/Can-Sahin/MoyaPromise"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Can-Sahin" => "cann2005@gmail.com" }
  s.swift_version = "4.0"
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/Can-Sahin/MoyaPromise.git", :tag => "#{s.version}" }
  s.source_files  = 'src/MoyaPromise/*.swift'

  s.dependency "Alamofire", "~> 4.7.0"
  s.dependency "PromiseKit/Alamofire", "~> 6.0"
  s.dependency "PromiseKit", "~> 6.2.1"
  s.dependency "Moya", "~> 11.0.1"


end
