//
//  CommonTypes.h
//  live555helper
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#include <stdio.h>

const size_t kBufferPaddingBytesH264 = 8;
const uint8_t kNaluTypeMask = 0x1F;

typedef enum CodecType {
    kCodecH264,
    kCodecH265,
    kCodecVP9,
    kCodecHEVC,
    kCodecJPEG,
    kNone
} CodecType ;

enum NaluType : uint8_t {
  kSlice = 1,
  kIdr = 5,
  kSei = 6,
  kSps = 7,
  kPps = 8,
  kAud = 9,
  kEndOfSequence = 10,
  kEndOfStream = 11,
  kFiller = 12,
  kStapA = 24,
  kFuA = 28
};
