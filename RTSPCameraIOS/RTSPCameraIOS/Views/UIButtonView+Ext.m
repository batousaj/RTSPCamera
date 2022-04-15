//
//  UIButtonView+Ext.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 14/04/2022.
//

#import <Foundation/Foundation.h>
#import "UIButtonView+Ext.h"

@implementation UICheckButton

- (instancetype)initButtonCheckBox {
    if ( self = [super init]) {
        //
    }
    return self;
}

- (instancetype) initButtonWithFrame:(CGRect) frame {
    if ( self = [super initWithFrame:frame]) {
        isCheck = NO;
    }
    return self;
}

- (void) setImageCheckBox:(NSMutableDictionary*) dict {
    self.checked = (UIImage*)[dict objectForKey:@"checked"];
    self.unchecked = (UIImage*)[dict objectForKey:@"unchecked"];
}

- (void) setupButtonWithTitle:(NSString*) title andDictImage:(NSMutableDictionary*)dict andCheck:(BOOL)isChecked {
    [self setImageCheckBox:dict];
    
    if ( @available(iOS 15.0,*) ) {
        self.config = [UIButtonConfiguration plainButtonConfiguration];
        [self.config setTitle:title];
        [self.config setBaseForegroundColor:[UIColor blackColor]];
        [self.config setImagePlacement:NSDirectionalRectEdgeLeading];
        [self.config setTitlePadding:5.0];
        [self.config setImagePadding:5.0];
        [self.config setContentInsets:NSDirectionalEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)];
        [self setCheck:isChecked];
    } else {
        [self setTitle:title forState:UIControlStateNormal];
        [self setCheck:isChecked];
    }
    
}

- (void) setImageCheck {
    if ( @available(iOS 15.0,*) ) {
        if (isCheck) {
            [self.config setImage:self.checked];
        } else {
            [self.config setImage:self.unchecked];
        }
        [self setConfiguration:self.config];
    } else {
        if (isCheck) {
            [self setImage:self.checked forState:UIControlStateNormal];
            [self setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5.0)];
            
        } else {
            [self setImage:self.unchecked forState:UIControlStateNormal];
            [self setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5.0)];
           
        }
    }
}

- (void) setCheck:(BOOL)checked {
    isCheck = checked;
    [self setImageCheck];
}

- (BOOL) isChecking {
    return isCheck;
}

@end
