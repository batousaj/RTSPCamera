//
//  CommonTypes.h
//  live555helper
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#pragma once
#include <stdio.h>

const size_t kBufferPaddingBytesH264 = 8;
// The size of a full NALU start sequence {0 0 0 1}, used for the first NALU
// of an access unit, and for SPS and PPS blocks.
const size_t kNaluLongStartSequenceSize = 4;

// The size of a shortened NALU start sequence {0 0 1}, that may be used if
// not the first NALU of an access unit or an SPS or PPS block.
const size_t kNaluShortStartSequenceSize = 3;

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

struct NaluIndex {
  // Start index of NALU, including start sequence.
  size_t start_offset;
  // Start index of NALU payload, typically type header.
  size_t payload_start_offset;
  // Length of NALU payload, in bytes, counting from payload_start_offset.
  size_t payload_size;
};
