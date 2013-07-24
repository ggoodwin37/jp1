//
//  ES1RenderDelegate.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.



#import <UIKit/UIKit.h>


@protocol ES1RenderDelegate <NSObject>

-(void)renderNextFrameWithTimeStamp:(CFTimeInterval)timeStamp;
-(void)afterPresentScene;
-(void)resetTimeStamp;

@end
