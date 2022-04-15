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

@property(nonatomic,assign) UIImage* checked;
@property(nonatomic,assign) UIImage* unchecked;

- (instancetype) initButtonCheckBox;
- (instancetype) initButtonWithFrame:(CGRect) frame;

- (void) setImageCheckBox:(NSDictionary*) dict;
- (void) setupButtonWithTitle:(NSString*) title andDictImage:(NSDictionary*)dict andCheck:(BOOL)isChecked;

- (void) setCheck:(BOOL)checked;
- (BOOL) isChecking;

@end
