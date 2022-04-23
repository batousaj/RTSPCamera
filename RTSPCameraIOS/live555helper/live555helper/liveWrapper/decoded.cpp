//
//  decoded.cpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 22/04/2022.
//

#include "decoded.h"
#include <iostream>

bool Decode::DecodeAndConvert(const std::string& base64, std::vector<uint8_t>* binary) {
  return Base64::DecodeFromArray(base64.data(), base64.size(),
                                      Base64::DO_STRICT, binary, nullptr);
}

bool Decode::DecodeSprop(const std::string& sprop) {
  size_t separator_pos = sprop.find(',');
  std::cout << "Parsing sprop \"" << sprop << "\"" << std::endl;
  if ((separator_pos <= 0) || (separator_pos >= sprop.length() - 1)) {
      std::cout << "Invalid seperator position " << separator_pos << " *"
                    << sprop << "*" << std::endl;
    return false;
  }
  std::string sps_str = sprop.substr(0, separator_pos);
  std::string pps_str = sprop.substr(separator_pos + 1, std::string::npos);
  
  if (!DecodeAndConvert(sps_str, &sps_)) {
      std::cout << "Failed to decode sprop/sps *" << sprop << "*" << std::endl;
    return false;
  }
  sps_size_= sps_.size();
  std::cout << "Size sps \"" << sps_size_ << std::endl;
  if (!DecodeAndConvert(pps_str, &pps_)) {
      std::cout << "Failed to decode sprop/pps *" << sprop << "*" << std::endl;
    return false;
  }
  pps_size_= pps_.size();
  std::cout << "Size pps \"" << pps_size_ << std::endl;
  return true;
}
