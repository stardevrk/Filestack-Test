//
//  AutoImageTransform.swift
//  FilestackSDK
//
//  Created by Ruben Nine on 13/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import Foundation

/**
 Changes encoding of the image based on the user agent and therefore provides better compression and quality
 characteristics compared to their older JPEG and PNG counterparts.
 */
@objc(FSAutoImageTransform) public class AutoImageTransform: Transform {
    /**
     Initializes an `AutoImageTransform` object.
     */
    @objc public init() {
        super.init(name: "auto_image")
    }
}
