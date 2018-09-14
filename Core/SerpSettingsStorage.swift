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

import Foundation

class SerpSettingsStorage {

    struct Constants {
        static let oldCookieStorageKey = "com.duckduckgo.allowedCookies"
        static let serpSettingsKey = "com.duckduckgo.serp.settings"
    }

    private var userDefaults: UserDefaults

    var settings: [String: String] {
        return userDefaults.object(forKey: Constants.serpSettingsKey) as? [String: String] ?? [:]
    }

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        userDefaults.removeObject(forKey: Constants.oldCookieStorageKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: Constants.serpSettingsKey)
    }

    func addSetting(name: String, value: String) {
        var settings = self.settings
        settings[name] = value
        userDefaults.set(settings, forKey: Constants.serpSettingsKey)
    }

    func settingsNeedUpdating(in url: URL) -> Bool {
        return settings.contains(where: { url.getParam(name: $0.key) != $0.value })
    }

}
