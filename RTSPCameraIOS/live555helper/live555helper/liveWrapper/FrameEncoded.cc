//
//  FrameEncoded.cpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#include "FrameEncoded.h"

FrameEncoded::FrameEncoded(uint8_t* buffer, size_t size, uint64_t presentation_time):
        _size(size),
        presentation_time_(presentation_time),
        _buffer(buffer)
{
    std::cout << "Thien Vu: FrameEncoded was init" << std::endl ;
}

FrameEncoded::FrameEncoded(uint8_t* buffer, size_t size):
        _size(size),
        _buffer(buffer)
{
    std::cout << "Thien Vu: FrameEncoded was init" << std::endl ;
}

FrameEncoded::~FrameEncoded() {
    //
}

size_t FrameEncoded::GetBufferPaddingBytes(common::CodecType codec_type) {
    switch (codec_type) {
        case common::kCodecH265:
        case common::kCodecHEVC:
        case common::kCodecJPEG:
        case common::kCodecVP9:
        case common::kCodecH264:
            return common::kBufferPaddingBytesH264;
        default:
            break;
    }
    return 0;
}
