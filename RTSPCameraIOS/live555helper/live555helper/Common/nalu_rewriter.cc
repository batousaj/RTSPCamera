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

#include "nalu_rewriter.h"
#include <iostream>

#include <CoreFoundation/CoreFoundation.h>
#include <memory>
#include <vector>

const char kAnnexBHeaderBytes[4] = {0, 0, 0, 1};
const size_t kAvccHeaderByteSize = sizeof(uint32_t);

bool H264AnnexBBufferToCMSampleBuffer(const uint8_t* annexb_buffer,
                                      size_t annexb_buffer_size,
                                      CMVideoFormatDescriptionRef video_format,
                                      CMSampleBufferRef* out_sample_buffer) {
  *out_sample_buffer = nullptr;

  AnnexBBufferReader reader(annexb_buffer, annexb_buffer_size);
  if (H264AnnexBBufferHasVideoFormatDescription(annexb_buffer,
                                                annexb_buffer_size)) {
    // Advance past the SPS and PPS.
    const uint8_t* data = nullptr;
    size_t data_len = 0;
    if (!reader.ReadNalu(&data, &data_len)) {
        std::cout << "Failed to read SPS";
      return false;
    }
    if (!reader.ReadNalu(&data, &data_len)) {
        std::cout << "Failed to read PPS";
      return false;
    }
  }

  // Allocate memory as a block buffer.
  // TODO(tkchin): figure out how to use a pool.
  CMBlockBufferRef block_buffer = nullptr;
  OSStatus status = CMBlockBufferCreateWithMemoryBlock(
      nullptr, nullptr, reader.BytesRemaining(), nullptr, nullptr, 0,
      reader.BytesRemaining(), kCMBlockBufferAssureMemoryNowFlag,
      &block_buffer);
  if (status != kCMBlockBufferNoErr) {
      std::cout << "Failed to create block buffer.";
    return false;
  }

  // Make sure block buffer is contiguous.
  CMBlockBufferRef contiguous_buffer = nullptr;
  if (!CMBlockBufferIsRangeContiguous(block_buffer, 0, 0)) {
    status = CMBlockBufferCreateContiguous(
        nullptr, block_buffer, nullptr, nullptr, 0, 0, 0, &contiguous_buffer);
    if (status != noErr) {
        std::cout << "Failed to flatten non-contiguous block buffer: "
                    << status;
      CFRelease(block_buffer);
      return false;
    }
  } else {
    contiguous_buffer = block_buffer;
    block_buffer = nullptr;
  }

  // Get a raw pointer into allocated memory.
  size_t block_buffer_size = 0;
  char* data_ptr = nullptr;
  status = CMBlockBufferGetDataPointer(contiguous_buffer, 0, nullptr,
                                       &block_buffer_size, &data_ptr);
  if (status != kCMBlockBufferNoErr) {
    std::cout << "Failed to get block buffer data pointer.";
    CFRelease(contiguous_buffer);
    return false;
  }

  // Write Avcc NALUs into block buffer memory.
  AvccBufferWriter writer(reinterpret_cast<uint8_t*>(data_ptr),
                          block_buffer_size);
  while (reader.BytesRemaining() > 0) {
    const uint8_t* nalu_data_ptr = nullptr;
    size_t nalu_data_size = 0;
    if (reader.ReadNalu(&nalu_data_ptr, &nalu_data_size)) {
      writer.WriteNalu(nalu_data_ptr, nalu_data_size);
    }
  }

  // Create sample buffer.
  status = CMSampleBufferCreate(nullptr, contiguous_buffer, true, nullptr,
                                nullptr, video_format, 1, 0, nullptr, 0,
                                nullptr, out_sample_buffer);
  if (status != noErr) {
      std::cout << "Failed to create sample buffer.";
    CFRelease(contiguous_buffer);
    return false;
  }
  CFRelease(contiguous_buffer);
  return true;
}

