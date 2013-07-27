//
//  IElbowRoom.h
//  JumpProto
//
//  Created by Gideon iOS on 7/26/13.
//
//

#import <Foundation/Foundation.h>
#import "ERDirection.h"
#import "Block.h"

@protocol IElbowRoom <NSObject>

-(void)addBlock:(Block *)block;
-(void)removeBlock:(Block *)block;
-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset;
-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir outCollidingEdgeList:(NSArray **)outCollidingEdgeList;
-(void)reset;

@end
