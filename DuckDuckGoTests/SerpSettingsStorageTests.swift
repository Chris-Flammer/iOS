//
//  SerpSettingsStorage.swift
//  DuckDuckGo
//
//  Copyright © 2018 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import WebKit
import XCTest
@testable import Core

class SerpSettingsStorageTests: XCTestCase {

    var testee: SerpSettingsStorage!
    let testGroupName = "test"

    var userDefaults: UserDefaults {
        return UserDefaults(suiteName: testGroupName)!
    }

    override func setUp() {
        userDefaults.removePersistentDomain(forName: testGroupName)
        testee = SerpSettingsStorage(userDefaults: userDefaults)
    }

    func testWhenInitialisedThenDeletesStoredCookies() {

        userDefaults.set("test", forKey: SerpSettingsStorage.Constants.oldCookieStorageKey)
        _ = SerpSettingsStorage(userDefaults: userDefaults)
        XCTAssertNil(userDefaults.value(forKey: SerpSettingsStorage.Constants.oldCookieStorageKey))

    }

    func testWhenSettingsMatchThenReturnsFalse() {
        let url = URL(string: "http://www.example.com?x=1&y=2")!
        testee.addSetting(name: "x", value: "1")
        testee.addSetting(name: "y", value: "2")
        XCTAssertFalse(testee.settingsNeedUpdating(in: url))
    }

    func testWhenSettingsDontMatchThenReturnsTrue() {
        let url = URL(string: "http://www.example.com?x=1&y=1")!
        testee.addSetting(name: "x", value: "1")
        testee.addSetting(name: "y", value: "2")
        XCTAssertTrue(testee.settingsNeedUpdating(in: url))
    }

    func testWhenSettingsMissingThenReturnsTrue() {
        let url = URL(string: "http://www.example.com?x=1")!
        testee.addSetting(name: "x", value: "1")
        testee.addSetting(name: "y", value: "2")
        XCTAssertTrue(testee.settingsNeedUpdating(in: url))
    }

    func testWhenMultipleCookiesAreSetThenClearCookiesOnNewInstanceClearsAll() {
        testee.addSetting(name: "name", value: "value")
        testee.addSetting(name: "name2", value: "value2")
        testee = SerpSettingsStorage(userDefaults: userDefaults)
        testee.clear()
        XCTAssertTrue(testee.settings.isEmpty)
    }

    func testWhenMultipleCookiesAreSetBetweenInstancesThenCookiesCountMatches() {
        testee.addSetting(name: "name", value: "value")
        testee = SerpSettingsStorage(userDefaults: userDefaults)
        testee.addSetting(name: "name2", value: "value2")
        XCTAssertEqual(testee.settings.count, 2)
    }

    func testWhenMultipleCookieIsSetThenClearRemovesIt() {
        testee.addSetting(name: "name", value: "value")
        testee.clear()
        XCTAssertTrue(testee.settings.isEmpty)
    }

    func testWhenMultipleCookiesAreSetThenCookiesCountMatches() {
        testee.addSetting(name: "name", value: "value")
        testee.addSetting(name: "name2", value: "value2")
        XCTAssertEqual(testee.settings.count, 2)
    }

    func testWhenCookieIsSetThenCookiesContainsIt() {
        testee.addSetting(name: "name", value: "value")

        XCTAssertEqual(testee.settings.count, 1)
        XCTAssertEqual(testee.settings.first?.key, "name")
        XCTAssertEqual(testee.settings.first?.value, "value")

    }

    func testWhenNewThenCookiesIsEmpty() {
        XCTAssertTrue(testee.settings.isEmpty)
    }

    private func cookie(_ name: String, _ value: String) -> HTTPCookie {
        return HTTPCookie(properties: [.name: name, .value: value, .path: "/", .domain: "example.com"])!
    }

}
