//
//  BlockGroup.h
//  JumpProto
//
//  Created by Gideon Goodwin on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Block.h"

// the purpose of a group is to replace one or more blocks and aggregate their physics and ER state, then
// update all as a unit. we need to have good caching for this to happen.


@interface BlockGroup : NSObject<ISolidObject>
{
    BlockProps *m_groupProps;
    EmuPoint m_groupV;
    NSString *m_key;
}

@property (nonatomic, retain) NSMutableArray *blocks;
@property (nonatomic, assign) GroupId groupId;

-(id)initWithGroupId:(GroupId)groupIdIn;
-(void)addBlock:(Block *)block;

@end
