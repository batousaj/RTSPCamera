//
//  VideoView.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//


#import "VideoView.h"


@implementation VideoView

- (instancetype) initWithFrame:(CGRect)frame andSource:(SourceType)src {
    if (self = [super initWithFrame:frame]) {
        self.type = src;
        [self setupBeforePlayVideo];
        [self setupLoadingLabel];
    }
    return self;
}

#pragma mark - Setup View

- (void) setupBeforePlayVideo {
//    self.player = [[VLCMediaPlayer alloc] init];
//    self.player.drawable = self;
//    NSString *ratio = @"16:9";
//    self.player.videoAspectRatio = (char*)[ratio UTF8String];
    self.displayLayer = [[AVSampleBufferDisplayLayer alloc]init];
    [self.displayLayer setFrame:self.frame];
    self.displayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.displayLayer.backgroundColor = [UIColor blackColor].CGColor;
       CMTimebaseRef tmBase = nil;
    CMTimebaseCreateWithSourceClock(NULL,CMClockGetHostTimeClock(),&tmBase);
    self.displayLayer.controlTimebase = tmBase;
    CMTimebaseSetTime( self.displayLayer.controlTimebase, kCMTimeZero);
    CMTimebaseSetRate( self.displayLayer.controlTimebase, 1.0);

    [self.layer addSublayer: self.displayLayer];
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
    if ([self isLive555]) {
        NSString* urlStr = [url absoluteString];
        self.videoCapturer = [[RTSPCapturer alloc] initWithURL:urlStr];
        self.videoCapturer.decoder.delegate = self;
    } else {
//        [self setupBeforePlayVideo];
//        VLCMedia *media = [VLCMedia mediaWithURL:url];
//        self.player.media = media;
    }
}

- (void) playVideo {
    if ( [self isLive555] == YES) {
        [self.videoCapturer startStreams];
    } else {
//        [self.player play];
    }
    [self.playingLabel removeFromSuperview];
}

- (void) stopVideo {
    if ([self isLive555]) {
        [self.videoCapturer stopStreams];
    } else {
//        [self.player stop];
    }
    [self addSubview:self.playingLabel];
}

- (BOOL) isPlayingVideo {
    if ([self isLive555]) {
        return [self.videoCapturer isPlayingStreams];
    } else {
        return NO;
//        return self.player.isPlaying;
    }
}

#pragma mark - Private Function
- (BOOL) isLive555 {
    if (self.type == kLive555) {
        return YES;
    } else {
        return NO;
    }
}

- (void)RTSPCapturerDecodeDelegateSampleBuffer:(CMSampleBufferRef) samplebuffer {
    if([self.displayLayer isReadyForMoreMediaData])
        {
            [self.displayLayer enqueueSampleBuffer:samplebuffer];
        }
        [self.displayLayer setNeedsDisplay];
//    if (self.displayLayer) {
//        [self.displayLayer enqueueSampleBuffer:samplebuffer];
//    }
}

#pragma mark - Control Audio Streaming

- (void) setVolume:(CGFloat) volume {
    isMuted = NO;
//    self.player.audio.volume = volume;

}

- (void) setMutedVideo:(BOOL)muted {
    isMuted = YES;
//    self.player.audio.volume = 0;
}

- (BOOL) isMutedVideo {
    return isMuted;
}

@end
