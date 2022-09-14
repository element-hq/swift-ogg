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
import AVFoundation

class ConverterTests: XCTestCase {

    func testInvalidSampleRate() {
        let src = Bundle.module.url(forResource: "InvalidSampleRate", withExtension: "ogg")!
        let dest = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.m4a")
        do {
            try OGGConverter.convertOpusOGGToM4aFile(src: src, dest: dest)
            XCTAssert(try dest.checkResourceIsReachable(), "destination m4a file does not exist")
        } catch {
            XCTFail("Failed to convert from ogg to m4a with error \(error)")
        }
    }
    
    func testConversionRoundTrip() {
        let src = Bundle.module.url(forResource: "VoiceRecordingWeb", withExtension: "m4a")!
        let originalDuration = getM4aDuration(src: src)
        let dest = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.ogg")
        let dest2 = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.m4a")
        
        do {
            try OGGConverter.convertM4aFileToOpusOGG(src: src, dest: dest)
            XCTAssert(try dest.checkResourceIsReachable(), "destination ogg file does not exist")
        } catch {
            XCTFail("Failed to convert from m4a to ogg with error \(error)")
        }
        
        do {
            try OGGConverter.convertOpusOGGToM4aFile(src: dest, dest: dest2)
            XCTAssert(try dest2.checkResourceIsReachable(), "destination m4a file does not exist")
        } catch {
            XCTFail("Failed to convert from ogg to m4a with error \(error)")
        }
        let roundTripDuration = getM4aDuration(src: dest2)
        XCTAssertEqual(originalDuration, roundTripDuration, "The duration after the round-trip conversion was not equal to the original file.")
        
    }
    
    private func getM4aDuration(src: URL) -> Int {
        let audioAsset = AVURLAsset(url: src, options: nil)
        let duration = audioAsset.duration
        return Int(CMTimeGetSeconds(duration))
    }
}
