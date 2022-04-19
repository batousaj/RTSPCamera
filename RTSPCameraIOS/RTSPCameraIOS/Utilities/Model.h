//
//  Model.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SourceType) {
    kLive555        = 0,
    kVLCMedia       = 1,
    kNoneSrc           = 2,
};

@interface Model : NSObject

+ (Model*) shareInstance;

- (NSMutableDictionary*) getImageCheckBox;

@end
