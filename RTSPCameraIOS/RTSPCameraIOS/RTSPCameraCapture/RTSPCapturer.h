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
        void onDecodeParams(FrameEncoded* sps, FrameEncoded* pps) override;
        void onData(FrameEncoded* frame) override;
    
    private :
        RTSPCapturer* capture;
        RTSPControl* controller;
};
