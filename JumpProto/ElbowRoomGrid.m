//
//  ElbowRoomGrid.m
//  JumpProto
//
//  Created by Gideon iOS on 7/27/13.
//
//

#import "ElbowRoomGrid.h"
#import "BlockGroup.h"

@implementation ElbowRoomGrid

-(id)initWithRedBluProvider:(NSObject<IRedBluStateProvider> *)redBluProvider
{
    if( self = [super init] )
    {
        m_gridCellSize = ONE_BLOCK_SIZE_Emu * 2;   // class const.
        m_gridCells = nil;
        
        m_workingStack = [[NSMutableArray arrayWithCapacity:4] retain];
        m_overlapperStack = [[NSMutableArray arrayWithCapacity:4] retain];
        m_redBluProvider = redBluProvider;  // weak
    }
    return self;
}


-(void)releaseGridCells
{
    for( int i = 0; i < m_numGridCells; ++i )
    {
        [m_gridCells[i] release];
        m_gridCells[i] = nil;
    }
    free( m_gridCells );
    m_gridCells = nil;
}


-(void)dealloc
{
    m_redBluProvider = nil;  // weak
    [m_overlapperStack release]; m_overlapperStack = nil;
    [m_workingStack release]; m_workingStack = nil;
    [self releaseGridCells];
    [super dealloc];
}


-(void)resetWithWorldMin:(EmuPoint)minPoint worldMax:(EmuPoint)maxPoint
{
    [self releaseGridCells];
    m_worldMin = minPoint;
    m_worldMax = maxPoint;
    
    Emu worldWidth = maxPoint.x - minPoint.x;
    Emu worldHeight = maxPoint.y - minPoint.y;
    
    int gridCol = (int)ceilf(worldWidth / m_gridCellSize);
    int gridRow = (int)ceilf(worldHeight / m_gridCellSize);
    m_numGridCells = gridCol * gridRow;
    m_gridCells = (NSMutableArray **)malloc(m_numGridCells * sizeof(NSMutableArray *));
    NSAssert( m_gridCells, @"Assume we have enough memory for ElbowRoomGrid cell list" );
    for( int i = 0; i < m_numGridCells; ++i )
    {
        m_gridCells[i] = nil;
    }
    m_gridCellStride = gridCol;
    
    NSLog( @"reset ERGrid. cellSize is %d, worldSize is %d, %d -> %d, %d. grid is %d, %d, total %d cells.",
          m_gridCellSize, minPoint.x, minPoint.y, maxPoint.x, maxPoint.y, gridCol, gridRow, m_numGridCells );
}


-(void)reset
{
    Emu defaultMin = -10 * ONE_BLOCK_SIZE_Emu;
    Emu defaultMax = 100 * ONE_BLOCK_SIZE_Emu;
    [self resetWithWorldMin:EmuPointMake( defaultMin, defaultMin ) worldMax:EmuPointMake( defaultMax, defaultMax )];
}


-(Emu)getMaxDistance
{
    return m_gridCellSize;
}


-(NSMutableArray *)ensureGridCellAtCol:(int)x row:(int)y
{
    int offset = y * m_gridCellStride + x;
    if( offset < 0 || offset >= m_numGridCells )
    {
        // degrade gracefully. if a block wants to move off grid, it can, we just
        //  won't track it in elbowRoom. world is responsible for killing stuff.
        return nil;
    }
    NSMutableArray *result = m_gridCells[offset];
    if( result == nil )
    {
        result = m_gridCells[offset] = [[NSMutableArray arrayWithCapacity:4] retain];   // TODO: capacity makes sense?
    }
    return result;
}


-(NSMutableArray *)tryGetGridCellAtCol:(int)x row:(int)y
{
    int offset = y * m_gridCellStride + x;
    if( offset < 0 || offset >= m_numGridCells )
    {
        return nil;
    }
    return m_gridCells[offset];  // may be nil
}


-(void)addBlock:(Block *)block
{
    int blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    for( int ij = blockRow0; ij <= blockRow1; ++ij )
    {
        for( int ii = blockCol0; ii <= blockCol1; ++ii )
        {
            [[self ensureGridCellAtCol:ii row:ij] addObject:block];  // O(1)
        }
    }
}


-(void)removeBlock:(Block *)block
{
    // TODO: figure out how to pass param'd selectors in obj-c so I can reuse the calc/iteration code.
    int blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    for( int ij = blockRow0; ij <= blockRow1; ++ij )
    {
        for( int ii = blockCol0; ii <= blockCol1; ++ii )
        {
            [[self tryGetGridCellAtCol:ii row:ij] removeObject:block];  // O(n)
        }
    }
}


