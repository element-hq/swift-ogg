//
// Copyright 2022 Vector Creations Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
import SwiftOGG

class ConverterTests: XCTestCase {

    func testConversionRoundTrip() {
        let url = Bundle.module.url(forResource: "VoiceRecordingWeb", withExtension: "m4a")!
        let destUrl = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.ogg")
        let dest2Url = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.m4a")
        
        do {
            try OGGConverter.convertM4aFileToOpusOGG(src: url, dest: destUrl)
            XCTAssert(try destUrl.checkResourceIsReachable(), "destination ogg file does not exist")
        } catch {
            XCTAssert(false, "Failed to convert from m4a to ogg with error \(error)")
        }
        
        do {
            try OGGConverter.convertOpusOGGToM4aFile(src: destUrl, dest: dest2Url)
            XCTAssert(try dest2Url.checkResourceIsReachable(), "destination m4a file does not exist")
        } catch {
            XCTAssert(false, "Failed to convert from ogg to m4a with error \(error)")
        }
    }
}
