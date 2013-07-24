//
//  SoundManager.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "SoundManager.h"


// this class has mostly become a wrapper for an openAL setup that was jacked from oalTouch sample app.
//  I modified the sample to support multiple buffers and unhooked the listenerLocation stuff.

@interface SoundManager (private)


@end


@implementation SoundManager

-(id)init
{
	if( self = [super init] )
	{
		NSLog( @"TODO SoundManager: make me a singleton." );

		[self initPlayers];
	}
	return self;
}

-(void)dealloc
{
	[oalPlayer release];
	[super dealloc];
}



-(void)initPlayers
{

	NSArray *soundNames = [NSArray arrayWithObjects:

						// TODO: list sound resource names here.
						   
						   nil ];
	
	NSAssert( [soundNames count] + 1 == SoundIdCount, @"Missing sound names or ids problem?" );   // +1 for SoundIdNone

	oalPlayer = [[oalPlayback alloc] initWithResourceNames: soundNames];
	NSLog( @"openAL started OK." );
}


//Error setting audio session category

-(void)playSound:(SoundId)soundId
{
	
	if( soundId == SoundIdNone )
		return;
	
	[oalPlayer startSound:(int)soundId pitchFactor:1.0f ];

}



@end
