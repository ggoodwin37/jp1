//
//  JumpProtoAppDelegate.h
//  JumpProto
//
//  Created by gideong on 7/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IAppStartStop <NSObject>

-(void)onAppStart;
-(void)onAppStop;

@end


@class JumpProtoLaunchViewController;

@interface JumpProtoAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet JumpProtoLaunchViewController *viewController;

@end
