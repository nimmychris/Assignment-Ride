//
//  APIManager.swift
//  Assignment
//
//  Created by Christi John on 11/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import UIKit
import Alamofire

public typealias CompletionInfo = (_ finished: Bool, _ response: Any?) -> Void

class APIManager: NSObject {
    
    static func getReuest(requestUrl: URL,
                   method: HTTPMethod,
                   params: Dictionary<String, String>?,
                   completion: @escaping CompletionInfo) {
    
        Alamofire.request(requestUrl,
                          method: .get,
                          parameters:params,
                          encoding: URLEncoding.default, headers: nil)
            .validate()
            .responseJSON { (response) in
                switch (response.result) {
                case .success:
                    if let data = response.result.value as? [String: AnyObject] {
                        completion(true, data)
                    }
                case .failure(let error):
                    print("error \(error)")
                }
        }
        
        
    }
    
}

