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

import Foundation
import AVFAudio
import AVFoundation

public enum OGGConverterError: Error {
    case failedToCreateAVAudioChannelLayout
    case failedToCreatePCMBuffer
    case other(Error)
}

public class OGGConverter {

    public static func convertOpusOGGToM4aFile(src: URL, dest: URL) throws {
        do {
            let data = try Data(contentsOf: src)
            let decoder = try OGGDecoder(audioData: data)
            guard let layout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Mono) else { throw OGGConverterError.failedToCreateAVAudioChannelLayout }
            
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(decoder.sampleRate), interleaved: false, channelLayout: layout)
            guard let buffer = decoder.pcmData.toPCMBuffer(format: format) else { throw OGGConverterError.failedToCreatePCMBuffer }
            var settings: [String : Any] = [:]

            settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
            settings[AVSampleRateKey] = buffer.format.sampleRate
            settings[AVNumberOfChannelsKey] = 1
            settings[AVLinearPCMIsFloatKey] = (buffer.format.commonFormat == .pcmFormatFloat32)

            let destFile = try AVAudioFile(forWriting: dest, settings: settings, commonFormat: buffer.format.commonFormat, interleaved: buffer.format.isInterleaved)
            try destFile.write(from: buffer)
        } catch let error as OGGConverterError  {
            throw error
        } catch {
            // wrap lower level errors
            throw OGGConverterError.other(error)
        }
    }
    
    public static func convertM4aFileToOpusOGG(src: URL, dest: URL) throws {
        do {
            let srcFile = try AVAudioFile(
                forReading: src,
                commonFormat: .pcmFormatInt16,
                interleaved: false
            )
            let format = srcFile.processingFormat
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(srcFile.length)
            ) else { throw OGGConverterError.failedToCreatePCMBuffer }
            try srcFile.read(into: buffer)
            let streamDescription = srcFile.processingFormat.streamDescription.pointee
            let encoder = try OGGEncoder(format: streamDescription, opusRate: Int32(srcFile.processingFormat.sampleRate), application: .audio)
            
            let channels = UnsafeBufferPointer(start: buffer.int16ChannelData, count: 1)
            let length = Int(buffer.frameCapacity * buffer.format.streamDescription.pointee.mBytesPerFrame)
            let data = Data(bytes: channels[0], count: length)
            try encoder.encode(pcm: data)
            let opus = encoder.bitstream(flush: true)
            try opus.write(to: dest)
        } catch let error as OGGConverterError  {
            throw error
        } catch {
            // wrap lower level errors
            throw OGGConverterError.other(error)
        }
    }
}

extension Data {
  func toPCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let streamDesc = format.streamDescription.pointee
    let frameCapacity = UInt32(count) / streamDesc.mBytesPerFrame
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else { return nil }

    buffer.frameLength = buffer.frameCapacity
    let audioBuffer = buffer.audioBufferList.pointee.mBuffers
    guard let mData = audioBuffer.mData else { return nil }
      withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
        if let addr = rawBufferPointer.baseAddress {
            mData.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
        }
    }
    return buffer
  }
}
