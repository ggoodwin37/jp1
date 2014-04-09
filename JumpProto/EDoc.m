//
//  EDoc.m
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EDoc.h"
#import "constants.h"
#import "EArchiveUtil.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridPoint
@implementation EGridPoint

@synthesize xGrid = m_xGrid, yGrid = m_yGrid, key = m_key;

-(id)initAtXGrid:(NSUInteger)xGrid yGrid:(NSUInteger)yGrid
{
    if( self = [super init] )
    {
        m_xGrid = xGrid;
        m_yGrid = yGrid;
        
        NSAssert( (m_xGrid & 0x0000ffff) == m_xGrid, @"EGridPoint overflow" );
        NSUInteger hash = ((m_xGrid & 0x0000ffff) << 16) | m_yGrid;

        m_key = [[NSString stringWithFormat:@"%lu", (unsigned long)hash] retain];
        
    }
    return self;
}


-(void)dealloc
{
    [m_key release]; m_key = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridBlockMarkerProps
@implementation EGridBlockMarkerProps

@synthesize groupId;

-(id)init
{
    if( self = [super init] )
    {
        // defaults
        self.groupId = GROUPID_NONE;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridBlockMarker
@implementation EGridBlockMarker

@synthesize gridLocation, preset, gridSize, props, shadowParent;

-(id)init
{
    if( self = [super init] )
    {
        self.props = [[EGridBlockMarkerProps alloc] init];
        self.shadowParent = nil;
    }
    return self;
}


-(void)dealloc
{
    self.shadowParent = nil;
    self.props = nil;
    [super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridDocument
@implementation EGridDocument

@synthesize levelName, levelDescription;

-(id)init
{
    if( self = [super init] )
    {
        m_gridMap = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
        self.levelName = nil;
        self.levelDescription = nil;
    }
    return self;
}


-(void)dealloc
{
    self.levelName = nil;
    self.levelDescription = nil;
    [m_gridMap release]; m_gridMap = nil;
    [super dealloc];
}


-(void)removeParentAndAllShadowsAtLocation:(EGridPoint *)location
{
    EGridBlockMarker *targetMarker = (EGridBlockMarker *)[m_gridMap valueForKey:location.key];
    if( targetMarker.shadowParent != nil )
    {
        targetMarker = targetMarker.shadowParent;
    }
    EGridPoint *parentLocation = [[[EGridPoint alloc] initAtXGrid:targetMarker.gridLocation.xGrid yGrid:targetMarker.gridLocation.yGrid] autorelease];
    NSAssert( targetMarker != nil, @"remove parent fail" );
    NSAssert( targetMarker.shadowParent == nil, @"expected shadowParent, not shadow" );
    int w = (int)targetMarker.gridSize.xGrid;
    int h = (int)targetMarker.gridSize.yGrid;
    for( int j = 0; j < h; ++j )
    {
        for( int i = 0; i < w; ++i )
        {
            EGridPoint *thisLocation = [[[EGridPoint alloc] initAtXGrid:(parentLocation.xGrid + i) yGrid:(parentLocation.yGrid + j)] autorelease];
            [m_gridMap removeObjectForKey:thisLocation.key];
        }
    }
}


-(void)addParentAndShadowsForMarker:(EGridBlockMarker *)targetMarker atLocation:(EGridPoint *)location
{
    NSAssert( targetMarker.shadowParent == nil, @"expected shadowParent, not shadow" );
    for( int j = 0; j < targetMarker.gridSize.yGrid; ++j )
    {
        for( int i = 0; i < targetMarker.gridSize.xGrid; ++i )
        {
            EGridBlockMarker *thisMarker;
            EGridPoint *thisLocation = [[[EGridPoint alloc] initAtXGrid:(location.xGrid + i) yGrid:(location.yGrid + j)] autorelease];
            if( i == 0 && j == 0 )
            {
                // add parent block
                thisMarker = targetMarker;
            }
            else
            {
                // add shadow block
                thisMarker = [[[EGridBlockMarker alloc] init] autorelease];
                thisMarker.shadowParent = targetMarker;
            }
            
            // remove any blocks that we might overlap (even when placing shadows).
            if( [m_gridMap valueForKey:thisLocation.key] != nil )
            {
                [self removeParentAndAllShadowsAtLocation:thisLocation];
            }
            
            // set block.
            [m_gridMap setValue:thisMarker forKey:thisLocation.key];
        }
    }
}


// returns YES if state changed.
-(BOOL)setPreset:(EBlockPreset)preset atXGrid:(NSUInteger)xGrid yGrid:(NSUInteger)yGrid w:(NSUInteger)wGrid h:(NSUInteger)hGrid groupId:(GroupId)groupId
{
    EGridPoint *location = [[[EGridPoint alloc] initAtXGrid:xGrid yGrid:yGrid] autorelease];

    // handle erase
    if( preset == EBlockPreset_None )
    {
        if( [m_gridMap valueForKey:location.key] != nil )
        {
            [self removeParentAndAllShadowsAtLocation:location];
        }
        return YES;
    }

    EGridBlockMarker *marker = [[[EGridBlockMarker alloc] init] autorelease];
    marker.gridLocation = location;
    marker.gridSize = [[[EGridPoint alloc] initAtXGrid:wGrid yGrid:hGrid] autorelease];
    marker.preset = preset;
    marker.props.groupId = groupId;
    
    [self addParentAndShadowsForMarker:marker atLocation:location];
    return YES;
}


-(EGridBlockMarker *)getMarkerAtXGrid:(UInt32)xGrid yGrid:(UInt32)yGrid
{
    // TODO: this won't hit with non-1x1 blocks (other than the origin point).
    
    EGridPoint *location = [[[EGridPoint alloc] initAtXGrid:xGrid yGrid:yGrid] autorelease];   
    EGridBlockMarker *marker = (EGridBlockMarker *)[m_gridMap objectForKey:location.key];
    return marker;
}


-(EGridBlockMarker *)getMarkerAt:(CGPoint)p
{
    NSAssert( p.x >= 0.f && p.y >= 0.f, @"EGridDocument getMarkerAt: negative coords not allowed." );
    
    UInt32 xGrid = (UInt32)floorf( p.x / ONE_BLOCK_SIZE_Fl );
    UInt32 yGrid = (UInt32)floorf( p.y / ONE_BLOCK_SIZE_Fl );
    
    return [self getMarkerAtXGrid:xGrid yGrid:yGrid];
}


-(NSArray *)getValues
{
    return [m_gridMap allValues];
}


@end
