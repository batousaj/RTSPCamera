//
//  UIButtonView+Ext.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 14/04/2022.
//

#import <UIKit/UIKit.h>

@interface UICheckButton : UIButton {
    BOOL isCheck;
}

- (instancetype) initButtonCheckBox;
- (instancetype) initButtonWithFrame:(CGRect) frame;

- (void) setCheck:(BOOL)checked;
- (BOOL) isChecking;

@end
