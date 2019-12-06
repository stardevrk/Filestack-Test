//
//  CollageTransform.swift
//  FilestackSDK
//
//  Created by Mihály Papp on 15/06/2018.
//  Copyright © 2018 Filestack. All rights reserved.
//

import Foundation

/**
 The collage task accepts an array of Filestack file handles, storage aliases, or external URLs.
 These files are appended in given order to the base file of the transformation URL.
 Altogther the base image and the passed files are the images that will comprise the collage.
 The order in which they are added dictates how the images will be arranged.
 */
@objc(FSCollageTransform) public class CollageTransform: Transform {
    /**
     Initializes a `CollageTransform` object.

     - Parameter size: Valid range: `1...10000` x `1...10000`
     - Parameter collection: CollageTransformCollection with added handles or direct links to images.
     */
    init(size: CGSize, collection: CollageTransformCollection) {
        super.init(name: "collage")
        appending(key: "width", value: Int(size.width))
        appending(key: "height", value: Int(size.height))
        appending(key: "files", value: collection.files)
    }

    /**
     Adds the `margin` option.

     - Parameter value: Valid range: `1...100`
     */
    @objc @discardableResult public func margin(_ value: Int) -> Self {
        return appending(key: "margin", value: value)
    }

    /**
     Adds the `color` option.

     - Parameter value: Sets the background color to display behind the images.
     */
    @objc @discardableResult public func color(_ value: UIColor) -> Self {
        return appending(key: "color", value: value.hexString)
    }

    /**
     Changes the `fit` option to every image from `auto` to `crop`.
     */
    @objc @discardableResult public func cropFit() -> Self {
        return appending(key: "fit", value: TransformFit.crop)
    }

    /**
     Adds the `autorotate` option.
     */
    @objc @discardableResult public func autorotate() -> Self {
        return appending(key: "autorotate", value: true)
    }
}

/**
 Class that is used for creating and sanitizing collection of file handles, storage aliases, or external urls.

 See also `CollageTransform`.
 */
@objc(FSCollageTransformCollection) public class CollageTransformCollection: NSObject {
    var files = [String]()

    /// Adding one resource to collection.
    ///
    /// - Parameter resource: File handle, storage aliase, or external url passed as String.
    /// - Returns: self
    @objc(addResource:) @discardableResult public func add(_ resource: String) -> Self {
        return add([resource])
    }

    /// Adding few resources to collection.
    ///
    /// - Parameter resources: Array of file handles, storage aliase, or external url passed as String.
    /// - Returns: self
    @objc(addResources:) @discardableResult public func add(_ resources: [String]) -> Self {
        files.append(contentsOf: resources.map { envelop($0) })
        return self
    }

    private func envelop(_ string: String) -> String {
        return "\"\(string)\""
    }
}
