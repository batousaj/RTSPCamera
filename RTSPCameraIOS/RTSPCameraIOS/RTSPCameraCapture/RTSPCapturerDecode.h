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

@interface RTSPCapturerDecode : NSObject {
    uint64_t presentation_time_;
}

@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) id<RTSPCapturerDecodeDelegate> delegate;
@property (nonatomic, assign) int spsSize;
@property (nonatomic, assign) int ppsSize;

- (void)createDecoder;
- (void)createDecompSession;
- (void)decode:(FrameEncoded*) encodedImage;

@end
