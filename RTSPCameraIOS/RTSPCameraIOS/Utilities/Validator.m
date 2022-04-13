//
//  Utilities.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 13/04/2022.
//

#import "Validator.h"


@implementation Validator

+ (BOOL) isValidURL:(NSString *)url {
    NSString *valid = @"(?i)(http?|https|rtsp)://(?:www\\.)?\\S+(?:/|\\b)";
    NSPredicate *result = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",valid];
    return [result evaluateWithObject:url];
}

@end
