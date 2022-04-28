//
//  StoredFrame.m
//  RTSPCameraIOS
//
//  Created by Thien Vu on 28/04/2022.
//

#import <Foundation/Foundation.h>

#include "StoredFrame.h"

@implementation StoredData

- (instancetype) init {
    if ( self = [super init]) {
        //
    }
    return self;
}

- (void)storedData:(uint8_t*) data withPts:(uint32_t)presentation_time_ {
    
}

- (uint8_t*) getBufferDisplay {
    return nil;
}

@end
