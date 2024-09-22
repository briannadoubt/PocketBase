//
//  PocketBaseDemoUITests.swift
//  PocketBaseDemoUITests
//
//  Created by Brianna Zamora on 8/7/24.
//

import XCTest

final class PocketBaseDemoUITests: XCTestCase {
    @MainActor
    func testLogin() throws {
        let app = XCUIApplication()
        app.launch()
        
        let username = app.textFields["Username"]
        guard username.waitForExistence(timeout: 10) else {
            XCTFail("Missing Username Field")
            return
        }
        username.tap()
        username.typeText("meowface")
        
        let password = app.secureTextFields["Password"]
        guard password.waitForExistence(timeout: 10) else {
            XCTFail("Missing Password Field")
            return
        }
        password.tap()
        password.typeText("Test1234\n")
        
        let loginButton = app.buttons["btn_login"]
        guard loginButton.waitForExistence(timeout: 10) else {
            XCTFail("Missing Login Button")
            return
        }
        loginButton.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
