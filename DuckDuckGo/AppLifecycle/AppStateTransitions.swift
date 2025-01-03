//
//  AppStateTransitions.swift
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

import os.log
import Core

extension Init {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .launching(let application, let launchOptions):
            return Launched(application: application, launchOptions: launchOptions)
        default:
            return handleUnexpectedEvent(event)
        }
    }

}

extension Launched {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .activating(let application):
            return Active(application: application)
        case .openURL:
            return self
        case .backgrounding:
            return InactiveBackground()
        case .launching, .suspending:
            return handleUnexpectedEvent(event)
        }
    }

}

extension Active {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .suspending(let application):
            return Inactive(application: application)
        case .openURL:
            return self
        case .launching, .activating, .backgrounding:
            return handleUnexpectedEvent(event)
        }
    }

}

extension Inactive {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .backgrounding(let application):
            return Background(application: application)
        case .activating(let application):
            return Active(application: application)
        case .openURL:
            return self
        case .launching, .suspending:
            return handleUnexpectedEvent(event)
        }
    }

}

extension Background {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .activating(let application):
            return Active(application: application)
        case .openURL:
            return self
        case .backgrounding:
            return DoubleBackground(previousDidEnterBackgroundTimestamp: timestamp, counter: 0)
        case .launching, .suspending:
            return handleUnexpectedEvent(event)
        }
    }

}

extension DoubleBackground {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .activating(let application):
            return Active(application: application)
        case .suspending(let application):
            return Inactive(application: application)
        case .backgrounding(let application):
            return DoubleBackground(previousDidEnterBackgroundTimestamp: currentDidEnterBackgroundTimestamp, counter: counter)
        case .launching, .openURL:
            return self
        }

    }

}

extension InactiveBackground {

    func apply(event: AppEvent) -> any AppState {
        switch event {
        case .activating(let application):
            return Active(application: application)
        case .suspending(let application):
            return Inactive(application: application)
        case .launching, .backgrounding, .openURL:
            return self
        }
    }

}

extension AppEvent {

    var rawValue: String {
        switch self {
        case .launching: return "launching"
        case .activating: return "activating"
        case .backgrounding: return "backgrounding"
        case .suspending: return "suspending"
        case .openURL: return "openURL"
        }
    }

}

extension AppState {

    func handleUnexpectedEvent(_ event: AppEvent) -> Self {
        Logger.lifecycle.error("Invalid transition (\(event.rawValue)) for state (\(type(of: self)))")
        DailyPixel.fireDailyAndCount(pixel: .appDidTransitionToUnexpectedState,
                                     withAdditionalParameters: [PixelParameters.appState: String(describing: type(of: self)),
                                                                PixelParameters.appEvent: event.rawValue])
        return self
    }

}
