//
//  VideoView.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileVLCKit/MobileVLCKit.h>

@interface VideoView : UIView {
    BOOL isMuted;
}

@property(nonatomic) UILabel *playingLabel;
@property(nonatomic,strong) VLCMediaPlayer *player;

- (instancetype) initWithFrame:(CGRect)frame;

- (void) loadVideo:(NSURL*)url;
- (void) playVideo;
- (void) stopVideo;
- (BOOL) isPlayingVideo;

- (void) setMutedVideo:(BOOL)muted;
- (BOOL) isMutedVideo;
- (void) setVolume:(CGFloat) volume;

@end
