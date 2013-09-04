//
//  PropagateMovementUpdater.h
//  JumpProto
//
//  Created by Gideon iOS on 7/27/13.
//
//

#import <Foundation/Foundation.h>

#import "BlockUpdater.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// PropagateMovementUpdater

// propagates movement due to velocity along all abutting blocks.
@interface PropagateMovementUpdater : ERFrameCacheBlockUpdater {
    NSMutableArray *m_groupPropStack;  // scratch array used to prevent group propagation loops.
    BlockProps *m_propsAccumulator;
}

@end
