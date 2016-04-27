//
//  ObjC.m
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 27/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

#import "ObjC.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
    }
}

@end
