//
//  WorldFrameState.m
//  JumpProto
//
//  Created by Gideon Goodwin on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WorldFrameState.h"
#import "BlockGroup.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// WorldFrameCacheEntry

@implementation WorldFrameCacheEntry

@synthesize gravityTallyForFrameSoFar, gravityTallyOwningSO, newAbuttersThisFrame, didBounceThisFrame;

-(id)init
{
    if( self = [super init] )
    {
        m_abuttListUp    = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListLeft  = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListRight = [[NSMutableArray arrayWithCapacity:4] retain];
        m_abuttListDown  = [[NSMutableArray arrayWithCapacity:4] retain];
        m_hasCachedAbuttListUp = NO;
        m_hasCachedAbuttListLeft = NO;
        m_hasCachedAbuttListRight = NO;
        m_hasCachedAbuttListDown = NO;
        
        self.gravityTallyForFrameSoFar = 0;
        self.gravityTallyOwningSO = nil;
        self.newAbuttersThisFrame = NO;
        self.didBounceThisFrame = NO;
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
        case ERDirUp:
            if( m_hasCachedAbuttListUp )
            {
                [m_abuttListUp removeAllObjects];
                m_hasCachedAbuttListUp = NO;
            }
            break;
        
        case ERDirLeft:
            if( m_hasCachedAbuttListLeft )
            {
                [m_abuttListLeft removeAllObjects];
                m_hasCachedAbuttListLeft = NO;
            }
            break;
        
        case ERDirRight:
            if( m_hasCachedAbuttListRight )
            {
                [m_abuttListRight removeAllObjects];
                m_hasCachedAbuttListRight = NO;
            }
            break;
        
        case ERDirDown:
            if( m_hasCachedAbuttListDown )
            {
                [m_abuttListDown removeAllObjects];
                m_hasCachedAbuttListDown = NO;
            }
            break;

        default:
            NSAssert( NO, @"dir fail" );
            break;
    }
}


// TODO: how often is copying really necessary? can we just consume off stack directly in most cases?
-(void)copyAbuttingBlocksFromElbowRoom:(NSObject<IElbowRoom> *)elbowRoom forDirection:(ERDirection)dir
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
    while( YES )
    {
        Block *thisBlock = [elbowRoom popCollider];
        if( thisBlock == nil )
        {
            break;
        }

        // if we are abutting a group element, also put a ref to the owning
        //  group in the list. This allows us to handle movement propagation
        //  for groups correctly.
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


-(void)removeAbuttersForGroup:(BlockGroup *)group forDirection:(ERDirection)dir
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
    
    for( int i = (int)[targetArray count] - 1; i >= 0; --i )
    {
        ASolidObject *thisSO = (ASolidObject *)targetArray[i];
        if( ![thisSO isGroup] )
        {
            Block *thisBlock = (Block *)thisSO;
            if( thisBlock.owningGroup == group )
            {
                [targetArray removeObjectAtIndex:i];
            }
        }
    }
}


-(void)markCacheAbuttListForDirection:(ERDirection)dir
{
    switch( dir )
    {
        case ERDirUp:    m_hasCachedAbuttListUp    = YES; break;
        case ERDirLeft:  m_hasCachedAbuttListLeft  = YES; break;
        case ERDirRight: m_hasCachedAbuttListRight = YES; break;
        case ERDirDown:  m_hasCachedAbuttListDown  = YES; break;
        default: NSAssert( NO, @"dir fail" );             break;
    }
}


-(BOOL)hasCachedAbuttListForDirection:(ERDirection)dir
{
    switch( dir )
    {
        case ERDirUp:    return m_hasCachedAbuttListUp;
        case ERDirLeft:  return m_hasCachedAbuttListLeft;
        case ERDirRight: return m_hasCachedAbuttListRight;
        case ERDirDown:  return m_hasCachedAbuttListDown;
        default: NSAssert( NO, @"dir fail" ); return NO;
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
    
    static const ERDirection dirList[] = { ERDirUp, ERDirLeft, ERDirRight, ERDirDown };
    const int dirListCount = 4;
    for( int i = 0; i < dirListCount; ++i )
    {
        [thisEntry clearAbuttListForDirection:dirList[i]];
    }
    
    thisEntry.gravityTallyForFrameSoFar = 0;
    thisEntry.gravityTallyOwningSO = nil;
    thisEntry.newAbuttersThisFrame = NO;
    thisEntry.didBounceThisFrame = NO;
}


-(void)updateOneAbuttListForSolidObject:(ASolidObject *)solidObject inER:(NSObject<IElbowRoom> *)er direction:(ERDirection)dir
{
    WorldFrameCacheEntry *cacheEntry = [self ensureEntryForSO:solidObject];
    
    Emu thisElbowRoom = [er getElbowRoomForSO:solidObject inDirection:dir];
    if( thisElbowRoom == 0 )
    {
        [cacheEntry copyAbuttingBlocksFromElbowRoom:er forDirection:dir];
    }
    
    // also register abutters for each element of a group. This is needed for group gap check (specifically the case where
    // the group may fall into a gap).
    // TODO: seems like this n^2 block could potentially get SLOW. need better algorithm.
    if( [solidObject isGroup] )
    {
        BlockGroup *thisGroup = (BlockGroup *)solidObject;
        for( int i = 0; i < [thisGroup.blocks count]; ++i )
        {
            Block *thisElement = (Block *)[thisGroup.blocks objectAtIndex:i];
            WorldFrameCacheEntry *thisElementCacheEntry = [self ensureEntryForSO:thisElement];
            [thisElementCacheEntry clearAbuttListForDirection:dir];
            thisElbowRoom = [er getElbowRoomForSO:thisElement inDirection:dir];
            if( thisElbowRoom == 0 )
            {
                [thisElementCacheEntry copyAbuttingBlocksFromElbowRoom:er forDirection:dir];
                [thisElementCacheEntry removeAbuttersForGroup:thisGroup forDirection:dir];
            }
        }  // for
    }  // if group
}


-(NSArray *)lazyGetAbuttListForSO:(ASolidObject *)solidObject inER:(NSObject<IElbowRoom> *)er direction:(ERDirection)dir
{
    NSAssert( [solidObject getProps].canMoveFreely, @"Only moving blocks need abutt lists." );
    WorldFrameCacheEntry *cacheEntry = [self ensureEntryForSO:solidObject];

    if( ![cacheEntry hasCachedAbuttListForDirection:dir] )
    {
        [self updateOneAbuttListForSolidObject:solidObject inER:er direction:dir];
        [cacheEntry markCacheAbuttListForDirection:dir];
    }
    return [cacheEntry getAbuttListForDirection:dir];
}


-(void)tryBounceNode:(ASolidObject *)node onXAxis:(BOOL)xAxis
{
    WorldFrameCacheEntry *cacheEntry = [self ensureEntryForSO:node];
    if( !cacheEntry.didBounceThisFrame )
    {
        [node bouncedOnXAxis:xAxis];
        cacheEntry.didBounceThisFrame = YES;
    }
}

@end
