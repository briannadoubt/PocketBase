//
//  ThumbSize.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

/// Represents thumbnail size options for image files in PocketBase.
///
/// PocketBase can generate thumbnails for jpg, png, gif (first frame), and webp images.
/// The original file is returned if the requested thumb size is not available or the file is not an image.
///
/// ## Supported Formats
///
/// - `WxH` - Crop to WxH viewbox (from center)
/// - `WxHt` - Crop to WxH viewbox (from top)
/// - `WxHb` - Crop to WxH viewbox (from bottom)
/// - `WxHf` - Fit inside a WxH viewbox (without cropping)
/// - `0xH` - Resize to H height preserving aspect ratio
/// - `Wx0` - Resize to W width preserving aspect ratio
///
/// ## Example
///
/// ```swift
/// let url = pocketbase.fileURL(
///     record: record,
///     filename: "avatar.png",
///     thumb: .crop(width: 100, height: 100)
/// )
/// ```
public enum ThumbSize: Sendable, Hashable {
    /// Crop to WxH viewbox from center.
    case crop(width: Int, height: Int)

    /// Crop to WxH viewbox from top.
    case cropTop(width: Int, height: Int)

    /// Crop to WxH viewbox from bottom.
    case cropBottom(width: Int, height: Int)

    /// Fit inside a WxH viewbox without cropping.
    case fit(width: Int, height: Int)

    /// Resize to specified height, preserving aspect ratio.
    case height(Int)

    /// Resize to specified width, preserving aspect ratio.
    case width(Int)

    /// The query string value for this thumb size.
    public var queryValue: String {
        switch self {
        case .crop(let width, let height):
            return "\(width)x\(height)"
        case .cropTop(let width, let height):
            return "\(width)x\(height)t"
        case .cropBottom(let width, let height):
            return "\(width)x\(height)b"
        case .fit(let width, let height):
            return "\(width)x\(height)f"
        case .height(let height):
            return "0x\(height)"
        case .width(let width):
            return "\(width)x0"
        }
    }
}
