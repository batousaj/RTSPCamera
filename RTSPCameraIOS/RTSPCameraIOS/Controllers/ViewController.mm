//
//  ViewController.m
//  RTSPCameraIOS
//
//  Created by Thien Vu on 12/04/2022.
//

#import "ViewController.h"
#import "Validator.h"
#import "UITextView+Ext.h"
#import "VideoStreamController.h"
#import "UINavigationController+Config.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self setTitle:@"RTSP Streams"];
}

- (void)dealloc {
    self.url = nil;
    self.addStreamBut = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    type = kVLCMedia;
    [self setupUIView];
}

#pragma mark - Setup Controller Views

- (void)setupUIView {
    [self setupURLField];
    [self setupButtonView];
    [self createAlertWarning];
    [self setupCheckView];
    [self setupTappedInView];
}

- (void)setupTappedInView {
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapped)];
    [self.view addGestureRecognizer:self.tap];
}

- (void)setupButtonView {
    self.addStreamBut = [[UIButton alloc] init];
    [self.addStreamBut setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.addStreamBut];
    
    [self.addStreamBut setTitle:@"Add Stream" forState:UIControlStateNormal];
    [self.addStreamBut setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addStreamBut.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [self.addStreamBut setBackgroundColor:[UIColor systemGrayColor]];
    [self.addStreamBut addTarget:self
                          action:@selector(onClickAddStreams:)
                forControlEvents:UIControlEventTouchUpInside];
    
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.addStreamBut attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:100];
    NSLayoutConstraint *tralling = [NSLayoutConstraint constraintWithItem:self.addStreamBut attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-100];

    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.addStreamBut attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.url attribute:NSLayoutAttributeBottom multiplier:1 constant:30];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.addStreamBut attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self.view addConstraints:@[leading,tralling,top]];
    [self.addStreamBut addConstraint:height];
}

- (void)setupCheckView {
    self.checkView = [[UIView alloc] init];
    [self.checkView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.checkView];
    
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.checkView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:50];
    NSLayoutConstraint *tralling = [NSLayoutConstraint constraintWithItem:self.checkView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-50];

    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.checkView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.addStreamBut attribute:NSLayoutAttributeBottom multiplier:1 constant:30];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.checkView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self.view addConstraints:@[leading,tralling,top]];
    [self.checkView addConstraint:height];
    
    [self setupButtonSource];
}

- (void)setupButtonSource {
    self.checkLive = [[UICheckButton alloc] initButtonWithFrame:CGRectMake(0, 0, 120, 50)];
//    [self.checkLive setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.checkView addSubview:self.checkLive];
    self.checkLive.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.checkLive setupButtonWithTitle:@"Live555"
                            andDictImage:[[Model shareInstance] getImageCheckBox]
                                andCheck:NO];
    [self.checkLive setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.checkVLC setTintColor:[UIColor systemBlueColor]];
    [self.checkLive addTarget:self
                       action:@selector(onClickCheckLive:)
             forControlEvents:UIControlEventTouchUpInside];
    
    self.checkVLC = [[UICheckButton alloc] initButtonWithFrame:CGRectMake(200, 0, 120, 50)];
//    [self.checkVLC setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.checkView addSubview:self.checkVLC];
    self.checkVLC.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.checkVLC setTitle:@"VLCMedia" forState:UIControlStateNormal];
    [self.checkVLC setupButtonWithTitle:@"VLCMedia"
                           andDictImage:[[Model shareInstance] getImageCheckBox]
                               andCheck:YES];
    [self.checkVLC setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.checkVLC setTintColor:[UIColor systemBlueColor]];
    [self.checkVLC addTarget:self
                      action:@selector(onClickCheckVLC:)
            forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupURLField {
    self.url = [[UITextField alloc] init];
    [self.url setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.url];
    
    [self.url setPlaceholder:@"URL Streams"];
    [self.url setTextColor:[UIColor systemGrayColor]];
    [self.url.layer setBorderWidth:1.0];
    [self.url.layer setBorderColor: [UIColor blackColor].CGColor];
    [self.url setLeftPadding:10.0];
    [self.url setRightPadding:10.0];
    
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:50];
    NSLayoutConstraint *tralling = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-50];

    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:self.view.frame.size.height/2 - 50];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self.view addConstraints:@[leading,tralling,top]];
    [self.url addConstraint:height];
}

- (void) createAlertWarning {
    self.alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                     message:@"The URL Streaming was incorrected"
                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:self.alert completion:nil];
        });
        
    }];
    
    [self.alert addAction:ok];
}

#pragma mark - Handle Event Selector

- (void) onClickAddStreams:(UIButton*) button {
    NSString *url = self.url.text;
//    BOOL isValided = [Validator isValidURL:url];
//    if (isValided) {
        [self pushVideoVideoWithURL:url];
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self presentViewController:self.alert animated:true completion:nil];
//        });
//    }
}

- (void) onClickCheckLive:(UIButton*) button {
    if (![self.checkLive isChecking]) {
        [self willCheckLive];
    }
}

- (void) onClickCheckVLC:(UIButton*) button {
    if (![self.checkVLC isChecking]) {
        [self willCheckVLC];
    }
}

- (void) onTapped {
    if ([self.url isEditing]) {
        [self.url endEditing:YES];
    }
}

#pragma mark - Private function to check source

- (void) willCheckVLC {
    NSLog(@"That's was VLCMedia");
    type = kVLCMedia;
    [self.checkVLC setCheck:YES];
    [self.checkLive setCheck:NO];
}

- (void) willCheckLive {
    NSLog(@"That's was Live555");
    type = kLive555;
    [self.checkVLC setCheck:NO];
    [self.checkLive setCheck:YES];
}

#pragma mark - Switch View Controller

- (void) pushVideoVideoWithURL:(NSString *)url {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"VideoView" bundle:nil];
    VideoViewController* controller = (VideoViewController*)[storyboard instantiateViewControllerWithIdentifier:@"VideoViewVC"];
    [controller setURL:url];
    [controller setSourceUsing:type];
    [self.navigationController pushViewController:controller animated:true];
//    UINavigationController * navigator = [[UINavigationController alloc] initWithRootViewController:controller];
//    [navigator setUpAppNavigation];
//    [self presentViewController:navigator animated:true completion:nil];
}

@end
