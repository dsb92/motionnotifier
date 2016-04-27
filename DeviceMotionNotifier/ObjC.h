//
//  ObjC.h
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 27/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end
