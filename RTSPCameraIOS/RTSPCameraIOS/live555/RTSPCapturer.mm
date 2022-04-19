//
//  RTSPCapturer.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import "RTSPCapturer.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolBox/VideoToolBox.h>

std::map <std::string, std::string> rtsp_option_ = { {"rtptransport","tcp"} , {"timeout","60"} };

static RTSPCapturer* RTSP_capturer = NULL;
static RTSPFactoryManagePrivate* RTSP_source_factory = NULL;

RTSPFactoryManagePrivate::RTSPFactoryManagePrivate(RTSPCapturer* capturer) {
    capture = capturer;
}

void RTSPFactoryManagePrivate::onData(unsigned char* buffer, int presentationtime) {
    CGDataProviderRef provider = CGDataProviderCreateWithData(
        NULL,
        pixelData,
        imageHeight * scanWidth,
        NULL);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef imageRef = CGImageCreate(imageWidth,
        imageHeight,
        8,
        bytesPerPixel * 8,
        scanWidth,
        colorSpaceRef,
        bitmapInfo,
        provider,
        NULL,
        NO,
        renderingIntent);

    UIImage *uiImage = [UIImage imageWithCGImage:imageRef];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
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
        std::string URL = [url UTF8String];
        manage = RTSPManagement::Create(URL,rtsp_option_);
    }
    return self;
}

- (void) startStreams {
    if (RTSP_source_factory) {
        RTSP_source_factory->startStreams();
    }
}

- (void) stopStreams {
    if (RTSP_source_factory) {
        RTSP_source_factory->stopStreams();
    }
}

- (BOOL) isPlayingStreams {
    return NO;
}

@end