bool H264AnnexBBufferHasVideoFormatDescription(const uint8_t* annexb_buffer,
                                               size_t annexb_buffer_size) {

  // The buffer we receive via RTP has 00 00 00 01 start code artifically
  // embedded by the RTP depacketizer. Extract NALU information.
  // TODO(tkchin): handle potential case where sps and pps are delivered
  // separately.
  NaluType first_nalu_type = ParseNaluType(annexb_buffer[4]);
  bool is_first_nalu_type_sps = first_nalu_type == kSps;
  if (is_first_nalu_type_sps)
    return true;
  bool is_first_nalu_type_aud = first_nalu_type == kAud;
  // Start code + access unit delimiter + start code = 4 + 2 + 4 = 10.
  if (!is_first_nalu_type_aud || annexb_buffer_size <= 10u)
    return false;
  NaluType second_nalu_type = ParseNaluType(annexb_buffer[10]);
  bool is_second_nalu_type_sps = second_nalu_type == kSps;
  return is_second_nalu_type_sps;
}

CMVideoFormatDescriptionRef CreateVideoFormatDescription(
    const uint8_t* annexb_buffer,
    size_t annexb_buffer_size) {
  if (!H264AnnexBBufferHasVideoFormatDescription(annexb_buffer,
                                                 annexb_buffer_size)) {
    return nullptr;
  }
  AnnexBBufferReader reader(annexb_buffer, annexb_buffer_size);
  CMVideoFormatDescriptionRef description = nullptr;
  OSStatus status = noErr;
  // Parse the SPS and PPS into a CMVideoFormatDescription.
  const uint8_t* param_set_ptrs[2] = {};
  size_t param_set_sizes[2] = {};
  // Skip AUD.
  if (ParseNaluType(annexb_buffer[4]) == kAud) {
    if (!reader.ReadNalu(&param_set_ptrs[0], &param_set_sizes[0])) {
        std::cout << "Failed to read AUD";
      return nullptr;
    }
  }
  if (!reader.ReadNalu(&param_set_ptrs[0], &param_set_sizes[0])) {
      std::cout << "Failed to read SPS";
    return nullptr;
  }
  if (!reader.ReadNalu(&param_set_ptrs[1], &param_set_sizes[1])) {
      std::cout << "Failed to read PPS";
    return nullptr;
  }
  status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
      kCFAllocatorDefault, 2, param_set_ptrs, param_set_sizes, 4,
      &description);
  if (status != noErr) {
    std::cout << "Failed to create video format description." << std::endl;
    return nullptr;
  }
  return description;
}

AnnexBBufferReader::AnnexBBufferReader(const uint8_t* annexb_buffer,
                                       size_t length)
    : start_(annexb_buffer), length_(length) {
  offsets_ = FindNaluIndices(annexb_buffer, length);
  offset_ = offsets_.begin();
}

bool AnnexBBufferReader::ReadNalu(const uint8_t** out_nalu,
                                  size_t* out_length) {
  *out_nalu = nullptr;
  *out_length = 0;

  if (offset_ == offsets_.end()) {
    return false;
  }
  *out_nalu = start_ + offset_->payload_start_offset;
  *out_length = offset_->payload_size;
  ++offset_;
  return true;
}

size_t AnnexBBufferReader::BytesRemaining() const {
  if (offset_ == offsets_.end()) {
    return 0;
  }
  return length_ - offset_->start_offset;
}

AvccBufferWriter::AvccBufferWriter(uint8_t* const avcc_buffer, size_t length)
    : start_(avcc_buffer), offset_(0), length_(length) {
}

bool AvccBufferWriter::WriteNalu(const uint8_t* data, size_t data_size) {
  // Check if we can write this length of data.
  if (data_size + kAvccHeaderByteSize > BytesRemaining()) {
    return false;
  }
  // Write length header, which needs to be big endian.
  uint32_t big_endian_length = CFSwapInt32HostToBig(data_size);
  memcpy(start_ + offset_, &big_endian_length, sizeof(big_endian_length));
  offset_ += sizeof(big_endian_length);
  // Write data.
  memcpy(start_ + offset_, data, data_size);
  offset_ += data_size;
  return true;
}

size_t AvccBufferWriter::BytesRemaining() const {
  return length_ - offset_;
}

