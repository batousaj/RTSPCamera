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

@property(nonatomic,readwrite) UIButtonConfiguration *config API_AVAILABLE(ios(15.0), tvos(15.0)) API_UNAVAILABLE(watchos);
@property(nonatomic,assign) UIImage* checked;
@property(nonatomic,assign) UIImage* unchecked;

- (instancetype) initButtonCheckBox;
- (instancetype) initButtonWithFrame:(CGRect) frame;

- (void) setImageCheckBox:(NSMutableDictionary*) dict;
- (void) setupButtonWithTitle:(NSString*) title andDictImage:(NSMutableDictionary*)dict andCheck:(BOOL)isChecked;

- (void) setCheck:(BOOL)checked;
- (BOOL) isChecking;

@end
