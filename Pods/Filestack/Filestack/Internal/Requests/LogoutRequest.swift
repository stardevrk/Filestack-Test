//
//  LogoutRequest.swift
//  Filestack
//
//  Created by Ruben Nine on 11/21/17.
//  Copyright © 2017 Filestack. All rights reserved.
//

import Alamofire
import Foundation

final class LogoutRequest {
    // MARK: - Properties

    let provider: CloudProvider
    let apiKey: String
    let token: String

    // MARK: - Lifecyle Functions

    init(provider: CloudProvider, apiKey: String, token: String) {
        self.provider = provider
        self.apiKey = apiKey
        self.token = token
    }

    // MARK: - Internal Functions

    func perform(cloudService: CloudService, completionBlock: @escaping LogoutCompletionHandler) {
        let request = cloudService.logoutRequest(provider: provider, apiKey: apiKey, token: token)

        request.validate(statusCode: Constants.validHTTPResponseCodes)

        request.responseData { dataResponse in
            let response = LogoutResponse(error: dataResponse.error)

            completionBlock(response)
        }
    }
}
