//
//  LogStopWatch.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import <Foundation/Foundation.h>
#import "gutil.h"
#import "constants.h"

@interface LogStopWatch : NSObject {
	NSString *name;
	BOOL started;
	long startTime;
}

@property(nonatomic,readwrite,assign) NSString* name;
@property(nonatomic,readwrite,assign) BOOL started;
@property(nonatomic,readwrite,assign) long startTime;

-(id)initWithName:(NSString*)name;
-(void)start;
-(void)stop;

@end
