//
//  BlockGroup.m
//  JumpProto
//
//  Created by Gideon Goodwin on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockGroup.h"

@implementation BlockGroup

@synthesize blocks = m_blocks, groupId;

-(id)initWithGroupId:(GroupId)groupIdIn
{
    if( self = [super init] )
    {
        self.groupId = groupIdIn;
        self.blocks = [NSMutableArray arrayWithCapacity:10];
        
        m_groupProps = [[BlockProps alloc] init];
        m_groupV = EmuPointMake( 0, 0 );
        
        m_key = [[NSString stringWithFormat:@"g%u", (unsigned int)self.groupId ] retain];

    }
    return self;
}


-(void)dealloc
{
    [m_key release]; m_key = nil;
    self.blocks = nil;
    [m_groupProps release]; m_groupProps = nil;
    [super dealloc];
}


-(void)addBlock:(Block *)block
{
    [m_blocks addObject:block];
    block.groupId = self.groupId;
    block.owningGroup = self;  // weak
    
    if( [m_blocks count] == 1 )
    {
        [m_groupProps copyFrom:block.props];
    }
    else
    {
        if( ![m_groupProps equalTo:block.props] )
        {
            NSLog( @"BlockGroup addBlock: ignoring heterogeneous props." );
        }
    }
}


-(BOOL)isGroup
{
    return YES;
}


-(BOOL)isGroupElement
{
    return NO;
}


-(BlockProps *)getProps
{
    return m_groupProps;
}


-(EmuPoint)getV
{
    return m_groupV;
}


-(void)setV:(EmuPoint)v
{
    m_groupV = v;
}


-(EmuPoint)getMotive
{
    // groups don't have motive (currently)
    // TODO: not strictly true if you allow free-form grouping in the editor
    //       (can group platforms, etc)
    return EmuPointMake( 0, 0 );
}


-(EmuPoint)getMotiveAccel
{
    return EmuPointMake( 0, 0 );
}


-(NSString *)getKey
{
    return m_key;
}


-(void)bouncedOnXAxis:(BOOL)xAxis
{
    // err..do groups have vIntrinsic?
    //NSLog( @"group bounce NYI...come on, this won't be that hard." );
}


-(BOOL)collidedInto:(NSObject<ISolidObject> *)node inDir:(ERDirection)dir props:(BlockProps *)props
{
    // no default action for group collisions.
    return NO;
}


-(void)changePositionOnXAxis:(BOOL)onXAxis signedMoveOffset:(Emu)didMoveOffset elbowRoom:(id)elbowRoomIn
{
    for( int i = 0; i < [m_blocks count]; ++i )
    {
        Block *block = (Block *)[m_blocks objectAtIndex:i];
        [block changePositionOnXAxis:onXAxis signedMoveOffset:didMoveOffset elbowRoom:elbowRoomIn];
    }
}

@end
