//
//  NavigatorBar.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import <Foundation/Foundation.h>
#import "UINavigationController+Config.h"

@implementation UINavigationController (Config)

- (void) setUpAppNavigation {
    if ( @available(iOS 13.0,*) ) {
        UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
        [navBarAppearance configureWithOpaqueBackground];
        navBarAppearance.backgroundColor = [UIColor lightGrayColor];
        [navBarAppearance setTitleTextAttributes:
                @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//        self.navigationBar.tintColor = UIColor.whiteColor;
        self.navigationBar.standardAppearance = navBarAppearance;
        self.navigationBar.scrollEdgeAppearance = navBarAppearance;
    }
}

@end
