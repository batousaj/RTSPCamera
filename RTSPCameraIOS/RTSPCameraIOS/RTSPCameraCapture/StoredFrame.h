//
//  StoredFrame.h
//  RTSPCameraIOS
//
//  Created by Thien Vu on 28/04/2022.
//

#include <Foundation/Foundation.h>
#include <AVFoundation/AVFoundation.h>

@interface StoredData : NSObject

@property(nonatomic, assign)NSArray* presentation_time_;
@property(nonatomic, assign)NSArray* buffer;

- (instancetype)init;

- (void)storedData:(uint8_t*) data withPts:(uint32_t)presentation_time_;

- (uint8_t*) getBufferDisplay;

@end
