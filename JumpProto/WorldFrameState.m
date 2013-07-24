//
//  WorldFrameState.m
//  JumpProto
//
//  Created by Gideon Goodwin on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WorldFrameState.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldFrameCacheEntry

@implementation WorldFrameCacheEntry

@synthesize gravityTallyForFrameSoFar, gravityTallyOwningSO, newAbuttersThisFrame;

-(id)init
{
    if( self = [super init] )
    {
        m_abuttListUp    = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListLeft  = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListRight = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListDown  = [[NSMutableArray arrayWithCapacity:4] retain];
        
        self.gravityTallyForFrameSoFar = 0;
        self.gravityTallyOwningSO = nil;
        self.newAbuttersThisFrame = NO;
    }
    return self;
}


-(void)dealloc
{
    [m_abuttListDown release];  m_abuttListDown = nil;
    [m_abuttListRight release]; m_abuttListRight = nil;
    [m_abuttListLeft release];  m_abuttListLeft = nil;
    [m_abuttListUp release];    m_abuttListUp = nil;
    
    [super dealloc];
}


-(NSArray *)getAbuttListForDirection:(ERDirection)dir
{
    switch( dir )
    {
        case ERDirUp:    return m_abuttListUp;
        case ERDirLeft:  return m_abuttListLeft;
        case ERDirRight: return m_abuttListRight;
        case ERDirDown:  return m_abuttListDown;
        default: NSAssert( NO, @"dir fail" ); return nil;
    }
}


-(void)clearAbuttListForDirection:(ERDirection)dir
{
    switch( dir )
    {
        case ERDirUp:    [m_abuttListUp    removeAllObjects]; break;
        case ERDirLeft:  [m_abuttListLeft  removeAllObjects]; break;
        case ERDirRight: [m_abuttListRight removeAllObjects]; break;
        case ERDirDown:  [m_abuttListDown  removeAllObjects]; break;
        default: NSAssert( NO, @"dir fail" );                 break;
    }
}


-(void)copyAbuttingBlocksFromEdgeList:(NSArray *)edgeList forDirection:(ERDirection)dir
{
    NSMutableArray *targetArray;
    switch( dir )
    {
        case ERDirUp:    targetArray = m_abuttListUp;    break;
        case ERDirLeft:  targetArray = m_abuttListLeft;  break;
        case ERDirRight: targetArray = m_abuttListRight; break;
        case ERDirDown:  targetArray = m_abuttListDown;  break;
        default: NSAssert( NO, @"dir fail" );            break;
    }
    
    BOOL fDedupe = NO;  // only pay cost of deduping if we have an op that may add dupes.
    
    for( int i = 0; i < [edgeList count]; ++i )
    {
        EREdge *thisEdge = (EREdge *)[edgeList objectAtIndex:i];

        // if we are abutting a group element, also put a ref to the owning
        //  group in the list. This allows us to handle movement propagation
        //  for groups correctly.
        Block *thisBlock = thisEdge.block;
        if( [thisBlock isGroupElement] )
        {
            [targetArray addObject:thisBlock.owningGroup];  // may be dupe
            fDedupe = YES;
        }

        // add the abutting block, even if it was part of a group (which also got added).
        [targetArray addObject:thisBlock];
    }
    
    if( fDedupe )
    {
        NSSet *uniqueSet = [NSSet setWithArray:targetArray];
        [targetArray removeAllObjects];
        [targetArray addObjectsFromArray:[uniqueSet allObjects]];
    }
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldFrameCache

@implementation WorldFrameCache

-(id)init
{
    if( self = [super init] )
    {
        [self hardReset];
    }
    return self;
}


-(void)dealloc
{
    [m_SOToCacheEntryMap release]; m_SOToCacheEntryMap = nil;
    [super dealloc];
}


-(void)hardReset
{
    [m_SOToCacheEntryMap release]; m_SOToCacheEntryMap = nil;
    m_SOToCacheEntryMap = [[NSMutableDictionary dictionaryWithCapacity:64] retain];
}


-(WorldFrameCacheEntry *)ensureEntryForSO:(ASolidObject *)solidObject
{
    NSAssert( [solidObject getProps].canMoveFreely, @"shouldn't be creating frameCacheEntries for inert blocks" );
    
    NSString *keyStr = [solidObject getProps].tokenAsString;
    WorldFrameCacheEntry *entry = [m_SOToCacheEntryMap objectForKey:keyStr];
    if( entry == nil )
    {
        entry = [[WorldFrameCacheEntry alloc] init];
        
        [m_SOToCacheEntryMap setObject:entry forKey:keyStr];
    }
    
    return entry;
}


-(void)removeEntryForSO:(ASolidObject *)solidObject
{
    [m_SOToCacheEntryMap removeObjectForKey:solidObject];
}


-(void)resetForSO:(ASolidObject *)solidObject
{
    WorldFrameCacheEntry *thisEntry = (WorldFrameCacheEntry *)[m_SOToCacheEntryMap objectForKey:[solidObject getProps].tokenAsString];
    if( thisEntry == nil )
    {
        return;
    }
    
    // note: entry's abutt lists are actually cleared on demand when updating the lists. this is ok because
    //  we always update every list every frame, and we sometimes have to update mid-frame.
    
    thisEntry.gravityTallyForFrameSoFar = 0;
    thisEntry.gravityTallyOwningSO = nil;
    thisEntry.newAbuttersThisFrame = NO;
}

@end
