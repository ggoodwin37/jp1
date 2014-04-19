//
//  ArchiveFormat.m
//  JumpProto
//
//  Created by gideong on 10/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ArchiveFormat.h"



/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFBlockProps

@implementation AFBlockProps

@synthesize token = m_token, canMoveFreely = m_canMoveFreely, affectedByGravity = m_affectedByGravity,
            affectedByFriction = m_affectedByFriction, bounceDampFactor = m_bounceDampFactor,
            initialVelocity = m_initialVelocity;

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        self.token =              [((NSNumber *)[decoder decodeObjectForKey:@"token"]) unsignedIntValue];
        self.canMoveFreely =      [((NSNumber *)[decoder decodeObjectForKey:@"canMoveFreely"]) boolValue];
        self.affectedByGravity =  [((NSNumber *)[decoder decodeObjectForKey:@"affectedByGravity"]) boolValue];
        self.affectedByFriction = [((NSNumber *)[decoder decodeObjectForKey:@"affectedByFriction"]) boolValue];
        self.bounceDampFactor =   [((NSNumber *)[decoder decodeObjectForKey:@"bounceDampFactor"]) floatValue];
        float ivx, ivy;
        ivx =                     [((NSNumber *)[decoder decodeObjectForKey:@"ivx"]) floatValue];;
        ivy =                     [((NSNumber *)[decoder decodeObjectForKey:@"ivy"]) floatValue];;
        self.initialVelocity = CGPointMake( ivx, ivy );
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:self.token]       forKey:@"token"];
    [encoder encodeObject:[NSNumber numberWithBool:self.canMoveFreely]      forKey:@"canMoveFreely"];
    [encoder encodeObject:[NSNumber numberWithBool:self.affectedByGravity]  forKey:@"affectedByGravity"];
    [encoder encodeObject:[NSNumber numberWithBool:self.affectedByFriction] forKey:@"affectedByFriction"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.bounceDampFactor]  forKey:@"bounceDampFactor"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.initialVelocity.x] forKey:@"ivx"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.initialVelocity.y] forKey:@"ivy"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFBlock

@implementation AFBlock

@synthesize props = m_props, rect = m_rect, groupId = m_groupId;

-(id)initWithProps:(AFBlockProps *)props rect:(CGRect)rect groupId:(GroupId)groupId
{
    if( self = [super init] )
    {
        self.props = props;
        self.rect = rect;
        self.groupId = groupId;
    }
    return self;
}


-(void)dealloc
{
    self.props = nil;
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        self.props = [decoder decodeObjectForKey:@"props"];
        float x, y, w, h;
        x = [((NSNumber *)[decoder decodeObjectForKey:@"x"]) floatValue];
        y = [((NSNumber *)[decoder decodeObjectForKey:@"y"]) floatValue];
        w = [((NSNumber *)[decoder decodeObjectForKey:@"w"]) floatValue];
        h = [((NSNumber *)[decoder decodeObjectForKey:@"h"]) floatValue];
        self.rect = CGRectMake( x, y, w, h );
        
        NSNumber *pVal = (NSNumber *)[decoder decodeObjectForKey:@"groupId"];
        if( pVal != nil )
        {
            self.groupId = (GroupId)[pVal intValue];
        }
        else
        {
            self.groupId = GROUPID_NONE;
        }
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.props                                        forKey:@"props"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.origin.x]     forKey:@"x"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.origin.y]     forKey:@"y"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.size.width]   forKey:@"w"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.size.height]  forKey:@"h"];
    [encoder encodeObject:[NSNumber numberWithInt:self.groupId]             forKey:@"groupId"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFSpriteBlock

@implementation AFSpriteBlock

@synthesize resourceName = m_resourceName, animDur = m_animDur;

-(id)initWithProps:(AFBlockProps *)props rect:(CGRect)rect groupId:(GroupId)groupId resourceName:(NSString *)resourceName animDur:(float)animDur
{
    if( self = [super initWithProps:props rect:rect groupId:groupId] )
    {
        self.resourceName = resourceName;
        self.animDur = animDur;
    }
    return self;
}


-(void)dealloc
{
    self.resourceName = nil;
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super initWithCoder:decoder] )
    {
        self.resourceName = [decoder decodeObjectForKey:@"resourceName"];
        self.animDur = [((NSNumber *)[decoder decodeObjectForKey:@"animDur"]) floatValue];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.resourceName forKey:@"resourceName"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.animDur] forKey:@"animDur"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFAutoVariationMap
@implementation AFAutoVariationMap
@synthesize size = m_size;

-(id)initWithSize:(CGSize)size
{
    if( self = [super init] )
    {
        m_size = size;
        size_t len = ceilf( m_size.width ) * ceilf( m_size.height ) * sizeof( UInt32 );
        m_data = [[NSMutableData dataWithLength:len] retain];
    }
    return self;
}

