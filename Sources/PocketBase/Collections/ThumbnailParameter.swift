//
//  ThumbnailParameter.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/22/25.
//

import Foundation

/// Use this to generate the `thumb` `URLQueryItem` parameter when downloading a file.
///
/// The following thumb formats are currently supported:
///
/// * `WxH` (e.g. 100x300) - crop to `WxH` viewbox (from center)
/// * `WxHt` (e.g. 100x300t) - crop to `WxH` viewbox (from top)
/// * `WxHb` (e.g. 100x300b) - crop to `WxH` viewbox (from bottom)
/// * `WxHf` (e.g. 100x300f) - fit inside a `WxH` viewbox (without cropping)
/// * `0xH` (e.g. 0x300) - resize to `H` height preserving the aspect ratio
/// * `Wx0` (e.g. 100x0) - resize to `W` width preserving the aspect ratio
///
/// If the thumb size is not defined in the file schema field options or the file resource is not an image (jpg, png, gif), then the original file resource is returned unmodified.
public struct ThumbnailParameter {
    public var width: Int?
    public var height: Int?
    public var crop: Crop?
    
    /// Use this to generate the `thumb` `URLQueryItem` parameter when downloading a file.
    ///
    /// The following thumb formats are currently supported:
    ///
    /// * `WxH` (e.g. 100x300) - crop to `WxH` viewbox (from center)
    /// * `WxHt` (e.g. 100x300t) - crop to `WxH` viewbox (from top)
    /// * `WxHb` (e.g. 100x300b) - crop to `WxH` viewbox (from bottom)
    /// * `WxHf` (e.g. 100x300f) - fit inside a `WxH` viewbox (without cropping)
    /// * `0xH` (e.g. 0x300) - resize to `H` height preserving the aspect ratio
    /// * `Wx0` (e.g. 100x0) - resize to `W` width preserving the aspect ratio
    ///
    /// If the thumb size is not defined in the file schema field options or the file resource is not an image (jpg, png, gif), then the original file resource is returned unmodified.
    public init(width: Int? = nil, height: Int? = nil, crop: Crop? = nil) {
        self.width = width
        self.height = height
        self.crop = crop
    }
    
    var queryItem: URLQueryItem? {
        if let value {
            URLQueryItem(name: "thumb", value: value)
        } else {
            nil
        }
    }
    
    var value: String? {
        if let width, let height {
            "\(width)x\(height)\(crop?.rawValue ?? "")"
        } else if let width {
            "\(width)x0\(crop?.rawValue ?? "")"
        } else if let height {
            "0x\(height)\(crop?.rawValue ?? "")"
        } else {
            nil
        }
    }
    
    public enum Crop: String {
        case top = "t"
        case bottom = "b"
        case fit = "f"
    }
}
