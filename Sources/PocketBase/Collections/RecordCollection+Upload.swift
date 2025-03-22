//
//  RecordCollection+Upload.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/22/25.
//

import Foundation

extension RecordCollection where T: BaseRecord {
    /// Upload a single file to a record field
    /// - Parameters:
    ///   - data: The data to upload
    ///   - recordId: The id of the record to update
    ///   - field: The field that the file resides in the record
    ///   - fileName: The name of the uploaded file
    /// - Returns: The updated record
    @Sendable
    @discardableResult
    func upload(
        _ data: Data,
        for recordId: String,
        field: String,
        fileName: String
    ) async throws -> T {
        try await patch(
            path: PocketBase.recordPath(collection, recordId, trailingSlash: true) + fileName,
            headers: multipartHeaders,
            body: PocketBase.formEncoder.encode(
                [field: data],
                boundary: PocketBase.multipartEncodingBoundary
            )
        )
    }
    
    /// Upload a batch of files to a record field
    /// - Parameters:
    ///   - data: The data objects to upload
    ///   - recordId: The id of the record to update
    ///   - field: The field that the file resides in the record
    ///   - fileName: The name of the uploaded file
    /// - Returns: The updated record
    @Sendable
    @discardableResult
    func upload(
        _ data: [Data],
        for recordId: String,
        field: String,
        fileName: String
    ) async throws -> Data {
        try await patch(
            path: PocketBase.recordPath(
                collection,
                recordId,
                trailingSlash: true
            ) + fileName,
            headers: multipartHeaders,
            body: PocketBase.formEncoder.encode(
                [field: data],
                boundary: PocketBase.multipartEncodingBoundary
            )
        )
    }
}
