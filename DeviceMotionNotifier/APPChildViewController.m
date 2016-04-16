//
//  APPChildViewController.m
//  PageApp
//
//  Created by Rafael Garcia Leiva on 10/06/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "APPChildViewController.h"
#import "DeviceMotionNotifier-Swift.h"

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
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.screenNumber.text = [NSString stringWithFormat:@"Screen #%d", self.index];
    
    [self setImage];
    
    if (self.index == 4) {
        SettingsTheme *theme = [SettingsTheme theme01];
        _beginButton.borderColor = theme.primaryColor;
        [_beginButton setTitleColor:theme.secondaryColor forState:UIControlStateNormal];
        _beginButton.hidden = false;
        
    }
    else{
        _beginButton.hidden = true;
    }
}

- (void) setImage {
    
}

- (IBAction)beginButton:(MonitorButton *)sender {
    [sender animateTouchUpInsideCompletion:^{
        UIStoryboard *mainRegisterSB = [UIStoryboard storyboardWithName:@"MainRegister" bundle:nil];
        UIViewController *initialVC = [mainRegisterSB instantiateInitialViewController];
        [self presentViewController:initialVC animated:true completion:nil];
    }];
}


@end
