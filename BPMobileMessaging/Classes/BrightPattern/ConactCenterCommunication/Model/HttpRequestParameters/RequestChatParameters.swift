//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import UIKit

/// - Tag: RequestChatParameters
struct RequestChatParameters: Encodable {
    let phoneNumber: String?
    let from: String
    let parameters: [String: String]
    let userPlatform: [String: String]
    
    init(phoneNumber: String?, from: String, parameters: [String: String]) {
        #if targetEnvironment(simulator)
             let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
         #else
             var systemInfo = utsname()
             uname(&systemInfo)
        
             let machineMirror = Mirror(reflecting: systemInfo.machine)
             let identifier = machineMirror.children.reduce("") { identifier, element in
                 guard let value = element.value as? Int8, value != 0 else { return identifier }
                 return identifier + String(UnicodeScalar(UInt8(value)))
             }
         #endif
        
        self.phoneNumber = phoneNumber
        self.from = from
        self.parameters = parameters
        self.userPlatform = [
            "os": UIDevice.current.systemName + " " + UIDevice.current.systemVersion,
            "name": UIDevice.current.name,
            "manufacturer": "Apple",
            "model": UIDevice.current.model,
            "identifier": identifier
        ]
    }

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case from
        case parameters
    }
    
    enum UserPlatformKeys: String, CodingKey {
        case userPlatform = "user_platform"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if (phoneNumber != nil) {
            try container.encode(phoneNumber, forKey: .phoneNumber)
        }
        try container.encode(from, forKey: .from)
        
        let parametersEncoder = container.superEncoder(forKey: .parameters)
        try self.parameters.encode(to: parametersEncoder)
        
        var platformContainer = parametersEncoder.container(keyedBy: UserPlatformKeys.self)
        let platformEncoder = platformContainer.superEncoder(forKey: .userPlatform)
        try userPlatform.encode(to: platformEncoder)
    }
}
