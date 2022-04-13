//
//  ViewController.m
//  RTSPCameraIOS
//
//  Created by Thien Vu on 12/04/2022.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setTitle:@"RTSP Streams"];
}

- (void)dealloc {
    self.url = nil;
    self.addStreamBut = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [self setupUIView];
}

- (void)setupUIView {
    [self setupButtonView];
    [self setupURLField];
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
    self.url = [[UITextField alloc]init];
    [self.url setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.url];
    
    [self.url setPlaceholder:@"URL Streams"];
    [self.url setTextColor:[UIColor systemGrayColor]];
    [self.url.layer setBorderWidth:1.0];
    [self.url.layer setBorderColor: [UIColor blackColor].CGColor];
    
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:50];
    NSLayoutConstraint *tralling = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-50];

    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:350];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.url attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    
    [self.view addConstraints:@[leading,tralling,top]];
    [self.url addConstraint:height];
}

- (void) onClickAddStreams:(UIButton*) button {
    NSLog(@"That's user");
}


@end
