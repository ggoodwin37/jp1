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
    [self releaseGridCells];
    [super dealloc];
}


// x and y are grid column and row space.
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
}


-(void)removeBlock:(Block *)block
{
    
}


-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset
{
    
}


-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList
{
    return 0;
}


// TODO: if you keep this implementation, remove this from the interface.
-(void)reset
{
    NSAssert( NO, @"Call the version with min/max points." );
}


-(void)resetWithWorldMin:(EmuPoint)minPoint worldMax:(EmuPoint)maxPoint
{
    [self releaseGridCells];
    m_worldMin = minPoint;
    m_worldMax = maxPoint;
    
    // TODO: consider padding, should padding be explicitly added by caller, or implicit here?
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
}


@end
