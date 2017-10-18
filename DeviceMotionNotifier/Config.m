//
//  Config.m
#import "Config.h"

// Not used yet
int APP_WEB_SERVICES_VERSION = 1;

NSString *const kAboutUrl = @"http://dabdeveloper.wix.com/gotyah";

#if DEBUG || TEST
#warning all modules in debug mode
    #define LAYOUT_IN_TEST_MODE
    #define TIMER_LAY_TEST_MODE
#endif

#ifndef LAYOUT_IN_TEST_MODE
    const BOOL kDebugLayout = NO; // live
#else
    const BOOL kDebugLayout = YES; // test
#endif

#ifndef TIMER_LAY_TEST_MODE
    const NSUInteger kNotificationExpiration = 31;
    const NSUInteger kCountDownDelay = 11; // live
    const NSUInteger kDelayCountDown = 4;
#else
    const NSUInteger kCountDownDelay = 4; // test
    const NSUInteger kDelayCountDown = 4;
    const NSUInteger kNotificationExpiration = 10;
#endif

NSString *const kConfigAdAppId= @"ca-app-pub-8950051795385970~6412082183";
NSString *const kConfigAdUnitBannerId = @"ca-app-pub-8950051795385970/7533592165";
NSString *const kConfigAdUnitInterstitialsId = @"ca-app-pub-8950051795385970/5002087156";

@implementation Config


@end
