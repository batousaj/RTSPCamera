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

@interface ViewController : UIViewController {
    SourceType type;
}

@property(nonatomic,strong) UIButton *addStreamBut;
@property(nonatomic,strong) UITextField* url;
@property(nonatomic) UIAlertController* alert;

@end

