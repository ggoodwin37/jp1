//
//  oal.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "oal.h"


ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
	static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
	
    return;
}

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei*	outSampleRate)
{
	OSStatus						err = noErr;	
	SInt64							theFileLengthInFrames = 0;
	AudioStreamBasicDescription		theFileFormat;
	UInt32							thePropertySize = sizeof(theFileFormat);
	ExtAudioFileRef					extRef = NULL;
	void*							theData = NULL;
	AudioStreamBasicDescription		theOutputFormat;
	
	// Open a file with ExtAudioFileOpen()
	err = ExtAudioFileOpenURL(inFileURL, &extRef);
	if(err) { printf("MyGetOpenALAudioData: ExtAudioFileOpenURL FAILED, Error = %d\n", (int)err); goto Exit; }
	
	// Get the audio data format
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &theFileFormat);
	if(err) { printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %d\n", (int)err); goto Exit; }
	if (theFileFormat.mChannelsPerFrame > 2)  { printf("MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n"); goto Exit;}
	
	// Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = theFileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame;
	
	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 16;
	theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	
	// Set the desired client (output) data format
	err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(theOutputFormat), &theOutputFormat);
	if(err) { printf("MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %d\n", (int)err); goto Exit; }
	
	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if(err) { printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %d\n", (int)err); goto Exit; }
	
	// Read all the data into memory
	UInt32		dataSize = (unsigned int)(theFileLengthInFrames * theOutputFormat.mBytesPerFrame);
	theData = malloc(dataSize);
	if (theData)
	{
		AudioBufferList		theDataBuffer;
		theDataBuffer.mNumberBuffers = 1;
		theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
		theDataBuffer.mBuffers[0].mData = theData;
		
		// Read the data into an AudioBufferList
		err = ExtAudioFileRead(extRef, (UInt32*)&theFileLengthInFrames, &theDataBuffer);
		if(err == noErr)
		{
			// success
			*outDataSize = (ALsizei)dataSize;
			*outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
			*outSampleRate = (ALsizei)theOutputFormat.mSampleRate;
		}
		else 
		{ 
			// failure
			free (theData);
			theData = NULL; // make sure to return NULL
			printf("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %d\n", (int)err); goto Exit;
		}	
	}
	
Exit:
	// Dispose the ExtAudioFileRef, it is no longer needed
	if (extRef) ExtAudioFileDispose(extRef);
	return theData;
}





@interface oalPlayback (private)
- (void)teardownOpenAL;
- (void)initOpenAL;

@end


@implementation oalPlayback


#pragma mark Object Init / Maintenance
void interruptionListener(	void *	inClientData,
						  UInt32	inInterruptionState)
{
	oalPlayback* THIS = (oalPlayback*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		alcMakeContextCurrent(NULL);		
		//			if ([THIS isPlaying]) {
		//				THIS.wasInterrupted = YES;
		//			}
	}
	else if (inInterruptionState == kAudioSessionEndInterruption)
	{
		OSStatus result = AudioSessionSetActive(true);
		if (result) NSLog(@"Error setting audio session active! %d\n", (int)result);
		
		alcMakeContextCurrent(THIS->context);
		
		//		if (THIS.wasInterrupted)
		//		{
		//			[THIS startSound];			
		//			THIS.wasInterrupted = NO;
		//		}
	}
}

void RouteChangeListener(	void *                  inClientData,
						 AudioSessionPropertyID	inID,
						 UInt32                  inDataSize,
						 const void *            inData)
{
	CFDictionaryRef dict = (CFDictionaryRef)inData;
	
	CFStringRef oldRoute = CFDictionaryGetValue(dict, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
	
	UInt32 size = sizeof(CFStringRef);
	
	CFStringRef newRoute;
	OSStatus result = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
	
	NSLog(@"result: %d Route changed from %@ to %@", (int)result, oldRoute, newRoute);
}

- (id)initWithResourceNames:(NSArray *)resourceNamesIn
{	
	if (self = [super init]) {
		
		resourceNames = [resourceNamesIn retain];
		
		int nameListSize = (int)([resourceNames count] * sizeof( ALuint ));
		sources = (ALuint *)malloc( nameListSize );
		buffers = (ALuint *)malloc( nameListSize );
		
		// Start with our sound source slightly in front of the listener
		sourcePos = CGPointMake(0., -70.);
		
		// Put the listener in the center of the stage
		listenerPos = CGPointMake(0., 0.);
		
		// Listener looking straight ahead
		listenerRotation = 0.;
		
		// setup our audio session
		OSStatus result = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
		if (result) NSLog(@"Error initializing audio session! %d\n", (int)result);
		else {
			// if there is other audio playing, we don't want to play the background music
			UInt32 size = sizeof(iPodIsPlaying);
			result = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &iPodIsPlaying);
			if (result) NSLog(@"Error getting other audio playing property! %d", (int)result);
			
			// if the iPod is playing, use the ambient category to mix with it
			// otherwise, use solo ambient to get the hardware for playing the app background track
			UInt32 category = (iPodIsPlaying) ? kAudioSessionCategory_AmbientSound : kAudioSessionCategory_SoloAmbientSound;
			
			// REVIEW: this fires some times during init, but I think I've only seen it in the simulator. ignorable?
			result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
			if (result) NSLog(@"Error setting audio session category! %d\n", (int)result);
			
			result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, RouteChangeListener, self);
			if (result) NSLog(@"Couldn't add listener: %d", (int)result);
			
			result = AudioSessionSetActive(true);
			if (result) NSLog(@"Error setting audio session active! %d\n", (int)result);
		}
		
		wasInterrupted = NO;
		
		// Initialize our OpenAL environment
		[self initOpenAL];
	}
	
	return self;
}

