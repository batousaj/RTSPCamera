//
//  RTSPCapturer.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import "RTSPCapturer.h"

std::map <std::string, std::string> rtsp_option_ = { {"rtptransport","tcp"} , {"timeout","30"} };

static RTSPCapturer* RTSP_capturer = NULL;
static RTSPFactoryManagePrivate* RTSP_source_factory = NULL;

RTSPFactoryManagePrivate::RTSPFactoryManagePrivate(RTSPCapturer* capturer) {
    capture = capturer;
}

void RTSPFactoryManagePrivate::onDecodeParams(FrameEncoded* sps, FrameEncoded* pps) {
    //
}

void RTSPFactoryManagePrivate::onData(FrameEncoded* frame, bool isReset) {
    [capture.decoder decode:frame andReset:(BOOL)isReset];
}

void RTSPFactoryManagePrivate::receivedRawVideoFrame(uint8_t * frame, uint32_t frameSize) {
    [capture.decoder receivedRawVideoFrame:frame withSize:frameSize];
}

void RTSPFactoryManagePrivate::registerRTSPControl(RTSPControl* controller) {
    this->controller = controller;
}

void RTSPFactoryManagePrivate::startStreams() {
    controller->startRTSP();
}

void RTSPFactoryManagePrivate::stopStreams() {
    controller->stopRTSP();
}

RTSPSourceFactory* CreateRTSPSourceFactory(void) {
    RTSP_source_factory = new RTSPFactoryManagePrivate(RTSP_capturer);
    return RTSP_source_factory;
}

@implementation RTSPCapturer

- (instancetype) initWithURL:(NSString *)url {
    if (self = [super init]) {
        RTSP_capturer = self;
        RTSPSourceFactory::SetRTSPSourceFactory(CreateRTSPSourceFactory);
        self.decoder = [[RTSPCapturerDecode alloc] init];
        std::string URL = [url UTF8String];
        manage = RTSPManagement::Create(URL,rtsp_option_);
    }
    return self;
}

- (void) startStreams {
    if (RTSP_source_factory) {
        isPlaying = YES;
        RTSP_source_factory->startStreams();
    }
}

- (void) stopStreams {
    if (RTSP_source_factory) {
        isPlaying = NO;
        RTSP_source_factory->stopStreams();
    }
}

- (BOOL) isPlayingStreams {
    return isPlaying;
}

@end