-(void)dealloc
{
    [m_data release]; m_data = nil;
    [super dealloc];
}

-(UInt32)getHintAtX:(int)x y:(int)y
{
    size_t offset = (y * m_size.width + x) * sizeof( UInt32 );
    UInt32 *hintPtr = (UInt32 *)([m_data bytes] + offset);
    return *hintPtr;
}


-(void)setHintAtX:(int)x y:(int)y to:(UInt32)hint
{
    size_t offset = (y * m_size.width + x) * sizeof( UInt32 );
    UInt32 *hintPtr = (UInt32 *)([m_data bytes] + offset);
    *hintPtr = hint;
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        CGFloat width, height;
        width = [[decoder decodeObjectForKey:@"sw"] floatValue];
        height = [[decoder decodeObjectForKey:@"sh"] floatValue];
        m_size = CGSizeMake( width, height );
        m_data = [[decoder decodeObjectForKey:@"data"] retain];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithFloat:m_size.width] forKey:@"sw"];
    [encoder encodeObject:[NSNumber numberWithFloat:m_size.height] forKey:@"sh"];
    [encoder encodeObject:m_data forKey:@"data"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFPresetBlockBase

@implementation AFPresetBlockBase

@synthesize preset = m_preset, rect = m_rect, token = m_token, groupId = m_groupId, autoVariationMap = m_autoVariationMap;

-(id)initWithPreset:(EBlockPreset)preset rect:(CGRect)rect groupId:(GroupId)groupId autoVariationMap:(AFAutoVariationMap *)avMap
{
    if( self = [super init] )
    {
        self.preset = preset;
        self.rect = rect;
        self.groupId = groupId;
        self.autoVariationMap = avMap;
    }
    return self;    
}


-(void)dealloc
{
    self.autoVariationMap = nil;
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        self.preset = (EBlockPreset)[((NSNumber *)[decoder decodeObjectForKey:@"preset"]) intValue];

        // TODO: I'm gonna feel dumb if CGRect is decodeable directly.
        float x = [((NSNumber *)[decoder decodeObjectForKey:@"rx"]) floatValue];
        float y = [((NSNumber *)[decoder decodeObjectForKey:@"ry"]) floatValue];
        float w = [((NSNumber *)[decoder decodeObjectForKey:@"rw"]) floatValue];
        float h = [((NSNumber *)[decoder decodeObjectForKey:@"rh"]) floatValue];
        self.rect = CGRectMake( x, y, w, h );

        self.token = [((NSNumber *)[decoder decodeObjectForKey:@"token"]) unsignedIntValue];

        NSNumber *pVal = (NSNumber *)[decoder decodeObjectForKey:@"groupId"];
        if( pVal != nil )
        {
            self.groupId = (GroupId)[pVal intValue];
        }
        else
        {
            self.groupId = GROUPID_NONE;
        }
        
        self.autoVariationMap = [decoder decodeObjectForKey:@"avMap"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[NSNumber numberWithInt:(int)self.preset]        forKey:@"preset"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.origin.x]    forKey:@"rx"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.origin.y]    forKey:@"ry"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.size.width]  forKey:@"rw"];
    [encoder encodeObject:[NSNumber numberWithFloat:self.rect.size.height] forKey:@"rh"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:self.token]      forKey:@"token"];
    [encoder encodeObject:[NSNumber numberWithInt:self.groupId]            forKey:@"groupId"];
    [encoder encodeObject:self.autoVariationMap                            forKey:@"avMap"];
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFLevelProps

@implementation AFLevelProps

@synthesize name = m_name, description = m_description;

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(void)dealloc
{
    self.name = nil;
    self.description = nil;
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        self.name =        [decoder decodeObjectForKey:@"name"];
        self.description = [decoder decodeObjectForKey:@"description"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name        forKey:@"name"];
    [encoder encodeObject:self.description forKey:@"description"];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFLevel

@implementation AFLevel

@synthesize props = m_props, blockList = m_blockList;

-(id)initWithProps:(AFLevelProps *)props blockList:(NSArray *)blockList
{
    if( self = [super init] )
    {
        self.props = props;
        self.blockList = blockList;
    }
    return self;
}


-(void)dealloc
{
    self.props = nil;
    self.blockList = nil;
    [super dealloc];
}


-(id)initWithCoder:(NSCoder *)decoder
{
    if( self = [super init] )
    {
        self.props = [decoder decodeObjectForKey:@"props"];
        self.blockList = [decoder decodeObjectForKey:@"blockList"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.props                                              forKey:@"props"];
    [encoder encodeObject:self.blockList                                          forKey:@"blockList"];
}

@end

