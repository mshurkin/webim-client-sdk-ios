//
//  SQLiteHistoryStorageTests.swift
//  WebimClientLibrary_Tests
//
//  Created by Nikita Lazarev-Zubov on 20.02.18.
//  Copyright © 2018 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
@testable import WebimClientLibrary
import XCTest

class SQLiteHistoryStorageTests: XCTestCase {
    
    // MARK: - Constants
    private static let DB_NAME = "test"
    private static let SERVER_URL_STRING = "https://demo.webim.ru"
    
    // MARK: - Properties
    var sqLiteHistoryStorage: SQLiteHistoryStorage?
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        let queue = DispatchQueue.main
        let exeIfNotDestroyedHandlerExecutor = ExecIfNotDestroyedHandlerExecutor(sessionDestroyer: SessionDestroyer(),
                                                                                 queue: queue)
        let internalErrorListener = InternalErrorListenerForTests()
        let actionRequestLoop = ActionRequestLoopForTests(completionHandlerExecutor: exeIfNotDestroyedHandlerExecutor,
                                                          internalErrorListener: internalErrorListener)
        sqLiteHistoryStorage = SQLiteHistoryStorage(dbName: SQLiteHistoryStorageTests.DB_NAME,
                                                    serverURL: SQLiteHistoryStorageTests.DB_NAME,
                                                    webimClient: WebimClient(withActionRequestLoop: actionRequestLoop,
                                                                             deltaRequestLoop: DeltaRequestLoop(deltaCallback: DeltaCallback(currentChatMessageMapper: CurrentChatMapper(withServerURLString: SQLiteHistoryStorageTests.SERVER_URL_STRING)),
                                                                                                                completionHandlerExecutor: exeIfNotDestroyedHandlerExecutor,
                                                                                                                sessionParametersListener: nil,
                                                                                                                internalErrorListener: internalErrorListener,
                                                                                                                baseURL: SQLiteHistoryStorageTests.SERVER_URL_STRING,
                                                                                                                title: "Title",
                                                                                                                location: "mobile",
                                                                                                                appVersion: nil,
                                                                                                                visitorFieldsJSONString: nil,
                                                                                                                providedAuthenticationTokenStateListener: nil,
                                                                                                                providedAuthenticationToken: nil,
                                                                                                                deviceID: "ID",
                                                                                                                deviceToken: nil,
                                                                                                                visitorJSONString: nil,
                                                                                                                sessionID: nil,
                                                                                                                authorizationData: nil),
                                                                             webimActions: WebimActions(baseURL: SQLiteHistoryStorageTests.SERVER_URL_STRING,
                                                                                                        actionRequestLoop: actionRequestLoop)),
                                                    reachedHistoryEnd: true,
                                                    queue: queue)
    }
    
    override func tearDown() {
        let fileManager = FileManager.default
        let documentsPath = try! fileManager.url(for: .documentDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil,
                                                 create: false)
        let dbPath = "\(documentsPath)/\(SQLiteHistoryStorageTests.DB_NAME)"
        do {
            try fileManager.removeItem(at: URL(string: dbPath)!)
        } catch let error {
            print("DB file deletion failed with error: " + error.localizedDescription)
        }
        
        super.tearDown()
    }
    
    // MARK: Private methods
    private static func generateMessages(ofCount numberOfMessages: Int) -> [MessageImpl] {
        var messages = [MessageImpl]()
        
        for index in 1 ... numberOfMessages {
            messages.append(MessageImpl(serverURLString: SQLiteHistoryStorageTests.SERVER_URL_STRING,
                                        id: String(index),
                                        operatorID: "1",
                                        senderAvatarURLString: nil,
                                        senderName: "Name",
                                        type: MessageType.OPERATOR,
                                        data: nil,
                                        text: "Text",
                                        timeInMicrosecond: Int64(index * 1_000_000_000_000),
                                        attachment: nil,
                                        historyMessage: true,
                                        internalID: String(index),
                                        rawText: nil))
        }
        
        return messages
    }
    
    // MARK: - Tests
    
    func testGetMajorVersion() {
        XCTAssertEqual(sqLiteHistoryStorage!.getMajorVersion(),
                       1)
    }
    
    func testGetFullHistory() {
        let messagesCount = 10
        sqLiteHistoryStorage!.receiveHistoryBefore(messages: SQLiteHistoryStorageTests.generateMessages(ofCount: messagesCount),
                                                   hasMoreMessages: false)
        
        let expectation = XCTestExpectation()
        var gettedMessages = [Message]()
        sqLiteHistoryStorage!.getFullHistory() { messages in
            gettedMessages = messages
            
            expectation.fulfill()
        }
        wait(for: [expectation],
             timeout: 1.0)
        
        XCTAssertEqual(gettedMessages.count,
                       messagesCount)
    }
    
    func testGetLatestHistory() {
        let messagesCount = 10
        sqLiteHistoryStorage!.receiveHistoryBefore(messages: SQLiteHistoryStorageTests.generateMessages(ofCount: messagesCount),
                                                   hasMoreMessages: false)
        
        let messagesLimit = 3
        let expectation = XCTestExpectation()
        var gettedMessages = [Message]()
        sqLiteHistoryStorage!.getLatestHistory(byLimit: messagesLimit) { messages in
            expectation.fulfill()
            gettedMessages = messages
        }
        wait(for: [expectation],
             timeout: 1.0)
        
        XCTAssertEqual(gettedMessages.count,
                       messagesLimit)
        
        let timestampArray = gettedMessages.map() { $0.getTime() }
        let thresholdTimestamp = Date(timeIntervalSince1970: TimeInterval((messagesCount - messagesLimit) * 1_000_000))
        for timestamp in timestampArray {
            XCTAssertTrue(timestamp > thresholdTimestamp)
        }
    }
    
    func testGetHistoryBefore() {
        let messagesCount = 10
        sqLiteHistoryStorage!.receiveHistoryBefore(messages: SQLiteHistoryStorageTests.generateMessages(ofCount: messagesCount),
                                                   hasMoreMessages: false)
        
        let messagesLimit = 3
        let beforeID = 5
        let expectation = XCTestExpectation()
        var gettedMessages = [Message]()
        sqLiteHistoryStorage!.getHistoryBefore(id: HistoryID(dbID: String(beforeID),
                                                             timeInMicrosecond: Int64(beforeID * 1_000_000_000_000)),
                                               limitOfMessages: messagesLimit) { messages in
                                                gettedMessages = messages
                                                
                                                expectation.fulfill()
        }
        wait(for: [expectation],
             timeout: 1.0)
        
        XCTAssertEqual(gettedMessages.count,
                       messagesLimit)
        
        let timestampArray = gettedMessages.map() { $0.getTime() }
        let lowerThresholdTimestamp = Date(timeIntervalSince1970: TimeInterval((beforeID - messagesLimit - 1)) * 1_000_000)
        let upperThresholdTimestamp = Date(timeIntervalSince1970: TimeInterval(beforeID * 1_000_000))
        for timestamp in timestampArray {
            XCTAssertTrue(timestamp > lowerThresholdTimestamp)
            XCTAssertTrue(timestamp < upperThresholdTimestamp)
        }
    }
    
}