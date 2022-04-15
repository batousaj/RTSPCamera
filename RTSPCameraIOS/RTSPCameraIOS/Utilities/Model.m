//
//  Model.m
//  RTSPCameraIOS
//
//  Created by Thien Vu on 15/04/2022.
//

#import <UIKit/UIKit.h>
#import "Model.h"

@implementation Model

// define a singleton class
+ (Model*) shareInstance {
    static Model* model;
    @synchronized (model) {
        if (!model) {
            model = [[Model alloc] init];
            
        }
        return model;
    }
}

- (NSDictionary*) getImageCheckBox {
    NSDictionary* dict = [[NSDictionary alloc] init];
    UIImage *image = [UIImage imageNamed:@""];
    [dict setValue:image forKey:@"checked"];
    UIImage *img = [UIImage imageNamed:@""];
    [dict setValue:img forKey:@"unchecked"];
    return dict;
}

@end
