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
    [self setupUIView];
    type = kVLCMedia;
}

#pragma mark - Setup Controller Views

- (void)setupUIView {
    [self setupButtonView];
    [self setupURLField];
    [self createAlertWarning];
}

- (void)setupButtonView {
    self.addStreamBut = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200.0, 50.0)];
    self.addStreamBut.center = self.view.center;
    [self.view addSubview:self.addStreamBut];
    
    [self.addStreamBut setTitle:@"Add Stream" forState:UIControlStateNormal];
    [self.addStreamBut setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addStreamBut.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [self.addStreamBut setBackgroundColor:[UIColor systemGrayColor]];
    [self.addStreamBut addTarget:self action:@selector(onClickAddStreams:) forControlEvents:UIControlEventTouchUpInside];
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

    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:350];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self.view addConstraints:@[leading,tralling,top]];
    [self.url addConstraint:height];
}

- (void) createAlertWarning {
    self.alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"The URL Streaming was incorrected" preferredStyle:UIAlertControllerStyleAlert];
    
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
    BOOL isValided = [Validator isValidURL:url];
    if (isValided) {
        NSLog(@"That's was VLCMedia");
        [self pushVideoVideoWithURL:url];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:self.alert animated:true completion:nil];
        });
    }
}

#pragma mark - Switch View Controller

- (void) pushVideoVideoWithURL:(NSString *)url {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"VideoView" bundle:nil];
    VideoViewController* controller = (VideoViewController*)[storyboard instantiateViewControllerWithIdentifier:@"VideoViewVC"];
    [controller setURL:url];
    [controller setSourceUsing:type];
    UINavigationController * navigator = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController pushViewController:navigator animated:false];
    [self presentViewController:navigator animated:true completion:nil];
}

@end
