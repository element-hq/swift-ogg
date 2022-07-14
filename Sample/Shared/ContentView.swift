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

import SwiftUI
import SwiftOGG
import AVFoundation

struct ContentView: View {
    var body: some View {
        Button("Convert!") {
            testConversionRoundTrip()
        }
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func testConversionRoundTrip() {
    let src = Bundle.main.url(forResource: "VoiceRecordingWeb", withExtension: "m4a")!
    let originalDuration = getM4aDuration(src: src)
    let dest = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.ogg")
    let dest2 = URL(fileURLWithPath: NSTemporaryDirectory() + "VoiceRecordingWebOut.m4a")
    
    do {
        try OGGConverter.convertM4aFileToOpusOGG(src: src, dest: dest)
    } catch {
        print(false, "Failed to convert from m4a to ogg with error \(error)")
    }
    
    do {
        try OGGConverter.convertOpusOGGToM4aFile(src: dest, dest: dest2)
    } catch {
        print(false, "Failed to convert from ogg to m4a with error \(error)")
    }
    let roundTripDuration = getM4aDuration(src: dest2)
    print("roundTripDuration", originalDuration, roundTripDuration)
    
}

private func getM4aDuration(src: URL) -> Int {
    let audioAsset = AVURLAsset(url: src, options: nil)
    let duration = audioAsset.duration
    return Int(CMTimeGetSeconds(duration))
}
