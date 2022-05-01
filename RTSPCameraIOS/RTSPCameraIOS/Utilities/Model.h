//
//  Model.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>

//typedef std::vector<uint8_t> StoredBuffer;

typedef NS_ENUM(NSInteger, SourceType) {
    kLive555        = 0,
    kVLCMedia       = 1,
    kNoneSrc           = 2,
};

static NSString * const naluTypesStrings[] =
{
 @"0: Unspecified (non-VCL)",
 @"1: Coded slice of a non-IDR picture (VCL)", // P frame
 @"2: Coded slice data partition A (VCL)",
 @"3: Coded slice data partition B (VCL)",
 @"4: Coded slice data partition C (VCL)",
 @"5: Coded slice of an IDR picture (VCL)", // I frame
 @"6: Supplemental enhancement information (SEI) (non-VCL)",
 @"7: Sequence parameter set (non-VCL)", // SPS parameter
 @"8: Picture parameter set (non-VCL)", // PPS parameter
 @"9: Access unit delimiter (non-VCL)",
 @"10: End of sequence (non-VCL)",
 @"11: End of stream (non-VCL)",
 @"12: Filler data (non-VCL)",
 @"13: Sequence parameter set extension (non-VCL)",
 @"14: Prefix NAL unit (non-VCL)",
 @"15: Subset sequence parameter set (non-VCL)",
 @"16: Reserved (non-VCL)",
 @"17: Reserved (non-VCL)",
 @"18: Reserved (non-VCL)",
 @"19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
 @"20: Coded slice extension (non-VCL)",
 @"21: Coded slice extension for depth view components (non-VCL)",
 @"22: Reserved (non-VCL)",
 @"23: Reserved (non-VCL)",
 @"24: STAP-A Single-time aggregation packet (non-VCL)",
 @"25: STAP-B Single-time aggregation packet (non-VCL)",
 @"26: MTAP16 Multi-time aggregation packet (non-VCL)",
 @"27: MTAP24 Multi-time aggregation packet (non-VCL)",
 @"28: FU-A Fragmentation unit (non-VCL)",
 @"29: FU-B Fragmentation unit (non-VCL)",
 @"30: Unspecified (non-VCL)",
 @"31: Unspecified (non-VCL)",
};

@interface Model : NSObject

+ (Model*) shareInstance;

- (NSMutableDictionary*) getImageCheckBox;

@end
