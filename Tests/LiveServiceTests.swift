//
//  LiveServiceTests.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import XCTest
import PromiseKit
import PMKAlamofire
@testable import Hemlock

/// These tests run against the live service configured in testAccount.json.
/// Don't do anything crazy here.
class LiveServiceTests: XCTestCase {
    
    //MARK: - properties
    
    let configFile = "TestUserData/testAccount" // .json
    var account: Account?
    var username = "" //read from testAccount.json
    var password = "" //read from testAccount.json
    var homeOrgID = 1 //read from testAccount.json
    var sampleRecordID: Int? //read from testAccount.json
    var authtoken: String?
    let consortiumOrgID = 1 // assumption
    
    //MARK: - functions
    
    override func setUp() {
        super.setUp()
        
        // read configFile as json
        let testBundle = Bundle(for: type(of: self))
        guard
            let path = testBundle.path(forResource: configFile, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any],
            let url = jsonObject["url"] as? String,
            let username = jsonObject["username"] as? String,
            let password = jsonObject["password"] as? String else
        {
            XCTFail("unable to read JSON data from \(configFile).json, see TestUserData/README.md")
            return
        }
        if let homeOrgID = jsonObject["homeOrgID"] as? Int {
            self.homeOrgID = homeOrgID
        }
        self.sampleRecordID = jsonObject["sampleRecordID"] as? Int
        App.library = Library(url)
        account = Account(username, password: password)
    }
    
    //MARK: - Promise tests
    
