//
//  VideoStreamController.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>
#import "VideoStreamController.h"

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigatorBar];
    [self setupTapView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [self setupVideoView];
}

#pragma mark - Setup Controller Views

- (void) setupNavigatorBar {
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(onClickBack)];
    self.navigationItem.backBarButtonItem = back;
}

- (void) setupTapView {
    self.tapped = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTapped)];
    [self.view addGestureRecognizer:self.tapped];
}

- (void) setupVideoView {
    if (islive555) {
//        videoCapturer
    } else {
        self.video = [[VideoView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
        [self.view addSubview:self.video];
        self.title = url.host;
        [self.video loadVideo:url];
        [self.video addGestureRecognizer:self.tapped];
    }
}

- (void) setURL:(NSString *)url {
    self->url = [NSURL URLWithString:url];
}

- (void) setSourceUsing:(SourceType)source {
    if (source == kVLCMedia) {
        islive555 = NO;
    } else if (source == kLive555) {
        islive555 = YES;
    }
}

#pragma mark - Handle Event on Selector

- (void) onTapped {
    if ([self.video isPlayingVideo]) {
        [self stopVideo];
    } else {
        [self playVideo];
    }
}

- (void) onClickBack {
    [self dismissViewControllerAnimated:self completion:nil];
}

#pragma mark - Private function

- (void) playVideo {
    [self.video playVideo];
    [self setNavigatorHidden];
}

- (void) stopVideo {
    [self.video stopVideo];
    [self setNavigatorUnHidden];
}

- (void) setNavigatorHidden {
    [self.navigationController setNavigationBarHidden:YES];
}

- (void) setNavigatorUnHidden {
    [self.navigationController setNavigationBarHidden:NO];
}

@end
