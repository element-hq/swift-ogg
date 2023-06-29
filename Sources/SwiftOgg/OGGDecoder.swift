/**
 * (C) Copyright IBM Corp. 2016, 2021.
 * (C) Copyright 2022 Vector Creations Ltd
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import Copus
import COgg
import Copustools

class OGGDecoder {

    var sampleRate: Int32 = 48000       // sample rate for decoding. default value by Opus is 48000
    var pcmData = Data()                // decoded pcm data
    
    // swiftlint:disable:next type_name
    private typealias opus_decoder = OpaquePointer
    // swiftlint:disable:next identifier_name
    private let MAX_FRAME_SIZE = Int32(960 * 6)

    private var streamState: ogg_stream_state   // state of ogg stream
    private var page: ogg_page                  // encapsulates the data for an Ogg page
    private var syncState: ogg_sync_state       // tracks the status of data during decoding
    private var packet: ogg_packet              // packet within a stream passing information
    private var header: OpusHeader              // header of the Opus file to decode
    private var decoder: opus_decoder           // decoder to convert opus to pcm
    private var packetCount: Int64 = 0          // number of packets read during decoding
    private var beginStream = true              // if decoding of stream has begun
    private var pageGranulePosition: Int64 = 0  // position of the packet data at page
    private var hasOpusStream = false           // whether or not the opus stream has been created
    private var hasTagsPacket = false           // whether or not the tags packet has been read
    private var opusSerialNumber: Int = 0       // the assigned serial number of the opus stream
    private var totalLinks: Int = 0             // a count of the number of opus streams
    private var preSkip: Int32 = 0              // number of samples to be skipped at beginning of stream
    private var granOffset: Int32 = 0           // where to begin reading the data from Opus
    private var frameSize: Int32 = 0            // number of samples decoded
    private var linkOut: Int32 = 0              // total number of bytes written from opus stream to pcmData
    private var numChannels: Int32 = 1          // number of channels
    private var pcmDataBuffer = UnsafeMutablePointer<Float>.allocate(capacity: 0) // decoded pcm float data
    
    private static let validSampleRates: [Int32] = [8000, 12000, 16000, 24000, 48000]

    init(audioData: Data) throws {
        // set properties
        streamState = ogg_stream_state()
        page = ogg_page()
        syncState = ogg_sync_state()
        packet = ogg_packet()
        header = OpusHeader()

        // status to catch errors when creating decoder
        var status = Int32(0)
        decoder = opus_decoder_create(sampleRate, numChannels, &status)

        // initialize ogg sync state
        ogg_sync_init(&syncState)
        var processedByteCount = 0
        
        // deallocate pcmDataBuffer when the function ends, regardless if the function ended normally or with an error.
        defer {
            pcmDataBuffer.deallocate()
        }
        
        while processedByteCount < audioData.count {
            // determine the size of the buffer to ask for
            var bufferSize: Int
            if audioData.count - processedByteCount > 200 {
                bufferSize = 200
            } else {
                bufferSize = audioData.count - processedByteCount
            }

            // obtain a buffer from the syncState
            var bufferData: UnsafeMutablePointer<Int8>
            bufferData = ogg_sync_buffer(&syncState, bufferSize)

            // write data from the service into the syncState buffer
            bufferData.withMemoryRebound(to: UInt8.self, capacity: bufferSize) { bufferDataUInt8 in
                audioData.copyBytes(to: bufferDataUInt8, from: processedByteCount..<processedByteCount + bufferSize)
            }
            processedByteCount += bufferSize
            // notify syncState of number of bytes we actually wrote
            ogg_sync_wrote(&syncState, bufferSize)

            // attempt to get a page from the data that we wrote
            while ogg_sync_pageout(&syncState, &page) == 1 {
                if beginStream {
                    // assign stream's number with the page.
                    ogg_stream_init(&streamState, ogg_page_serialno(&page))
                    beginStream = false
                }

                if ogg_page_serialno(&page) != Int32(streamState.serialno) {
                    ogg_stream_reset_serialno(&streamState, ogg_page_serialno(&page))
                }

                // add page to the ogg stream
                ogg_stream_pagein(&streamState, &page)

                // save position of the current decoding process
                pageGranulePosition = ogg_page_granulepos(&page)

                // extract packets from the ogg stream until no packets are left
                try extractPacket(&streamState, &packet)
            }
        }

        if totalLinks == 0 {
            NSLog("Does not look like an opus file.")
            throw OpusError.invalidState
        }

        // perform cleanup
        opus_multistream_decoder_destroy(decoder)
        if !beginStream {
            ogg_stream_clear(&streamState)
        }
        ogg_sync_clear(&syncState)
    }

    // Extract a packet from the ogg stream and store the extracted data within the packet object.
    private func extractPacket(_ streamState: inout ogg_stream_state, _ packet: inout ogg_packet) throws {
        // attempt to extract a packet from the ogg stream
        while ogg_stream_packetout(&streamState, &packet) == 1 {
            // execute if initial stream header
            if packet.b_o_s != 0 && packet.bytes >= 8 && memcmp(packet.packet, "OpusHead", 8) == 0 {
                // check if there's another opus head to see if stream is chained without EOS
                if hasOpusStream && hasTagsPacket {
                    hasOpusStream = false
                    opus_multistream_decoder_destroy(decoder)
                }

                // set properties if we are in a new opus stream
                if !hasOpusStream {
                    if packetCount > 0 && opusSerialNumber == streamState.serialno {
                        NSLog("Apparent chaining without changing serial number. Something bad happened.")
                        throw OpusError.internalError
                    }
                    opusSerialNumber = streamState.serialno
                    hasOpusStream = true
                    hasTagsPacket = false
                    linkOut = 0
                    packetCount = 0
                    totalLinks += 1
                } else {
                    NSLog("Warning: ignoring opus stream.")
                }
            }

            if !hasOpusStream || streamState.serialno != opusSerialNumber {
                break
            }

            // if first packet in logical stream, process header
            if packetCount == 0 {
                // create decoder from information in Opus header
                decoder = try processHeader(&packet, &numChannels, &preSkip)

                // Check that there are no more packets in the first page.
                let lastElementIndex = page.header_len - 1
                let lacingValue = page.header[lastElementIndex]
                // A lacing value of 255 would suggest that the packet continues on the next page.
                if ogg_stream_packetout(&streamState, &packet) != 0 || lacingValue == 255 {
                    throw OpusError.invalidPacket
                }

                granOffset = preSkip

                let capacity = MemoryLayout<Float>.stride * Int(MAX_FRAME_SIZE) * Int(numChannels)
                pcmDataBuffer = UnsafeMutablePointer<Float>.allocate(capacity: capacity)

            } else if packetCount == 1 {
                hasTagsPacket = true

                let lastElementIndex = page.header_len - 1
                let lacingValue = page.header[lastElementIndex]
                if ogg_stream_packetout(&streamState, &packet) != 0 || lacingValue == 255 {
                    NSLog("Extra packets on initial tags page. Invalid stream.")
                    throw OpusError.invalidPacket
                }
            } else {
                var numberOfSamplesDecoded: Int32
                var maxOut: Int64
                var outSample: Int64

                // Decode opus packet.
                numberOfSamplesDecoded = opus_multistream_decode_float(decoder, packet.packet, Int32(packet.bytes), pcmDataBuffer, MAX_FRAME_SIZE, 0)

                if numberOfSamplesDecoded < 0 {
                    NSLog("Decoding error: \(String(describing: opus_strerror(numberOfSamplesDecoded)))")
                    throw OpusError.internalError
                }

                frameSize = numberOfSamplesDecoded

                // Make sure the output duration follows the final end-trim
                // Output sample count should not be ahead of granpos value.
                maxOut = ((pageGranulePosition - Int64(granOffset)) * Int64(sampleRate) / 48000) - Int64(linkOut)
                outSample = try audioWrite(&pcmDataBuffer, numChannels, frameSize, &preSkip, &maxOut)

                linkOut += Int32(outSample)
            }
            packetCount += 1
        }

    }

    // Process the Opus header and create a decoder with these values
    private func processHeader(_ packet: inout ogg_packet, _ channels: inout Int32, _ preskip: inout Int32) throws -> opus_decoder {
        // create status to capture errors
        var status = Int32(0)

        if opus_header_parse(packet.packet, Int32(packet.bytes), &header) == 0 {
            throw OpusError.invalidPacket
        }

        channels = header.channels
        preskip = header.preskip

        // update the sample rate choosing closest valid value to that present in the header.
        sampleRate = Self.getClosestValidSampleRate(inputRate: Int32(header.input_sample_rate))

        var newDecoder: opus_decoder? = opus_multistream_decoder_create(sampleRate, channels, header.nb_streams, header.nb_coupled, &header.stream_map.0, &status)
        
        if status != OpusError.okay.rawValue {
            throw OpusError.badArgument
        }
        
        guard let newDecoder = newDecoder else {
            throw OpusError.badArgument
        }
        
        decoder = newDecoder
        return decoder
    }
    
    static func getClosestValidSampleRate(inputRate: Int32) -> Int32 {
        guard let closest = validSampleRates.enumerated().min(by: { abs($0.1 - inputRate) < abs($1.1 - inputRate)} ) else {
            return inputRate
        }
        return closest.element
    }

    // Write the decoded Opus data (now PCM) to the pcmData object
    private func audioWrite(_ pcmDataBuffer: inout UnsafeMutablePointer<Float>,
                            _ channels: Int32,
                            _ frameSize: Int32,
                            _ skip: inout Int32,
                            _ maxOut: inout Int64) throws -> Int64 {
        var sampOut: Int64 = 0
        var tmpSkip: Int32
        var outLength: UInt
        var floatOutput: UnsafeMutablePointer<Float>
        if maxOut < 0 {
            maxOut = 0
        }

        if skip != 0 {
            if skip > frameSize {
                tmpSkip = frameSize
            } else {
                tmpSkip = skip
            }
            skip -= tmpSkip
        } else {
            tmpSkip = 0
        }
        
        floatOutput = pcmDataBuffer.advanced(by: Int(channels) * Int(tmpSkip))
        outLength = UInt(frameSize) - UInt(tmpSkip)
        if maxOut > 0 {
            let bufferPointer = UnsafeBufferPointer(start: floatOutput, count: Int(outLength))
            pcmData.append(bufferPointer)
            sampOut += Int64(outLength)
        }

        return sampOut
    }
}