    // Test a basic promise chain, it does not actually login
    // but it goes through the mechanics of logging in.
    func test_promiseBasic() {
        let expectation = XCTestExpectation(description: "async response")
        
        let args: [Any] = [account!.username]
        let req = Gateway.makeRequest(service: API.auth, method: API.authInit, args: args)
        req.responseJSON().then { (json: Any, response: PMKAlamofireDataResponse) -> Promise<(json: Any, response: PMKAlamofireDataResponse)> in
            print("then: \(json)")
            let objectParam = ["type": "opac",
                               "username": self.account!.username,
                               "password": "badbeef"]
            return Gateway.makeRequest(service: API.auth, method: API.authComplete, args: [objectParam]).responseJSON()
        }.done { (json,response) in
            print("done: \(json)")
            expectation.fulfill()
        }.ensure {
            // nada
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    // Test successful login using a promise chain
    func test_gatewayPromise() {
        let expectation = XCTestExpectation(description: "async response")
        
        let args: [Any] = [account!.username]
        let req = Gateway.makeRequest(service: API.auth, method: API.authInit, args: args)
        req.gatewayResponse().then { (resp: GatewayResponse, pmkresp: PMKAlamofireDataResponse) -> Promise<(resp: GatewayResponse, pmkresp: PMKAlamofireDataResponse)> in
            print("resp: \(resp)")
            // todo: refactor to Account.loginContinue(authInitReponse:)
            guard let nonce = resp.str else {
                throw HemlockError.unexpectedNetworkResponse("expected string")
            }
            let password = md5(nonce + md5((self.account?.password)!))
            let objectParam = ["type": "opac",
                               "username": self.account!.username,
                               "password": password]
            return Gateway.makeRequest(service: API.auth, method: API.authComplete, args: [objectParam]).gatewayResponse()
        }.done { (resp, pmkresp) in
            print("resp: \(resp)")
            try self.account?.loadFromAuthResponse(resp.obj)
            print("here")
            expectation.fulfill()
        }.ensure {
            print("no ensure today")
        }.catch { error in
            print("error: \(error)")
            let desc = error.localizedDescription
            print("desc: \(desc)")
            XCTFail(desc)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        print("ok")
    }

    //MARK: - LoginController Tests

    func test_LoginController_success() {
        let expectation = XCTestExpectation(description: "async response")
        LoginController(for: account!).login { resp in
            XCTAssertFalse(resp.failed, String(describing: resp.error))
            XCTAssertNotNil(self.account?.authtoken)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_LoginController_failure() {
        let expectation = XCTestExpectation(description: "async response")
        let altAccount = Account(username, password: "bogus")
        LoginController(for: altAccount).login { resp in
            XCTAssertTrue(resp.failed, String(describing: resp.error))
            XCTAssertNil(altAccount.authtoken)
            XCTAssertNotNil(resp.error)
            XCTAssertEqual(resp.errorMessage, "User login failed")

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_LoginController_getSession() {
        let parser = IDLParser(contentsOf: URL(string: Gateway.idlURL())!)
        let ok = parser.parse()
        XCTAssertTrue(ok)

        let expectation = XCTestExpectation(description: "async response")
        LoginController(for: account!).login { resp in
            XCTAssertFalse(resp.failed, String(describing: resp.error))
            XCTAssertNotNil(self.account?.authtoken)
            LoginController.getSession(self.account!) { resp in
                debugPrint(resp)
                for key in (resp.obj?.dict.keys)! {
                    let val = resp.obj?.dict[key]
                    print("\(key) -> \(String(describing: val))")
                }
                let deleted = resp.obj?.getBool("deleted")
                XCTAssertFalse(deleted!)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - IDL
    
    func test_parseIDL_subset() {
        self.measure {
            let url = Gateway.idlURL()
            let parser = IDLParser(contentsOf: URL(string: url)!)
            let ok = parser.parse()
            XCTAssertTrue(ok)
            XCTAssertGreaterThan(OSRFCoder.registryCount(), 1)
        }
    }
    
    //MARK: - orgTypesRetrieve
    
    func test_orgTypesRetrieve() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = ActorService.fetchOrgTypesArray()
        promise.ensure {
            let orgTypes = OrgType.orgTypes
            XCTAssert(orgTypes.count > 0, "found some org types")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - orgTreeRetrieve
    
    func test_orgTreeRetrieve() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = ActorService.fetchOrgTree()
        promise.ensure {
            let org = Organization.find(byId: 1)
            XCTAssertNotNil(org)
            XCTAssertNotNil(org?.name)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - orgUnitSetting
    
    func test_orgUnitSetting() {
        let expectation = XCTestExpectation(description: "async response")

        let orgID = self.homeOrgID
        let setting = API.settingSMSEnable
//        let setting = API.settingNotPickupLib
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSetting, args: [orgID, setting, API.anonymousAuthToken])
        req.gatewayOptionalObjectResponse().done { obj in
            let value = obj?.getBool("value")
            print("org \(orgID) setting \(setting) value \(String(describing: value))")
            XCTAssertNotNil(value, "this assertion is not 100% but it is true of my settings")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_orgUnitSettingBatch() {
        let expectation = XCTestExpectation(description: "async response")
        
        let orgID = self.homeOrgID
        let settings = [API.settingNotPickupLib, API.settingSMSEnable]
        var notPickupLib = false
        var smsEnable = false
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [orgID, settings, API.anonymousAuthToken])
        req.gatewayOptionalObjectResponse().done { obj in
            if let settingObj = obj?.getObject(API.settingNotPickupLib),
                let settingValue = settingObj.getBool("value")
            {
                notPickupLib = settingValue
            }
            if let settingObj = obj?.getObject(API.settingSMSEnable),
                let settingValue = settingObj.getBool("value")
            {
                smsEnable = settingValue
            }
            print("org \(orgID) setting \(API.settingNotPickupLib) value \(notPickupLib)")
            print("org \(orgID) setting \(API.settingSMSEnable) value \(smsEnable)")
            XCTAssertFalse(notPickupLib, "this assertion is not 100% but it is true of my settings")
            XCTAssertTrue(smsEnable, "this assertion is not 100% but it is true of my settings")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - sms carriers

    func test_fetchSMSCarriers() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = PCRUDService.fetchSMSCarriers()
        promise.ensure {
            let carriers = SMSCarrier.getSpinnerLabels()
            for l in carriers {
                print ("carrier: \(l)")
            }
            XCTAssertGreaterThan(carriers.count, 0)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - Copy Status

    func test_copyStatusAll() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = SearchService.fetchCopyStatusAll()
        print("xxx promise made")
        promise.ensure {
            XCTAssertGreaterThan(CopyStatus.status.count, 0)
            expectation.fulfill()
        }.catch { error in
            print("xxx promise caught")
            let str = error.localizedDescription
            print("xxx \(str)")
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_copySummary() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = SearchService.fetchCopySummary(orgID: self.consortiumOrgID, recordID: self.sampleRecordID!)
        promise.done { array in
            let copyCounts = CopySummary.makeArray(fromArray: array)
            XCTAssertGreaterThan(copyCounts.count, 0)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }

    //MARK: - actorCheckedOut
    
    /* Can't enable this test until we have IDL for the au class
    func test_actorCheckedOut_basic() {
     static let orgTreeRetrieve = "open-ils.actor"
        LoginController(for: account!).login { resp in
            guard let authtoken = self.account?.authtoken,
                let userID = self.account?.userID else
            {
                XCTFail()
                expectation.fulfill()
                return
            }
            let request = Gateway.createRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userID])
            request.responseData { response in
                print("response: \(response.description)")
                XCTAssertTrue(response.result.isSuccess)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    */
}
