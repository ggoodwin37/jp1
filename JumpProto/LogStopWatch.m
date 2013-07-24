//
//  LogStopWatch.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "LogStopWatch.h"

@implementation LogStopWatch

@synthesize name,started,startTime;

-(id)initWithName:(NSString*)nameIn
{
	self = [super init];
	if(self)
	{
		self.name = nameIn;
	}
	return self;
}

-(void)start
{
	if(self.started)
	{
		NSLog(@"stopwatch: start called while already started. Restarting.");
		[self stop];
	}
	self.started = YES;
	self.startTime = getUpTimeMs();
}

-(void)stop
{
	if(self.started)
	{
		long diff = getUpTimeMs() - self.startTime;
#ifdef STOPWATCH_REPORT
		NSLog( @"stopwatch %@: %d msec", self.name, (int)diff );
#endif
		self.started = NO;
	}
	else
	{
		NSLog(@"stopwatch: stop called when not started, ignoring.");
	}
}


@end
