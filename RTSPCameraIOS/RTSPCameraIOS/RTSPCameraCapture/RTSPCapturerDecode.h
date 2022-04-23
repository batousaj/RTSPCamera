//
//  RTSPCapturerDecode.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#include "Model.h"
#include "FrameEncoded.h"

@protocol RTSPCapturerDecodeDelegate <NSObject>

- (void)RTSPCapturerDecodeDelegateSampleBuffer:(CMSampleBufferRef) samplebuffer;

@end

@interface RTSPCapturerDecode : NSObject

@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) id<RTSPCapturerDecodeDelegate> delegate;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

- (void)createDecoder;
- (void)createDecompSession;
- (void)createFormatDescription:(uint8_t*) sps ppsData:(uint8_t*) pps andsizeSps:(size_t)sps_size andpps:(size_t)pps_size;
- (void)decode:(FrameEncoded*) encodedImage;

@end