-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset
{
    int oldBlockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int oldBlockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int oldBlockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int oldBlockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;

    // actually commit the new coordinates to block. we do this on block's behalf
    //  so that we have a chance to see both old and new coords for state update.
    EmuRect targetRect = EmuRectMake( block.x + offset.x, block.y + offset.y, block.w, block.h );
    [block.state setRect:targetRect];
    
    int newBlockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int newBlockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int newBlockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int newBlockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    
    // only update cells that were newly added or removed.
    int minRow = MIN(oldBlockRow0, newBlockRow0);
    int maxRow = MAX(oldBlockRow1, newBlockRow1);
    int minCol = MIN(oldBlockCol0, newBlockCol0);
    int maxCol = MAX(oldBlockCol1, newBlockCol1);
    for( int ij = minRow; ij <= maxRow; ++ij )
    {
        for( int ii = minCol; ii <= maxCol; ++ii )
        {
            if( ii < oldBlockCol0 ||
                ii > oldBlockCol1 ||
                ij < oldBlockRow0 ||
                ij > oldBlockRow1 )
            {
                [[self ensureGridCellAtCol:ii row:ij] addObject:block];  // O(1)
            }
            if( ii < newBlockCol0 ||
                ii > newBlockCol1 ||
                ij < newBlockRow0 ||
                ij > newBlockRow1 )
            {
                [[self tryGetGridCellAtCol:ii row:ij] removeObject:block];  // O(n)
            }
        }
    }
}


+(void)addIfUniqueToStack:(NSMutableArray *)resultStack block:(Block *)block
{
    for( int i = 0; i < [resultStack count]; ++i )
    {
        Block *thisBlock = (Block *)[resultStack objectAtIndex:i];
        if( thisBlock == block ) return;
    }
    [resultStack addObject:block];
}


-(Emu)getElbowRoomInCellForBlock:(Block *)block col:(int)col row:(int)row dir:(ERDirection)dir previousMinDistance:(Emu)prevMin resultStack:(NSMutableArray *)resultStack
{
    NSArray *list = [self tryGetGridCellAtCol:col row:row];  // could be nil
    Emu minDistance = prevMin;
    Emu thisDistance;
    for( int i = 0; i < [list count]; ++i )
    {
        Block *candidateBlock = (Block *)[list objectAtIndex:i];

        if( candidateBlock == block ) continue;  // can't collide with self.
        if( block.groupId != GROUPID_NONE && block.groupId == candidateBlock.groupId ) continue;  // can't collide with own group.
        
        if( candidateBlock.props.isAiHint && !block.props.followsAiHints ) continue;

        // only ask for current state if we are dealing with a red-blu.
        //  this saves us lots of calls since the typical case is a non-red-blu.
        //  but if we happen to have lots of red-blus, it would be nice to have
        //  this cached.
        if( candidateBlock.props.redBluState != BlockRedBlueState_None )
        {
            if( [m_redBluProvider isCurrentlyRed] )
            {
                if( candidateBlock.props.redBluState != BlockRedBlueState_Red ) continue;
            }
            else
            {
                if( candidateBlock.props.redBluState != BlockRedBlueState_Blu ) continue;
            }
        }

        if( dir == ERDirDown )
        {
            if( candidateBlock.x + candidateBlock.w <= block.x ) continue;
            if( candidateBlock.x >= block.x + block.w ) continue;
            if( candidateBlock.y + candidateBlock.h > block.y ) continue;
            if( block.props.eventSolidMask & BlockEdgeDirMask_Down )
            {
                if( !(candidateBlock.props.eventSolidMask & BlockEdgeDirMask_Up) ) continue;
            }
            else if( !(candidateBlock.props.solidMask & BlockEdgeDirMask_Up) ) continue;
            thisDistance = block.y - (candidateBlock.y + candidateBlock.h);
        }
        else if( dir == ERDirUp )
        {
            if( candidateBlock.x + candidateBlock.w <= block.x ) continue;
            if( candidateBlock.x >= block.x + block.w ) continue;
            if( candidateBlock.y < block.y + block.h ) continue;
            if( block.props.eventSolidMask & BlockEdgeDirMask_Up )
            {
                if( !(candidateBlock.props.eventSolidMask & BlockEdgeDirMask_Down) ) continue;
            }
            else if( !(candidateBlock.props.solidMask & BlockEdgeDirMask_Down) ) continue;
            thisDistance = candidateBlock.y - (block.y + block.h);
        }
        else if( dir == ERDirLeft )
        {
            if( candidateBlock.y + candidateBlock.h <= block.y ) continue;
            if( candidateBlock.y >= block.y + block.h ) continue;
            if( candidateBlock.x + candidateBlock.w > block.x ) continue;
            if( block.props.eventSolidMask & BlockEdgeDirMask_Left )
            {
                if( !(candidateBlock.props.eventSolidMask & BlockEdgeDirMask_Right) ) continue;
            }
            else if( !(candidateBlock.props.solidMask & BlockEdgeDirMask_Right) ) continue;
            thisDistance = block.x - (candidateBlock.x + candidateBlock.w);
        }
        else // if( dir == ERDirRight )
        {
            if( candidateBlock.y + candidateBlock.h <= block.y ) continue;
            if( candidateBlock.y >= block.y + block.h ) continue;
            if( candidateBlock.x < block.x + block.w ) continue;
            if( block.props.eventSolidMask & BlockEdgeDirMask_Right )
            {
                if( !(candidateBlock.props.eventSolidMask & BlockEdgeDirMask_Left) ) continue;
            }
            else if( !(candidateBlock.props.solidMask & BlockEdgeDirMask_Left) ) continue;
            thisDistance = candidateBlock.x - (block.x + block.w);
        }
        
        if( thisDistance < minDistance )
        {
            // this candidate is the best so far, reset stack and save.
            [resultStack removeAllObjects];
            [resultStack addObject:candidateBlock];
            minDistance = thisDistance;
        }
        else if( thisDistance == minDistance )
        {
            // this candidate is same as known best, save it with others if it is unique.
            [ElbowRoomGrid addIfUniqueToStack:resultStack block:candidateBlock];
        }
        // else do nothing for this candidate since it's further than min.
    }
    return minDistance;
}


