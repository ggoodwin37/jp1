//
//  ElbowRoomGrid.m
//  JumpProto
//
//  Created by Gideon iOS on 7/27/13.
//
//

#import "ElbowRoomGrid.h"

@implementation ElbowRoomGrid

-(id)init
{
    if( self = [super init] )
    {
        m_gridCellSize = ONE_BLOCK_SIZE_Emu * 2;   // class const.
        m_gridCells = nil;
        
        m_workingStack = [[NSMutableArray arrayWithCapacity:4] retain];
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


-(NSMutableArray *)ensureGridCellAtCol:(int)x Row:(int)y
{
    int offset = y * m_gridCellStride + x;
    NSMutableArray *result = m_gridCells[offset];
    if( result == nil )
    {
        result = m_gridCells[offset] = [[NSMutableArray arrayWithCapacity:4] retain];   // TODO: capacity makes sense?
        
    }
    return result;
}


-(void)addBlock:(Block *)block
{
    // TODO: groups?
    int blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    NSLog( @"adding block on range %d, %d -> %d, %d", blockCol0, blockRow0, blockCol1, blockRow1 );
    for( int ij = blockRow0; ij <= blockRow1; ++ij )
    {
        for( int ii = blockCol0; ii <= blockCol1; ++ii )
        {
            [[self ensureGridCellAtCol:ii Row:ij] addObject:block];  // O(1)
        }
    }
}


-(void)removeBlock:(Block *)block
{
    // TODO: groups?
    // TODO: figure out how to pass param'd selectors in obj-c so I can reuse the calc/iteration code.
    int blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
    int blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
    int blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
    int blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    for( int ij = blockRow0; ij <= blockRow1; ++ij )
    {
        for( int ii = blockCol0; ii <= blockCol1; ++ii )
        {
            [[self ensureGridCellAtCol:ii Row:ij] removeObject:block];  // O(n)
        }
    }
}


-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset
{
    // TODO: groups?

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
            if( ii < oldBlockRow0 ||
                ii > oldBlockRow1 ||
                ij < oldBlockCol0 ||
                ij > oldBlockCol1 )
            {
                [[self ensureGridCellAtCol:ii Row:ij] addObject:block];  // O(1)
            }
            if( ii < newBlockRow0 ||
                ii > newBlockRow1 ||
                ij < newBlockCol0 ||
                ij > newBlockCol1 )
            {
                [[self ensureGridCellAtCol:ii Row:ij] removeObject:block];  // O(n)
            }
        }
    }
}


-(Emu)getElbowRoomInCellForBlock:(Block *)block col:(int)col row:(int)row dir:(ERDirection)dir previousMinDistance:(Emu)prevMin
{
    NSArray *list = [self ensureGridCellAtCol:col Row:row];
    Emu minDistance = prevMin;
    Emu thisDistance;
    for( int i = 0; i < [list count]; ++i )
    {
        Block *thisBlock = (Block *)[list objectAtIndex:i];
        if( dir == ERDirDown )
        {
            if( thisBlock.x + thisBlock.w < block.x ) continue;
            if( thisBlock.x > block.x + block.w ) continue;
            if( thisBlock.y + thisBlock.h > block.y ) continue;
            thisDistance = block.y - (thisBlock.y + thisBlock.h);
        }
        else if( dir == ERDirUp )
        {
            if( thisBlock.x + thisBlock.w < block.x ) continue;
            if( thisBlock.x > block.x + block.w ) continue;
            if( thisBlock.y < block.y + block.h ) continue;
            thisDistance = thisBlock.y - (block.y + block.h);
        }
        else if( dir == ERDirLeft )
        {
            if( thisBlock.y + thisBlock.h < block.y ) continue;
            if( thisBlock.y > block.y + block.h ) continue;
            if( thisBlock.x + thisBlock.w > block.x ) continue;
            thisDistance = block.x - (thisBlock.x + thisBlock.w);
        }
        else // if( dir == ERDirRight )
        {
            if( thisBlock.y + thisBlock.h < block.y ) continue;
            if( thisBlock.y > block.y + block.h ) continue;
            if( thisBlock.x < block.x + block.w ) continue;
            thisDistance = thisBlock.x - (block.x + block.w);
        }
        
        if( thisDistance < minDistance )
        {
            // this candidate is the best so far, reset stack and save.
            [m_workingStack removeAllObjects];
            [m_workingStack addObject:thisBlock];
            minDistance = thisDistance;
        }
        else if( thisDistance == minDistance )
        {
            // this candidate is same as known best, save it with others.
            [m_workingStack addObject:thisBlock];
        }
        // else do nothing for this candidate since it's further than min.
    }
    return minDistance;
}


-(Emu)getElbowRoomForBlock:(Block *)block inDirection:(ERDirection)dir
{
    int colInc, rowInc, blockCol0, blockCol1, blockRow0, blockRow1;
    if( dir == ERDirDown )
    {
        colInc = 1;
        rowInc = -1;
        blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
        blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
        blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
        blockRow1 = blockRow0 + rowInc;
    }
    else if( dir == ERDirUp )
    {
        colInc = 1;
        rowInc = 1;
        blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
        blockCol1 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
        blockRow0 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
        blockRow1 = blockRow0 + rowInc;
    }
    if( dir == ERDirLeft )
    {
        colInc = -1;
        rowInc = 1;
        blockCol0 = (block.x - m_worldMin.x) / m_gridCellSize;
        blockCol1 = blockCol0 + colInc;
        blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
        blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    }
    else // if( dir == ERDirRight )
    {
        colInc = 1;
        rowInc = 1;
        blockCol0 = (block.x + block.w - m_worldMin.x) / m_gridCellSize;
        blockCol1 = blockCol0 + colInc;
        blockRow0 = (block.y - m_worldMin.y) / m_gridCellSize;
        blockRow1 = (block.y + block.h - m_worldMin.y) / m_gridCellSize;
    }
    
    Emu minDistance = m_gridCellSize;
    for( int ii = blockCol0; ii <= blockCol1; ii += colInc )
    {
        for( int ij = blockRow0; ij <= blockRow1; ij += rowInc )
        {
            minDistance = [self getElbowRoomInCellForBlock:block col:ii row:ij dir:dir previousMinDistance:minDistance];
        }
        if( minDistance <= m_gridCellSize ) return minDistance;  // don't bother checking next
    }
    return minDistance;  // == m_gridCellSize
}


-(Emu)getElbowRoomForGroup:(BlockGroup *)blockGroup inDirection:(ERDirection)dir
{
    return 0;
}


-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir
{
    // TODO: groups?
    NSAssert( ![solidObject isGroup], @"Group NYI" );
    [m_workingStack removeAllObjects];
    return [self getElbowRoomForBlock:(Block *)solidObject inDirection:dir];
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

@end
