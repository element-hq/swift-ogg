# swift-ogg
This library provides a very simple API to convert between `opus/ogg` and `MPEG4AAC/m4a` files.
It uses opus's `libopus` `libogg` to convert between `opus/ogg` and linear PCM audio data and native iOS apis to convert between PCM and `MPEG4AAC/m4a`(but could be very easily adapted to use any other codec/container supported by iOS).
Apple's recording and playback APIs from `AVFoundation` can then be used quite simply with a codec/container pair that iOS natively supports (`MPEG4AAC/m4a` in this case).

# Usage
  ```swift
      let src:URL = ...
      let dest:URL = ...
      let dest2:URL = ...
      do {
          // Convert to OGG
          try OGGConverter.convertM4aFileToOpusOGG(src: src, dest: dest)
          // And back to M4a
          try OGGConverter.convertOpusOGGToM4aFile(src: dest, dest: dest2)
      } catch {
          // handle error
      }
  ```
# Licence
Portions of the swift-ogg library contain code derived from [watson-developer-cloud/swift-sdk](https://github.com/watson-developer-cloud/swift-sdk) under the Apache License 2.0

This project makes use of [opus-swift](https://github.com/vector-im/opus-swift) and [ogg-swift](https://github.com/vector-im/ogg-swift.git) which package the source code of libopus and libogg as platform independent XCFrameworks.
These two projects are under the MIT licence while the underlying libopus and libogg library source themselves are included under the BSD Licence described [here](https://opus-codec.org/license/)
