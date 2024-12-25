/*
 *  Copyright (c) 2015 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 *
 */
#pragma once

#include <CoreMedia/CoreMedia.h>
#include <vector>

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
  kStart = 0,
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

static NaluType ParseNaluType(uint8_t nalu_buffer) {
    return static_cast<NaluType>(nalu_buffer & kNaluTypeMask);
};

static std::vector<NaluIndex> FindNaluIndices(const uint8_t* buffer,
                                       size_t buffer_size) {
  // This is sorta like Boyer-Moore, but with only the first optimization step:
  // given a 3-byte sequence we're looking at, if the 3rd byte isn't 1 or 0,
  // skip ahead to the next 3-byte sequence. 0s and 1s are relatively rare, so
  // this will skip the majority of reads/checks.
  std::vector<NaluIndex> sequences;
  if (buffer_size < kNaluShortStartSequenceSize)
    return sequences;

  const size_t end = buffer_size - kNaluShortStartSequenceSize;
  for (size_t i = 0; i < end;) {
    if (buffer[i + 2] > 1) {
      i += 3;
    } else if (buffer[i + 2] == 1 && buffer[i + 1] == 0 && buffer[i] == 0) {
      // We found a start sequence, now check if it was a 3 of 4 byte one.
      NaluIndex index = {i, i + 3, 0};
      if (index.start_offset > 0 && buffer[index.start_offset - 1] == 0)
        --index.start_offset;

      // Update length of previous entry.
      auto it = sequences.rbegin();
      if (it != sequences.rend())
        it->payload_size = index.start_offset - it->payload_start_offset;

      sequences.push_back(index);

      i += 3;
    } else {
      ++i;
    }
  }

  // Update length of last entry, if any.
  auto it = sequences.rbegin();
  if (it != sequences.rend())
    it->payload_size = buffer_size - it->payload_start_offset;

  return sequences;
}

bool H264AnnexBBufferToCMSampleBuffer(const uint8_t* annexb_buffer,
                                      size_t annexb_buffer_size,
                                      CMVideoFormatDescriptionRef video_format,
                                      CMSampleBufferRef* out_sample_buffer);


bool H264AnnexBBufferHasVideoFormatDescription(const uint8_t* annexb_buffer,
                                               size_t annexb_buffer_size);

CMVideoFormatDescriptionRef CreateVideoFormatDescription(
    const uint8_t* annexb_buffer,
    size_t annexb_buffer_size);

// Helper class for reading NALUs from an RTP Annex B buffer.
class AnnexBBufferReader final {
 public:
  AnnexBBufferReader(const uint8_t* annexb_buffer, size_t length);
  ~AnnexBBufferReader() {}
  AnnexBBufferReader(const AnnexBBufferReader& other) = delete;
  void operator=(const AnnexBBufferReader& other) = delete;

  // Returns a pointer to the beginning of the next NALU slice without the
  // header bytes and its length. Returns false if no more slices remain.
  bool ReadNalu(const uint8_t** out_nalu, size_t* out_length);

  // Returns the number of unread NALU bytes, including the size of the header.
  // If the buffer has no remaining NALUs this will return zero.
  size_t BytesRemaining() const;

 private:
  // Returns the the next offset that contains NALU data.
  size_t FindNextNaluHeader(const uint8_t* start,
                            size_t length,
                            size_t offset) const;

  const uint8_t* const start_;
  std::vector<NaluIndex> offsets_;
  std::vector<NaluIndex>::iterator offset_;
  const size_t length_;
};

// Helper class for writing NALUs using avcc format into a buffer.
class AvccBufferWriter final {
 public:
  AvccBufferWriter(uint8_t* const avcc_buffer, size_t length);
  ~AvccBufferWriter() {}
  AvccBufferWriter(const AvccBufferWriter& other) = delete;
  void operator=(const AvccBufferWriter& other) = delete;

  // Writes the data slice into the buffer. Returns false if there isn't
  // enough space left.
  bool WriteNalu(const uint8_t* data, size_t data_size);

  // Returns the unused bytes in the buffer.
  size_t BytesRemaining() const;

 private:
  uint8_t* const start_;
  size_t offset_;
  const size_t length_;
};
