//
//  RTSPCapturer.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>
#include "FrameEncoded.h"
#include "RTSPManagement.h"
#include "RTSPCapturerDecode.h"

@interface RTSPCapturer : NSObject {
    RTSPManagement* manage;
    BOOL isPlaying;
}

@property (nonatomic)RTSPCapturerDecode* decoder;

- (instancetype) initWithURL:(NSString *)url;

- (void) startStreams;
- (void) stopStreams;
- (BOOL) isPlayingStreams;

@end

class RTSPFactoryManagePrivate : public RTSPSourceFactory {
    
    public :
        void startStreams();
        void stopStreams();
        RTSPFactoryManagePrivate(RTSPCapturer* capturer);
        void registerRTSPControl(RTSPControl* controller) override;
        void onDecodeParams(uint8_t* sps, uint8_t*pps, size_t sps_size, size_t pps_size) override;
        void onData(FrameEncoded* frame) override;
    
    private :
        RTSPCapturer* capture;
        RTSPControl* controller;
};
