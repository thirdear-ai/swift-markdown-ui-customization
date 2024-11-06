//
//  File.swift
//  swift-markdown-ui
//
//  Created by 唐海 on 11/5/24.
//

import Foundation
import UIKit

#if canImport(UIKit)
typealias PlatformSvgImage = UIImage
#elseif canImport(AppKit)
typealias PlatformSvgImage = NSImage
#endif

/// The default network image cache.
public class SVGCache {
    private enum Constants {
        static let defaultCountLimit = 150
    }
    
    private let cache = NSCache<NSString, PlatformSvgImage>()
                          
    private var errorKey = Set<String>()
    
    public init(countLimit: Int = 0) {
        self.cache.countLimit = countLimit
    }
    
    /// A shared network image cache.
    public static let shared = SVGCache(countLimit: Constants.defaultCountLimit)
}

extension SVGCache {
    
    func read(key: String, fontSize: CGFloat) -> PlatformSvgImage? {
        cache.object(forKey: "\(key)-\(fontSize)" as NSString)
    }
    
    func set(key: String, fontSize: CGFloat, image: PlatformSvgImage) {
        cache.setObject(image, forKey: "\(key)-\(fontSize)" as NSString)
    }
    
    func setError(key: String) {
        errorKey.insert(key)
    }
    
    func canKey(key: String) -> Bool {
        errorKey.contains(key) == false
    }
}
