//
//  Config.m
#import "Config.h"

// Not used yet
int APP_WEB_SERVICES_VERSION = 1;

NSString *const kAboutUrl = @"http://dabdeveloper.wix.com/gotyah";

#if DEBUG || TEST
#warning all modules in debug mode
    #define ADS_IN_TEST_MODE
    #define LAYOUT_IN_TEST_MODE
    #define TIMER_LAY_TEST_MODE
#endif

#ifndef ADS_IN_TEST_MODE
    NSString *const kConfigAdUnitBannerId = @"ca-app-pub-9818395476815781/2955409368";  // live
    NSString *const kConfigAdUnitInterstitialsId = @"ca-app-pub-9818395476815781/6675162529";
#else
    #warning ADS in debug mode:
    NSString *const kConfigAdUnitBannerId = @"ca-app-pub-3940256099942544/2934735716";  // test
    NSString *const kConfigAdUnitInterstitialsId = @"ca-app-pub-3940256099942544/4411468910";
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

@implementation Config


@end
