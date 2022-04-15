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

- (NSMutableDictionary *) getImageCheckBox {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    UIImage *image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    [dict setObject:image forKey:@"checked"];
    UIImage *img = [UIImage systemImageNamed:@"circle"];
    [dict setObject:img forKey:@"unchecked"];
    return dict;
}

@end
