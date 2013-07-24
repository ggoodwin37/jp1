//
//  oal.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.


#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <UIKit/UIKit.h>

typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei*	outSampleRate);


//#define kDefaultDistance 25.0

@interface oalPlayback : NSObject
{
	NSArray								*resourceNames;
	
	ALuint						*sources;
	ALuint						*buffers;
	
	ALCcontext*				context;
	ALCdevice*				device;
	
	void*					data;
	CGPoint					sourcePos;
	CGPoint					listenerPos;
	CGFloat					listenerRotation;
	ALfloat					sourceVolume;
	BOOL					isPlaying;
	BOOL					wasInterrupted;
	
	UInt32					iPodIsPlaying;
	
}


- (id)initWithResourceNames:(NSArray *)resourceNamesIn;
- (void)startSound:(int)index pitchFactor:(float)pitchFactor;
- (void)stopSound:(int)index;

@end
