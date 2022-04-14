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
        //
    }
    return self;
}

- (void) setCheck:(BOOL)checked; {
    isCheck = checked;
}

- (BOOL) isChecking {
    return isCheck;
}

@end
