//
//  AdminAPITests.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation
import Testing
@testable import PocketBaseAdmin
@testable import PocketBase

@Suite("AdminAPI")
struct AdminAPITests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("AdminAPI initialization")
    func initialization() {
        let admin = AdminAPI(pocketbase: pocketbase)
        #expect(admin.pocketbase.url == pocketbase.url)
    }

    @Test("AdminAPI accessible via pocketbase.admin extension")
    func extensionAccess() {
        let admin = pocketbase.admin
        #expect(admin.pocketbase.url == pocketbase.url)
    }

    @Test("AdminAPI logs subsystem")
    func logsSubsystem() async {
        let logs = pocketbase.admin.logs
        let url = await logs.pocketbase.url
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI collections subsystem")
    func collectionsSubsystem() async {
        let collections = pocketbase.admin.collections
        let url = await collections.pocketbase.url
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI settings subsystem")
    func settingsSubsystem() async {
        let settings = pocketbase.admin.settings
        let url = await settings.pocketbase.url
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI backups subsystem")
    func backupsSubsystem() async {
        let backups = pocketbase.admin.backups
        let url = await backups.pocketbase.url
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI health subsystem")
    func healthSubsystem() async {
        let health = pocketbase.admin.health
        let url = await health.pocketbase.url
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI records with collection name")
    func recordsWithCollectionName() async {
        let records = pocketbase.admin.records("posts")
        let collection = await records.collection
        let url = await records.pocketbase.url
        #expect(collection == "posts")
        #expect(url == pocketbase.url)
    }

    @Test("AdminAPI records with different collection names")
    func recordsWithDifferentCollections() async {
        let posts = pocketbase.admin.records("posts")
        let users = pocketbase.admin.records("_superusers")
        let custom = pocketbase.admin.records("my_custom_collection")

        #expect(await posts.collection == "posts")
        #expect(await users.collection == "_superusers")
        #expect(await custom.collection == "my_custom_collection")
    }

    @Test("AdminAPI fluent chaining")
    func fluentChaining() async {
        // Test that fluent API works as expected
        let admin = pocketbase.admin
        let logs = admin.logs
        let collections = admin.collections
        let records = admin.records("test")

        // All should share the same PocketBase instance URL
        #expect(await logs.pocketbase.url == pocketbase.url)
        #expect(await collections.pocketbase.url == pocketbase.url)
        #expect(await records.pocketbase.url == pocketbase.url)
    }
}

@Suite("RecordsAdmin")
struct RecordsAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("RecordsAdmin stores collection name")
    func storesCollectionName() async {
        let records = RecordsAdmin(collection: "posts", pocketbase: pocketbase)
        #expect(await records.collection == "posts")
    }

    @Test("RecordsAdmin stores pocketbase instance")
    func storesPocketbase() async {
        let records = RecordsAdmin(collection: "posts", pocketbase: pocketbase)
        #expect(await records.pocketbase.url == pocketbase.url)
    }
}

@Suite("LogsAdmin")
struct LogsAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("LogsAdmin initialization")
    func initialization() async {
        let logs = LogsAdmin(pocketbase: pocketbase)
        #expect(await logs.pocketbase.url == pocketbase.url)
    }
}

@Suite("CollectionsAdmin")
struct CollectionsAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("CollectionsAdmin initialization")
    func initialization() async {
        let collections = CollectionsAdmin(pocketbase: pocketbase)
        #expect(await collections.pocketbase.url == pocketbase.url)
    }
}

@Suite("SettingsAdmin")
struct SettingsAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("SettingsAdmin initialization")
    func initialization() async {
        let settings = SettingsAdmin(pocketbase: pocketbase)
        #expect(await settings.pocketbase.url == pocketbase.url)
    }
}

@Suite("BackupsAdmin")
struct BackupsAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("BackupsAdmin initialization")
    func initialization() async {
        let backups = BackupsAdmin(pocketbase: pocketbase)
        #expect(await backups.pocketbase.url == pocketbase.url)
    }
}

@Suite("HealthAdmin")
struct HealthAdminTests {

    let pocketbase = PocketBase(url: URL(string: "http://localhost:8090")!)

    @Test("HealthAdmin initialization")
    func initialization() async {
        let health = HealthAdmin(pocketbase: pocketbase)
        #expect(await health.pocketbase.url == pocketbase.url)
    }
}
