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

- (void) setImageCheckBox:(NSDictionary*) dict {
    self.checked = (UIImage*)[dict objectForKey:@"checked"];
    self.unchecked = (UIImage*)[dict objectForKey:@"unchecked"];
}

- (void) setupButtonWithTitle:(NSString*) title andDictImage:(NSDictionary*)dict andCheck:(BOOL)isChecked {
    [self setImageCheckBox:dict];
    
    if ( @available(iOS 15.0,*) ) {
        UIButtonConfiguration* configuration = [UIButtonConfiguration filledButtonConfiguration];
        [configuration setTitle:title];
        [configuration setImagePlacement:NSDirectionalRectEdgeLeading];
        [configuration setTitlePadding:5.0];
        [configuration setImagePadding:5.0];
        [configuration setContentInsets:NSDirectionalEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)];
        [self setConfiguration:configuration];
        
    } else {
        //
    }
    [self setCheck:isChecked];
}

- (void) setCheck:(BOOL)checked; {
    isCheck = checked;
    if (@available(iOS 15.0, *)) {
        if (isCheck) {
            [self.configuration setImage:self.checked];
        } else {
            [self.configuration setImage:self.unchecked];
        }
    } else {
        // Fallback on earlier versions
    }
}

- (BOOL) isChecking {
    return isCheck;
}

@end
