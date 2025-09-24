//
//  PurpleTests.swift
//  PurpleTests
//
//  Created by Jimmy Bosse on 9/20/25.
//

import Testing
import SwiftData
@testable import Purple

struct PurpleTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testGroupCreation() async throws {
        let group = Group(name: "Test Group", colorName: "blue", iconName: "folder", sortOrder: 1)
        
        #expect(group.name == "Test Group")
        #expect(group.colorName == "blue")
        #expect(group.iconName == "folder")
        #expect(group.sortOrder == 1)
        #expect(group.id != UUID())
    }
    
    @Test func testOTPAccountWithGroup() async throws {
        let group = Group(name: "Work", colorName: "orange", iconName: "building.2")
        let account = OTPAccount(
            serviceName: "GitHub",
            accountName: "work@company.com",
            secretKeyIdentifier: "test-key-id",
            group: group
        )
        
        #expect(account.serviceName == "GitHub")
        #expect(account.accountName == "work@company.com")
        #expect(account.group?.name == "Work")
        #expect(account.group?.colorName == "orange")
    }
    
    @Test func testOTPAccountWithoutGroup() async throws {
        let account = OTPAccount(
            serviceName: "Personal",
            accountName: "personal@gmail.com",
            secretKeyIdentifier: "test-key-id"
        )
        
        #expect(account.group == nil)
        #expect(account.serviceName == "Personal")
    }

}
