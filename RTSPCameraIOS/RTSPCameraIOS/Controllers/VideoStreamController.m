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
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self setupNavigatorBar];
    [self setupTapView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    isToggle = false;
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [self setupVideoView];
}

#pragma mark - Setup Controller Views

- (void) setupNavigatorBar {
    self.title = url.host;
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(onClickBack)];
    [back setTintColor:[UIColor whiteColor]];
    [self.navigationItem setHidesBackButton:YES];
    [self.navigationItem setLeftBarButtonItem:back];
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
    isToggle = !isToggle;
    [self playVideo];
    [self setNavigatorHiddenOrUnHidden:isToggle];
}

- (void) onClickBack {
    [self stopVideo];
    [self.navigationController popViewControllerAnimated:YES];
//    [self dismissViewControllerAnimated:self completion:nil];
}

#pragma mark - Private function

- (void) playVideo {
    if (![self.video isPlayingVideo]) {
        [self.video playVideo];
    }
}

- (void) stopVideo {
    if ([self.video isPlayingVideo]) {
        [self.video stopVideo];
    }
}

- (void) setNavigatorHiddenOrUnHidden:(BOOL)toggle {
    [self.navigationController setNavigationBarHidden:toggle animated:YES];
}

@end
