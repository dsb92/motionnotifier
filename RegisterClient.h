//
//  RegisterClient.h
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisterClient : NSObject

@property (strong, nonatomic) NSString* authenticationHeader;

-(void) registerWithDeviceToken:(NSData*)token tags:(NSSet*)tags
                  andCompletion:(void(^)(NSError*))completion;

-(instancetype) initWithEndpoint:(NSString*)Endpoint;

@end