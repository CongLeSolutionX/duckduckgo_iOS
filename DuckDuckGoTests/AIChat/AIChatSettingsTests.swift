//
//  AIChatSettingsTests.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

import XCTest
@testable import Core
@testable import DuckDuckGo
import BrowserServicesKit
import Combine

class AIChatSettingsTests: XCTestCase {

    private var mockPrivacyConfigurationManager: PrivacyConfigurationManagerMock!
    private var mockInternalUserDecider: MockInternalUserDecider!
    private var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockPrivacyConfigurationManager = PrivacyConfigurationManagerMock()
        mockInternalUserDecider = MockInternalUserDecider()
        mockUserDefaults = UserDefaults(suiteName: "TestDefaults")
    }

    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "TestDefaults")
        mockPrivacyConfigurationManager = nil
        mockInternalUserDecider = nil
        mockUserDefaults = nil
        super.tearDown()
    }

    func testAIChatURLReturnsDefaultWhenRemoteSettingsMissing() {
        let settings = AIChatSettings(privacyConfigurationManager: mockPrivacyConfigurationManager,
                                      internalUserDecider: mockInternalUserDecider,
                                      userDefaults: mockUserDefaults)

        (mockPrivacyConfigurationManager.privacyConfig as? PrivacyConfigurationMock)?.settings = [:]

        let expectedURL = URL(string: AIChatSettings.SettingsValue.aiChatURL.defaultValue)!
        XCTAssertEqual(settings.aiChatURL, expectedURL)
    }

    func testAIChatURLReturnsRemoteSettingWhenAvailable() {
        let settings = AIChatSettings(privacyConfigurationManager: mockPrivacyConfigurationManager,
                                      internalUserDecider: mockInternalUserDecider,
                                      userDefaults: mockUserDefaults)

        let remoteURL = "https://example.com/ai-chat"
        (mockPrivacyConfigurationManager.privacyConfig as? PrivacyConfigurationMock)?.settings = [
            .aiChat: [AIChatSettings.SettingsValue.aiChatURL.rawValue: remoteURL]
        ]

        XCTAssertEqual(settings.aiChatURL, URL(string: remoteURL))
    }

    func testIsAIChatFeatureEnabledWhenFeatureIsEnabled() {
        let settings = AIChatSettings(privacyConfigurationManager: mockPrivacyConfigurationManager,
                                      internalUserDecider: mockInternalUserDecider,
                                      userDefaults: mockUserDefaults)

        (mockPrivacyConfigurationManager.privacyConfig as? PrivacyConfigurationMock)?.enabledFeaturesForVersions = [
            .aiChat: [AppVersionProvider().appVersion() ?? ""]
        ]

        XCTAssertTrue(settings.isAIChatFeatureEnabled)
    }

    func testIsAIChatFeatureEnabledForInternalUser() {
        let settings = AIChatSettings(privacyConfigurationManager: mockPrivacyConfigurationManager,
                                      internalUserDecider: mockInternalUserDecider,
                                      userDefaults: mockUserDefaults)

        mockInternalUserDecider.mockIsInternalUser = true
        XCTAssertTrue(settings.isAIChatFeatureEnabled)
    }

    func testEnableAIChatBrowsingMenuUserSettings() {
        let settings = AIChatSettings(privacyConfigurationManager: mockPrivacyConfigurationManager,
                                      internalUserDecider: mockInternalUserDecider,
                                      userDefaults: mockUserDefaults)

        (mockPrivacyConfigurationManager.privacyConfig as? PrivacyConfigurationMock)?.enabledFeaturesForVersions = [
            .aiChat: [AppVersionProvider().appVersion() ?? ""]
        ]

        (mockPrivacyConfigurationManager.privacyConfig as? PrivacyConfigurationMock)?.enabledSubfeaturesForVersions = [
            AIChatSubfeature.browsingToolbarShortcut.rawValue: [AppVersionProvider().appVersion() ?? ""]
        ]
        settings.enableAIChatBrowsingMenuUserSettings(enable: false)
        XCTAssertFalse(settings.isAIChatBrowsingToolbarShortcutFeatureEnabled)

        settings.enableAIChatBrowsingMenuUserSettings(enable: true)
        XCTAssertTrue(settings.isAIChatBrowsingToolbarShortcutFeatureEnabled)
    }
}


final private class MockInternalUserDecider: InternalUserDecider {
    var mockIsInternalUser: Bool = false
    var mockIsInternalUserPublisher: AnyPublisher<Bool, Never> {
        Just(mockIsInternalUser).eraseToAnyPublisher()
    }

    var isInternalUser: Bool {
        return mockIsInternalUser
    }

    var isInternalUserPublisher: AnyPublisher<Bool, Never> {
        return mockIsInternalUserPublisher
    }

    @discardableResult
    func markUserAsInternalIfNeeded(forUrl url: URL?, response: HTTPURLResponse?) -> Bool {
        return mockIsInternalUser
    }
}