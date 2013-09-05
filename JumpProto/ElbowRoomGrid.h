//
//  ElbowRoomGrid.h
//  JumpProto
//
//  Created by Gideon iOS on 7/27/13.
//
//

#import <Foundation/Foundation.h>
#import "IElbowRoom.h"

@interface ElbowRoomGrid : NSObject<IElbowRoom> {
    int m_gridCellSize;       // how big in Emus is each grid cell square.
    EmuPoint m_worldMin;
    EmuPoint m_worldMax;
    int m_gridCellStride;
    int m_numGridCells;
    NSMutableArray **m_gridCells;    // each slot lazy holds an NSArray of grid inhabitants.
                                     // using a raw buffer here since NSArrays can't hold nil.
    
    NSMutableArray *m_workingStack;
    NSObject<IRedBluStateProvider> *m_redBluProvider;
}

@end
