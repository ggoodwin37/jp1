//
//  SpriteDef.m
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpriteDef.h"




/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteSheet
@implementation SpriteSheet

@synthesize name = m_name, nativeSize = m_nativeSize, texName = m_texName;
@synthesize isMemImage, memImage, imageBuffer;

-(id)initWithName:(NSString *)name
{
    if( self = [super init] )
    {
        m_name = [name retain];
        self.imageBuffer = nil;
        
    }
    return self;
}


-(void)dealloc
{
    self.imageBuffer = nil;  // NSData owns the backing buffer and will free it now.
    [m_name release]; m_name = nil;
    [super dealloc];    
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteDef
@implementation SpriteDef

@synthesize name = m_name, spriteSheet = m_spriteSheet, nativeBounds = m_nativeBounds, worldSize = m_worldSize;
@synthesize isFlipped = m_isFlipped;


-(id)initWithName:(NSString *)name spriteSheet:(SpriteSheet *)spriteSheet nativeBounds:(CGRect)nativeBounds isFlipped:(BOOL)isFlipped worldSize:(CGSize)worldSize
{
    if( self = [super init] )
    {
        m_name = [name retain];
        m_spriteSheet = [spriteSheet retain];
        m_nativeBounds = nativeBounds;
        m_isFlipped = isFlipped;
        m_worldSize = worldSize;
    }
    return self;
}


-(void)dealloc
{
    [m_spriteSheet release]; m_spriteSheet = nil;
    [m_name release]; m_name = nil;
    [super dealloc];    
}


-(GLfloat *)getTexCoordsCache
{
    return &m_texCoordsCache[0];
}


// happens when optimizing spritesheets at load time.
-(void)updateWithNewSheet:(SpriteSheet *)newSheet newBounds:(CGRect)newBounds
{
    [m_spriteSheet release];
    m_spriteSheet = [newSheet retain];
    m_nativeBounds = newBounds;
}


-(NSComparisonResult)compareHeightDecreasing:(SpriteDef *)other
{
    if( m_nativeBounds.size.height > other.nativeBounds.size.height )
    {
        return NSOrderedAscending;  // biggest height first.
    }
    else if( m_nativeBounds.size.height < other.nativeBounds.size.height )
    {
        return NSOrderedDescending;
    }
    else
    {
        return NSOrderedSame;
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimFrameDef
@implementation AnimFrameDef

@synthesize sprite = m_sprite, relativeDur = m_relativeDur;


-(id)initWithSprite:(SpriteDef *)sprite relativeDur:(float)relativeDur
{
    if( self = [super init] )
    {
        m_sprite = [sprite retain];
        m_relativeDur = relativeDur;
    }
    return self;
}


-(void)dealloc
{
    [m_sprite release]; m_sprite = nil;
    [super dealloc];    
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimDef
@interface AnimDef (private)
-(void)normalizeFrameDurations;

@end

@implementation AnimDef

@synthesize name = m_name;


-(id)initWithName:(NSString *)name frames:(NSArray *)frames
{
    if( self = [super init] )
    {
        m_name = [name retain];
        m_frames = [frames retain];
        
        [self normalizeFrameDurations];
    }
    return self;
}


-(void)dealloc
{
    [m_name release]; m_name = nil;
    [m_frames release]; m_frames = nil;
    [super dealloc];    
}


-(void)normalizeFrameDurations
{
    float totalDur = 0.f;
    for( int i = 0; i < [m_frames count]; ++i )
    {
        AnimFrameDef *thisFrame = (AnimFrameDef *)[m_frames objectAtIndex:i];
        totalDur += thisFrame.relativeDur;
    }

    if( totalDur <= 0.f )
    {
        NSLog( @"normalizeFrameDurations: invalid totalDur?" );
        return;
    }
    
    for( int i = 0; i < [m_frames count]; ++i )
    {
        AnimFrameDef *thisFrame = (AnimFrameDef *)[m_frames objectAtIndex:i];
        thisFrame.relativeDur = thisFrame.relativeDur / totalDur;
    }
}


-(int)getNumFrames
{
    return [m_frames count];
}


-(AnimFrameDef *)getFrame:(int)i
{
    return (AnimFrameDef *)[m_frames objectAtIndex:i];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ToggleDef
@implementation ToggleDef

@synthesize name = m_name, offSprite = m_offSprite, onSprite = m_onSprite;

-(id)initWithName:(NSString *)name offSprite:(SpriteDef *)offSprite onSprite:(SpriteDef *)onSprite
{
    if( self = [super init] )
    {
        m_name = [name retain];
        m_offSprite = [offSprite retain];
        m_onSprite = [onSprite retain];
    }
    return self;
}


-(void)dealloc
{
    [m_offSprite release]; m_offSprite = nil;
    [m_onSprite release]; m_onSprite = nil;
    [m_name release]; m_name = nil;
    [super dealloc];
}

@end
