//
//  VideoStreamController.h
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoView.h"
#import "Model.h"

@interface VideoViewController : UIViewController {
    NSURL* url;
    BOOL islive555;
    BOOL isToggle;
    SourceType type;
}

@property(nonatomic,strong) VideoView* video;
@property(nonatomic,strong) UITapGestureRecognizer *tapped;

- (void) setURL:(NSString*)url;
- (void) setSourceUsing:(SourceType) source;

@end

