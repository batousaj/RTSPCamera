//
//  RTSPCapturer.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#include "RTSPManagement.h"
#import <Foundation/Foundation.h>

@interface RTSPCapturer : NSObject {
    RTSPManagement* manage;
}

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
        void onData(unsigned char* buffer, int presentationtime) override;
    
    private :
        RTSPCapturer* capture;
        RTSPControl* controller;
};
