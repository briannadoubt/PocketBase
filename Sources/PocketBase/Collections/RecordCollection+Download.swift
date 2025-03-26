//
//  RecordCollection+Download.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/22/25.
//

import Foundation

extension RecordCollection {
    public typealias FileToken = String
    
    /// Download a file from a record field
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
    /// - Parameters:
    ///   - recordId: The id of the record where the flie resides.
    ///   - fileName: The filename of the requested resource. This is stored as the value of the field when downloading through JSON.
    ///   - thumbnail: Get the thumbnail of the requested file.
    ///   - fileToken: Optional file token for granting access to protected file(s). For an example, you can check ["Files upload and handling"](https://pocketbase.io/docs/files-handling/#protected-files).
    ///   - download: Whether or not to include download headers on the response
    /// - Returns: The file resource data
    @Sendable
    @discardableResult
    public func downloadFile(
        for recordId: String,
        fileName: String,
        thumbnail: ThumbnailParameter? = nil,
        token fileToken: FileToken? = nil,
        download: Bool = false
    ) async throws -> Data {
        try await client.get(
            path: PocketBase.recordPath(collection, recordId, trailingSlash: true) + fileName,
            query: {
                var query = [URLQueryItem]()
                if let thumbnail, let thumb = thumbnail.queryItem {
                    query.append(thumb)
                }
                if let fileToken {
                    query.append(URLQueryItem(name: "token", value: fileToken))
                }
                if download {
                    query.append(URLQueryItem(name: "download", value: "true"))
                }
                return query
            }(),
            headers: client.headers
        )
    }
}