-(Emu)getElbowRoomForBlock:(Block *)block inDirection:(ERDirection)dir resultStack:(NSMutableArray *)resultStack
{
    int colInc, rowInc, blockCol0, blockCol1, blockRow0, blockRow1;
    if( dir == ERDirDown || dir == ERDirUp )
    {
        if( dir == ERDirDown )
        {
            rowInc = -1;
            blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
            blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
            blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
            blockRow1 = blockRow0 + rowInc;
        }
        else if( dir == ERDirUp )
        {
            rowInc = 1;
            blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
            blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
            blockRow0 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
            blockRow1 = blockRow0 + rowInc;
        }
        
        Emu minDistance = m_gridCellSize;
        // row major
        for( int ij = blockRow0; (rowInc > 0) ? (ij <= blockRow1) : (ij >= blockRow1); ij += rowInc )
        {
            for( int ii = blockCol0; ii <= blockCol1; ++ii )
            {
                minDistance = [self getElbowRoomInCellForBlock:block col:ii row:ij dir:dir previousMinDistance:minDistance resultStack:resultStack];
            }
            if( minDistance < m_gridCellSize ) return minDistance;  // don't bother checking next
        }
        return m_gridCellSize;
    }
    else
    {
        if( dir == ERDirLeft )
        {
            colInc = -1;
            blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
            blockCol1 = blockCol0 + colInc;
            blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
            blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
        }
        else // if( dir == ERDirRight )
        {
            colInc = 1;
            blockCol0 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
            blockCol1 = blockCol0 + colInc;
            blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
            blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
        }

        Emu minDistance = m_gridCellSize;
        // columnMajor
        for( int ii = blockCol0; (colInc > 0) ? (ii <= blockCol1) : (ii >= blockCol1); ii += colInc )
        {
            for( int ij = blockRow0; ij <= blockRow1; ++ij )
            {
                minDistance = [self getElbowRoomInCellForBlock:block col:ii row:ij dir:dir previousMinDistance:minDistance resultStack:resultStack];
            }
            if( minDistance < m_gridCellSize ) return minDistance;  // don't bother checking next
        }
        return m_gridCellSize;
    }
}


-(Emu)getElbowRoomForGroup:(BlockGroup *)blockGroup inDirection:(ERDirection)dir
{
    NSMutableArray *tempStack = [NSMutableArray arrayWithCapacity:4];

    Emu minDistance = m_gridCellSize;
    for( int i = 0; i < [blockGroup.blocks count]; ++i )
    {
        Block *thisBlock = (Block *)[blockGroup.blocks objectAtIndex:i];
        [tempStack removeAllObjects];
        Emu thisDistance = [self getElbowRoomForBlock:thisBlock inDirection:dir resultStack:tempStack];
        if( thisDistance < minDistance )
        {
            [m_workingStack removeAllObjects];
            [m_workingStack addObjectsFromArray:tempStack];
            minDistance = thisDistance;
        }
        else if( thisDistance == minDistance )
        {
            [m_workingStack addObjectsFromArray:tempStack];
        }
        // else do nothing with this block
    }
    return minDistance;
}


-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir
{
    [m_workingStack removeAllObjects];
    if( [solidObject isGroup] )
    {
        return [self getElbowRoomForGroup:(BlockGroup *)solidObject inDirection:dir];
    }
    else
    {
        return [self getElbowRoomForBlock:(Block *)solidObject inDirection:dir resultStack:m_workingStack];
    }
}


-(Block *)popCollider
{
    Block *result = nil;
    if( [m_workingStack count] > 0 )
    {
        result = [m_workingStack lastObject];
        [m_workingStack removeLastObject];
    }
    return result;
}


-(int)getOverlappersForWorldRect:(EmuPoint)worldRect
{
    // TODO
    return 0;
}


-(Block *)popOverlapper
{
    Block *result = nil;
    if( [m_overlapperStack count] > 0 )
    {
        result = [m_overlapperStack lastObject];
        [m_overlapperStack removeLastObject];
    }
    return result;
}


@end
