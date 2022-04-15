//
//  ViewController.h
//  RTSPCameraIOS
//
//  Created by Thien Vu on 12/04/2022.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Model.h"
#import "UIButtonView+Ext.h"

@interface ViewController : UIViewController {
    SourceType type;
}

@property(nonatomic,strong) UIView *checkView;
@property(nonatomic,strong) UICheckButton *checkLive;
@property(nonatomic,strong) UICheckButton *checkVLC;
@property(nonatomic) UITapGestureRecognizer *tap;

@property(nonatomic,strong) UIButton *addStreamBut;
@property(nonatomic,strong) UITextField* url;
@property(nonatomic) UIAlertController* alert;

@end

