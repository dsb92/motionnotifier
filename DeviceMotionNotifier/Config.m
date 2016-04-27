//
//  Config.m
#import "Config.h"

// Not used yet
int APP_WEB_SERVICES_VERSION = 1;

#if DEBUG 
#warning all modules in debug mode
    #define ADS_IN_TEST_MODE
#endif

#ifndef ADS_IN_TEST_MODE
    NSString *const kConfigAdUnitBannerId = @"ca-app-pub-2595377837159656/1504782129";  // live
    NSString *const kConfigAdUnitInterstitialsId = @"ca-app-pub-2595377837159656/4903743727"
#else
    #warning ADS in debug mode:
    NSString *const kConfigAdUnitBannerId = @"ca-app-pub-3940256099942544/2934735716";  // test
    NSString *const kConfigAdUnitInterstitialsId = @"ca-app-pub-3940256099942544/4411468910";
#endif


@implementation Config


@end