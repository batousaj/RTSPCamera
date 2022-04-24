//
//  FrameEncoded.hpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#pragma once
#include <iostream>
#include <stdio.h>
#include <stdint.h>

#include "CommonTypes.h"

class FrameEncoded {
    public :
        FrameEncoded(uint8_t* buffer, size_t size, uint64_t presentation_time);
        FrameEncoded(uint8_t* buffer, size_t size);
        ~FrameEncoded();
    
        static size_t GetBufferPaddingBytes(CodecType codec_type);
        
        uint8_t* buffer() {
            return _buffer;
        };
    
        size_t size() {
            return _size;
        }
    
        uint64_t presentation_time() {
            return presentation_time_;
        }
    
    private :
        uint32_t _encodedWidth = 0;
        uint32_t _encodedHeight = 0;
        uint32_t _timeStamp = 0;
        uint8_t* _buffer;
        size_t _size;
        uint64_t presentation_time_ = 0;
        
};
