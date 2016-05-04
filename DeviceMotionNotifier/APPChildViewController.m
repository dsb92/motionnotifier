//
//  APPChildViewController.m
//  PageApp
//
//  Created by Rafael Garcia Leiva on 10/06/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "APPChildViewController.h"
#import "DeviceMotionNotifier-Swift.h"
#import "Page.h"

@interface APPChildViewController ()
@property (weak, nonatomic) IBOutlet UILabel *mainLine;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *subLine;
@property (weak, nonatomic) IBOutlet MonitorButton *beginButton;
@end

@implementation APPChildViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
        if (self.pages == nil) {
            Page *page1 = [[Page alloc]init];
            Page *page2 = [[Page alloc]init];
            Page *page3 = [[Page alloc]init];
            Page *page4 = [[Page alloc]init];
            
            // page 1
            page1.mainLine = @"Welcome";
            page1.subLine = @"This app detects when this device is being moved and recognizes sound when the alarm is armed";
            page1.imageName = @"page1.png";
            
            // page 2
            page2.mainLine = @"How does it work?";
            page2.subLine = @"If you move this device or speak very loudly into the microphone, the app will play a noisy sound and send push messages to your other registered device";
            page2.imageName = @"page2.png";
            
            // page 3
            page3.mainLine = @"...then what?";
            page3.subLine = @"The app instantly snaps a photo or records a video using your front camera. And saves it to the iCloud.";
            page3.imageName = @"page3.jpg";
            
            // page 4
            page4.mainLine = @"Useful for what exactly?";
            page4.subLine = @"Catch thieves in the act or let yourself know when your baby starts to cry!";
            page4.imageName = @"page4.jpg";
            
            self.pages = [[NSArray alloc]initWithObjects:page1, page2, page3, page4, nil];
        }
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setPage];
    
    if (self.index == _maxPages-1) {
        SettingsTheme *theme = [SettingsTheme theme01];
        _beginButton.borderColor = theme.blueColor;
        [_beginButton setTitleColor:theme.blackColor forState:UIControlStateNormal];
        _beginButton.hidden = false;
        
    }
    else{
        _beginButton.hidden = true;
    }
}

- (void) setPage {
    NSLog(@"Page index %ld", (long)self.index);
    Page *page = [self.pages objectAtIndex:self.index];
    _mainLine.text = page.mainLine;
    _subLine.text = page.subLine;
    _imageView.image = [UIImage imageNamed:page.imageName];
}

- (IBAction)beginButton:(MonitorButton *)sender {
    [sender animateTouchUpInsideCompletion:^{
        UIStoryboard *mainRegisterSB = [UIStoryboard storyboardWithName:@"MainRegister" bundle:nil];
        UIViewController *initialVC = [mainRegisterSB instantiateInitialViewController];
        [self presentViewController:initialVC animated:true completion:nil];
    }];
}


@end
