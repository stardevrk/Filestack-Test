//
//  ImageEditorView.swift
//  Filestack
//
//  Created by Ruben Nine on 7/4/19.
//  Copyright © 2019 Filestack. All rights reserved.
//

import UIKit

class ImageEditorView: UIView {
    weak var image: UIImage? {
        didSet {
            cgBackedImage = image?.cgImageBackedCopy()
            setNeedsDisplay()
        }
    }

    // CIImage-backed UIImages are not rendered correctly in iOS 13 if they have some transformations
    // applied (e.g. cropping), so we use a CGImage-backed UIImage instead for rendering.
    private var cgBackedImage: UIImage?

    override func draw(_: CGRect) {
        guard let image = cgBackedImage else { return }

        // Clear background
        UIColor.clear.setFill()
        UIRectFill(bounds)

        // Calculate image draw rect
        let imageRect = CGRect(origin: CGPoint.zero, size: image.size)
        let ratio = max(imageRect.width / bounds.width, imageRect.height / bounds.height)
        let size = CGSize(width: (imageRect.width / ratio).rounded(), height: (imageRect.height / ratio).rounded())
        let origin = CGPoint(x: (bounds.midX - (size.width / 2)).rounded(), y: (bounds.midY - (size.height / 2)).rounded())
        let drawRect = CGRect(origin: origin, size: size)

        // Draw image
        image.draw(in: drawRect)
    }
}
