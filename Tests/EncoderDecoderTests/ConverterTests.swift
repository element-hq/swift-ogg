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

class EncoderTests: XCTestCase {

    func testConvertToM4a() {
        let url = Bundle.module.url(forResource: "VoiceRecordingWeb", withExtension: "ogg")!
        let dirPath = NSTemporaryDirectory() + "VoiceRecdingWebOut.m4a"
        let destUrl = URL(fileURLWithPath: dirPath)
        try! OGGConverter.convertOpusOGGToM4aFile(src: url, dest: destUrl)
    }
    
    func testConvertToOGG() {
        let url = Bundle.module.url(forResource: "VoiceRecordingWeb", withExtension: "m4a")!
        let dirPath = NSTemporaryDirectory() + "VoiceRecdingWebOut.ogg"
        let destUrl = URL(fileURLWithPath: dirPath)
        try! OGGConverter.convertM4aFileToOpusOGG(src: url, dest: destUrl)
    }

}
