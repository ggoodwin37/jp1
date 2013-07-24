//
//  SoundManager.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import <Foundation/Foundation.h>
//#import <AVFoundation/AVFoundation.h>
#import "oal.h"
#import "gutil.h"


// assumes that these are in the same order as the sound resource name list.

enum SoundIdEnum
{

	
	
	SoundIdNone,  // NEXT TO LAST
	SoundIdCount  // LAST
};
typedef enum SoundIdEnum SoundId;



@interface SoundManager : NSObject {

	oalPlayback							*oalPlayer;
}

-(void)initPlayers;
-(void)playSound:(SoundId)soundId;

@end
