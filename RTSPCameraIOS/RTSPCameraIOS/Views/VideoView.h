//
//  VideoView.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//#import <MobileVLCKit/MobileVLCKit.h>
//#import "RTSPCapturer.h"
#import "RTSPClientConnnection.h"
#import "Model.h"

@interface VideoView : UIView</*RTSPCapturerDecodeDelegate*/ RTSPClientConnnectionDelegate2> {
    BOOL isMuted;
}

@property(nonatomic) UILabel *playingLabel;
//@property(nonatomic,strong) VLCMediaPlayer *player;
@property (nonatomic, retain) AVSampleBufferDisplayLayer *displayLayer;
//@property(nonatomic,strong) RTSPCapturer* videoCapturer;
@property(nonatomic,strong) RTSPClientConnnection* videoConnection;
@property(nonatomic,assign) SourceType type;

- (instancetype) initWithFrame:(CGRect)frame andSource:(SourceType)src;

- (void) loadVideo:(NSURL*)url;
- (void) playVideo;
- (void) stopVideo;
- (BOOL) isPlayingVideo;

- (void) setMutedVideo:(BOOL)muted;
- (BOOL) isMutedVideo;
- (void) setVolume:(CGFloat) volume;

@end