- (void)checkForMusic
{
	if (iPodIsPlaying) {
		//the iPod is playing, so we should disable the background music switch
		NSLog(@"iPod is active. Don't care.");
		//musicSwitch.enabled = NO;
	}
	else {
		//musicSwitch.enabled = YES;
	}
}

- (void)dealloc
{
	[super dealloc];
	[self teardownOpenAL];
	
	[resourceNames release]; resourceNames = nil;
	free( sources );
	free( buffers );
	
}

#pragma mark OpenAL

- (void) initBuffer:(int) bufferIndex withResourceName:(NSString *)resourceName
{
	ALenum  error = AL_NO_ERROR;
	ALenum  format;
	ALsizei size;
	ALsizei freq;
	
	NSBundle*				bundle = [NSBundle mainBundle];
	
	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource:resourceName ofType:@"wav"]] retain];
	
	if (fileURL)
	{	
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		CFRelease(fileURL);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"error loading sound: %x\n", error);
			exit(1);
		}
		
		// use the static buffer data API
		alBufferDataStaticProc(buffers[bufferIndex], format, data, size, freq);
		
		if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"error attaching audio to buffer: %x\n", error);
		}		
	}
	else
		NSLog(@"Could not find file!\n");
}


- (void) initSource:(int)sourceIndex
{
	ALenum error = AL_NO_ERROR;
	alGetError(); // Clear the error
	
	// Turn Looping ON....not
	alSourcei(sources[sourceIndex], AL_LOOPING, AL_FALSE);
	
	// Set Source Position
	float sourcePosAL[] = {sourcePos.x, 25.0, sourcePos.y};
	alSourcefv(sources[sourceIndex], AL_POSITION, sourcePosAL);
	
	// Set Source Reference Distance
	alSourcef(sources[sourceIndex], AL_REFERENCE_DISTANCE, 50.0f);
	
	// attach OpenAL Buffer to OpenAL Source
	alSourcei(sources[sourceIndex], AL_BUFFER, buffers[sourceIndex]);
	
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"Error attaching buffer to source: %x\n", error);
		exit(1);
	}	
}


- (void)initOpenAL
{
	ALenum			error;
	
	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	device = alcOpenDevice(NULL);
	if (device != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		context = alcCreateContext(device, 0);
		if (context != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(context);
			
			int numObjects = (int)[resourceNames count];
			
			// Create some OpenAL Buffer Objects
			alGenBuffers(numObjects, buffers);
			if((error = alGetError()) != AL_NO_ERROR) {
				NSLog(@"Error Generating Buffers: %x", error);
				exit(1);
			}
			
			// Create some OpenAL Source Objects
			alGenSources(numObjects, sources);
			if(alGetError() != AL_NO_ERROR) 
			{
				NSLog(@"Error generating sources! %x\n", error);
				exit(1);
			}
			
		}
	}
	// clear any errors
	alGetError();
	
	for( int i = 0; i < [resourceNames count]; ++i )
	{
		[self initBuffer:i withResourceName:[resourceNames objectAtIndex:i]];	
		[self initSource:i];
	}
}

- (void)teardownOpenAL
{	
	int numObjects = (int)[resourceNames count];
	
	// Delete the Sources
    alDeleteSources(numObjects, sources);
	// Delete the Buffers
    alDeleteBuffers(numObjects, buffers);
	
    //Release context
    alcDestroyContext(context);
    //Close device
    alcCloseDevice(device);
}

#pragma mark Play / Pause

- (void)startSound:(int)index pitchFactor:(float)pitchFactor
{
	ALenum error;
	
	[self stopSound:index];
	alSourceRewind( sources[index] );
	
	// set pitch factor.
	alSourcef( sources[index], AL_PITCH, pitchFactor );
	
	alSourcePlay(sources[index]);
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"error starting source: %x\n", error);
	}
}

- (void)stopSound:(int)index
{
	ALenum error;
	
	//NSLog(@"Stop!!\n");
	// Stop playing our source file
	alSourceStop(sources[index]);
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"error stopping source: %x\n", error);
	}
}

//#pragma mark Setters / Getters
//
//- (CGPoint)sourcePos
//{
//	return sourcePos;
//}
//
//- (void)setSourcePos:(CGPoint)SOURCEPOS
//{
//	sourcePos = SOURCEPOS;
//	float sourcePosAL[] = {sourcePos.x, kDefaultDistance, sourcePos.y};
//	// Move our audio source coordinates
//	alSourcefv(source, AL_POSITION, sourcePosAL);
//}
//
//
//
//- (CGPoint)listenerPos
//{
//	return listenerPos;
//}
//
//- (void)setListenerPos:(CGPoint)LISTENERPOS
//{
//	listenerPos = LISTENERPOS;
//	float listenerPosAL[] = {listenerPos.x, 0., listenerPos.y};
//	// Move our listener coordinates
//	alListenerfv(AL_POSITION, listenerPosAL);
//}
//
//
//
//- (CGFloat)listenerRotation
//{
//	return listenerRotation;
//}
//
//- (void)setListenerRotation:(CGFloat)radians
//{
//	listenerRotation = radians;
//	float ori[] = {cos(radians + M_PI_2), sin(radians + M_PI_2), 0., 0., 0., 1.};
//	// Set our listener orientation (rotation)
//	alListenerfv(AL_ORIENTATION, ori);
//}

@end

