# swift-ogg
This library provides a very simple api to convert between `opus/ogg` and `MPEG4AAC/m4a` files.
It uses opus's `libopus` `libogg` to convert between `opus/ogg` and linear PCM audio data and native iOS apis to convert between PCM and `MPEG4AAC/m4a`(but could be very easily adapted to use any other codec/container supported by iOS).
Apples recording and playback apis form `AVFoundation` can then be used quite simply with a codec/container pair that iOS natively supports(`MPEG4AAC/m4a` in this case).

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

Compiled versions of libopus and libogg are included and under the BSD Licence described [here](https://opus-codec.org/license/)
