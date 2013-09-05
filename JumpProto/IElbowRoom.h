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

-(id)initWithRedBluProvider:(NSObject<IRedBluStateProvider> *)redBluProvider;

-(void)resetWithWorldMin:(EmuPoint)minPoint worldMax:(EmuPoint)maxPoint;
-(void)reset;   // for compatibility with worldTest only, should remove this eventually.
-(Emu)getMaxDistance;
-(void)addBlock:(Block *)block;
-(void)removeBlock:(Block *)block;
-(void)moveBlock:(Block *)block byOffset:(EmuPoint)offset;
-(Emu)getElbowRoomForSO:(ASolidObject *)solidObject inDirection:(ERDirection)dir;
-(Block *)popCollider;  // returns next collider resulting from the most recent getElbowRoomForSO: call.

@end
