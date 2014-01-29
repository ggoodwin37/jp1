//
//  JumpProtoAppDelegate.m
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JumpProtoAppDelegate.h"
#import "JumpProtoLaunchViewController.h"
#import "JumpProtoLaunchViewPhoneController.h"

@implementation JumpProtoAppDelegate


@synthesize window=_window;

@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    [self setUpVC];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    return YES;
}


-(void)setUpVC
{
    // TODO: consider making this more robust before shipping (haha)
    NSString *deviceType = [UIDevice currentDevice].model;
    BOOL isIPad = ([deviceType rangeOfString:@"iPad"].location != NSNotFound);
    if (isIPad) {
        self.viewController = [[JumpProtoLaunchViewController alloc] init];
    } else {
        self.viewController = [[JumpProtoLaunchViewPhoneController alloc] init];
    }
    [self.window addSubview:self.viewController.view];
    JumpProtoLaunchViewControllerBase *baseVC = (JumpProtoLaunchViewControllerBase *)self.viewController;
    [baseVC onAwake];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.viewController onAppStop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.viewController onAppStop];
    NSLog( @"applicationDidEnterBackground" );
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.viewController onAppStart];
    NSLog( @"applicationWillEnterForeground" );
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.viewController onAppStart];
    NSLog( @"applicationDidBecomeActive" );
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.viewController onAppStop];
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}


@end
