//
//  CommonTypes.h
//  live555helper
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#include <stdio.h>

const size_t kBufferPaddingBytesH264 = 8;

typedef enum CodecType {
    kCodecH264,
    kCodecH265,
    kCodecVP9,
    kCodecHEVC,
    kCodecJPEG,
    kNone
} CodecType ;
