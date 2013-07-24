//
//  JumpProtoAppDelegate.m
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JumpProtoAppDelegate.h"

#import "JumpProtoLaunchViewController.h"

@implementation JumpProtoAppDelegate


@synthesize window=_window;

@synthesize viewController=_viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // would prefer to do this in the nib...
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
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
