//
//  Hubs.h
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 24/02/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonHMAC.h>
#import "HubInfo.h"
#import "RegisterClient.h"

@interface Hubs : NSObject

// create the Authorization header to perform Basic authentication with your app back-end
-(void) createAndSetAuthenticationHeaderWithUsername:(NSString*)username
                                         AndPassword:(NSString*)password;

- (void)SendNotificationASPNETBackend:(NSString*)pns UsernameTag:(NSString*)usernameTag
                              Message:(NSString*)message;

-(void) setDeviceToken: (NSData*) deviceToken;

-(void)ParseConnectionString;

-(NSString*) generateSasToken:(NSString*)uri;

-(void)SendToEnabledPlatforms;

- (void)SendNotificationRESTAPI;

-(void)MessageBox:(NSString *)title message:(NSString *)messageText;

@property (strong, nonatomic) NSData* deviceToken;
@property (strong, nonatomic) RegisterClient* registerClient;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *recipientName;
@property (strong, nonatomic) NSString *notificationMessage;
@property (strong, nonatomic) NSXMLParser *xmlParser;
@property (copy, nonatomic) NSString *currentElement;
@property(strong, nonatomic) NSString *statusResult;
@property BOOL notificationSeen;

@end
