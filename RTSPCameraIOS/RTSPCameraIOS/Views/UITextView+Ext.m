//
//  UITextView+Ext.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>
#import "UITextView+Ext.h"

@implementation UITextField (custom)

- (void) setLeftPadding:(CGFloat) amount {
    UIView *leftPadding = [[UIView alloc]initWithFrame:CGRectMake(0, 0, amount, self.frame.size.height)];
    self.leftView = leftPadding;
    self.leftViewMode = UITextFieldViewModeAlways;
}

- (void) setRightPadding:(CGFloat) amount  {
    UIView *rightPadding = [[UIView alloc]initWithFrame:CGRectMake(0, 0, amount, self.frame.size.height)];
    self.rightView = rightPadding;
    self.rightViewMode = UITextFieldViewModeAlways;
}

@end
