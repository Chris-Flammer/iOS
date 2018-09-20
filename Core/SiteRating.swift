//
//  SiteRating.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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

public class SiteRating {

    public enum EncryptionType {
        case unencrypted, mixed, encrypted, forced
    }

    public var domain: String? {
        return url.host
    }
    
    public var scores: Grade.Scores {
        if let scores = cache.get(url: url), scores.site.score > grade.scores.site.score {
            return scores
        }
        return grade.scores
    }

    public let url: URL
    public let protectionId: String
    public let httpsForced: Bool
    public let privacyPractice: PrivacyPractices.Practice
    public let isMajorTrackerNetwork: Bool
    
    public var hasOnlySecureContent: Bool
    public var finishedLoading = false
    public private (set) var trackersDetected = [DetectedTracker: Int]()
    public private (set) var trackersBlocked = [DetectedTracker: Int]()

    let prevalenceStore: PrevalenceStore
    
    private let grade = Grade()
    private let cache = GradeCache.shared
    
    public init(url: URL,
                httpsForced: Bool = false,
                entityMapping: EntityMapping = EntityMapping(),
                privacyPractices: PrivacyPractices = PrivacyPractices(),
                prevalenceStore: PrevalenceStore = EmbeddedPrevalenceStore(),
                protectionId: String = UUID.init().uuidString) {

        Logger.log(text: "new SiteRating(url: \(url), protectionId: \(protectionId))")
        
        let entity = entityMapping.findEntity(forURL: url)

        self.protectionId = protectionId
        self.url = url
        self.httpsForced = httpsForced
        self.prevalenceStore = prevalenceStore
        self.hasOnlySecureContent = url.isHttps()
        self.isMajorTrackerNetwork = prevalenceStore.isMajorNetwork(named: entity)
        self.privacyPractice = privacyPractices.practice(for: url)
        
        // This will change when there is auto upgrade data.  The default is false, but we don't penalise sites at this time so if the url is https
        //  then we assume auto upgrade is available for the purpose of grade scoring.
        self.grade.httpsAutoUpgrade = url.isHttps()
        self.grade.https = url.isHttps()
        self.grade.privacyScore = privacyPractice.score
        
        if let entity = entity {
            self.grade.setParentEntity(named: entity, withPrevalence: prevalenceStore.prevalences[entity])
        }
    }

    public var https: Bool {
        return url.isHttps()
    }

    public var encryptionType: EncryptionType {
        if hasOnlySecureContent {
            return httpsForced ? .forced : .encrypted
        } else if https {
            return .mixed
        }

        return .unencrypted
    }

    public var uniqueMajorTrackerNetworksDetected: Int {
        return uniqueMajorTrackerNetworks(trackers: trackersDetected)
    }

    public var uniqueMajorTrackerNetworksBlocked: Int {
        return uniqueMajorTrackerNetworks(trackers: trackersBlocked)
    }

    public var uniqueTrackerNetworksDetected: Int {
        return uniqueTrackerNetworks(trackers: trackersDetected)
    }

    public var uniqueTrackerNetworksBlocked: Int {
        return uniqueTrackerNetworks(trackers: trackersBlocked)
    }

    public var containsMajorTracker: Bool {
        return trackersDetected.contains(where: majorNetworkFilter)
    }

    public var containsIpTracker: Bool {
        return trackersDetected.contains(where: { $0.key.isIpTracker })
    }

    public func trackerDetected(_ tracker: DetectedTracker) {
        let detectedCount = trackersDetected[tracker] ?? 0
        trackersDetected[tracker] = detectedCount + 1

        let entity = tracker.networkNameForDisplay

        if tracker.blocked {
            let blockCount = trackersBlocked[tracker] ?? 0
            trackersBlocked[tracker] = blockCount + 1
            grade.addEntityBlocked(named: entity, withPrevalence: prevalenceStore.prevalences[entity])
        } else {
            grade.addEntityNotBlocked(named: entity, withPrevalence: prevalenceStore.prevalences[entity])
        }
    }

    public var uniqueTrackersDetected: Int {
        return trackersDetected.count
    }

    public var uniqueTrackersBlocked: Int {
        return trackersBlocked.count
    }

    public var totalTrackersDetected: Int {
        return trackersDetected.reduce(0) { $0 + $1.value }
    }

    public var totalTrackersBlocked: Int {
        return trackersBlocked.reduce(0) { $0 + $1.value }
    }

    public var majorNetworkTrackersDetected: [DetectedTracker: Int] {
        return trackersDetected.filter(majorNetworkFilter)
    }

    public var majorNetworkTrackersBlocked: [DetectedTracker: Int] {
        return trackersBlocked.filter(majorNetworkFilter)
    }

    private func uniqueMajorTrackerNetworks(trackers: [DetectedTracker: Int]) -> Int {
        let trackers = trackers
            .filter(majorNetworkFilter)
            .keys
            .compactMap({ $0.networkName })
        return Set(trackers).count
    }

    private func uniqueTrackerNetworks(trackers: [DetectedTracker: Int]) -> Int {
        return Set(trackers.keys.compactMap({ $0.networkName ?? $0.domain })).count
    }

    private func majorNetworkFilter(trackerDetected: (DetectedTracker, Int)) -> Bool {
        return prevalenceStore.isMajorNetwork(named: trackerDetected.0.networkName)
    }

}
