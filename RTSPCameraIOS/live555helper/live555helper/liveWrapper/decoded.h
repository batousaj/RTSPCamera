//
//  decoded.hpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 22/04/2022.
//

#pragma once

#include <stdio.h>
#include <vector>
#include <mutex>
#include <condition_variable>

#include "base64.h"
#include "CommonTypes.h"

class Decode  {
public :
    Decode() {};
    ~Decode() {};
    const std::vector<uint8_t>& sps_nalu() { return sps_; }
    const std::vector<uint8_t>& pps_nalu() { return pps_; }
    size_t sps_nalu_size() { return sps_size_; }
    size_t pps_nalu_size() { return pps_size_; }
    
    bool DecodeAndConvert(const std::string& base64, std::vector<uint8_t>* binary);
    bool DecodeSprop(const std::string& sprop);
    
    NaluType getNaluType(uint8_t nalu_buffer) {
        return static_cast<NaluType>(nalu_buffer & kNaluTypeMask);
    };
    
private :
    std::vector<uint8_t> sps_;
    std::vector<uint8_t> pps_;
    size_t sps_size_;
    size_t pps_size_;
};
