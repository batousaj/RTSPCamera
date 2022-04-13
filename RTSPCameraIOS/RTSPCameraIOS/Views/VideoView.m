//
//  VideoView.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//


#import "VideoView.h"


@implementation VideoView

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupBeforePlayVideo];
    }
    return self;
}

#pragma mark - Setup View

- (void) setupBeforePlayVideo {
    self.player = [[VLCMediaPlayer alloc] init];
    self.player.drawable = self;
    NSString *ratio = @"16:9";
    self.player.videoAspectRatio = (char*)[ratio UTF8String];
    
    [self setupLoadingLabel];
}

- (void) setupLoadingLabel {
    self.playingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 80)];
    self.playingLabel.center = self.center;
//    [self.playingLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.playingLabel];
    
    [self.playingLabel setText:@"Playing"];
    [self.playingLabel setTextColor: [UIColor whiteColor]];
    self.playingLabel.font = [UIFont systemFontOfSize:40.0];
    
//    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.playingLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//
//    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.playingLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
//
//    [self addConstraints:@[centerX,centerY]];
}

#pragma mark - Control Video Streaming

- (void) loadVideo:(NSURL*)url {
    VLCMedia *media = [VLCMedia mediaWithURL:url];
    self.player.media = media;
}

- (void) playVideo {
    [self.player play];
    [self.playingLabel removeFromSuperview];
}

- (void) stopVideo {
    [self.player stop];
    [self addSubview:self.playingLabel];
}

- (BOOL) isPlayingVideo {
    return self.player.isPlaying;
}

#pragma mark - Control Audio Streaming

- (void) setVolume:(CGFloat) volume {
    isMuted = NO;
    self.player.audio.volume = volume;
}

- (void) setMutedVideo:(BOOL)muted {
    isMuted = YES;
    self.player.audio.volume = 0;
}

- (BOOL) isMutedVideo {
    return isMuted;
}

@end
