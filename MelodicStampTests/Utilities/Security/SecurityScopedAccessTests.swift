//
//  SecurityScopedAccessTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Testing

@Suite struct SecurityScopedAccessTests {
    @Test func stopsAccessWhenStartSucceeds() {
        var startCount = 0
        var stopCount = 0
        var didRunBody = false

        let access = SecurityScopedAccess(
            startAccessing: {
                startCount += 1
                return true
            },
            stopAccessing: {
                stopCount += 1
            },
            isReachable: {
                false
            }
        )

        let result = access.perform {
            didRunBody = true
            return 42
        }

        #expect(result == 42)
        #expect(didRunBody)
        #expect(startCount == 1)
        #expect(stopCount == 1)
    }

    @Test func usesReachabilityWithoutStoppingUnstartedScope() {
        var stopCount = 0

        let access = SecurityScopedAccess(
            startAccessing: {
                false
            },
            stopAccessing: {
                stopCount += 1
            },
            isReachable: {
                true
            }
        )

        let result = access.perform {
            "reachable"
        }

        #expect(result == "reachable")
        #expect(stopCount == 0)
    }

    @Test func skipsBodyWhenAccessIsUnavailable() {
        var didRunBody = false

        let access = SecurityScopedAccess(
            startAccessing: {
                false
            },
            stopAccessing: {},
            isReachable: {
                false
            }
        )

        let result: Int? = access.perform {
            didRunBody = true
            return 42
        }

        #expect(result == nil)
        #expect(!didRunBody)
    }
}
