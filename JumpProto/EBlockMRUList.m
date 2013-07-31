//
//  EBlockMRUList.m
//  JumpProto
//
//  Created by Gideon iOS on 5/30/13.
//
//

#import "EBlockMRUList.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockMRUEntry
@implementation EBlockMRUEntry
@synthesize preset = m_preset;

-(id)initWithPreset:(EBlockPreset)preset
{
    if( self = [super init] )
    {
        m_preset = preset;
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(BOOL)isSameAs:(EBlockMRUEntry *)other
{
    return self.preset == other.preset;
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockMRUList
@implementation EBlockMRUList : NSObject

-(id)initWithMaxSize:(int)maxSize
{
    if( self = [super init] )
    {
        m_maxSize = maxSize;
        m_stack = [[NSMutableArray arrayWithCapacity:(m_maxSize * 2)] retain];
    }
    return self;
}


-(void)dealloc
{
    [m_stack release]; m_stack = nil;
    [super dealloc];
}


-(void)pushEntry:(EBlockMRUEntry *)entry
{
    // insert new entry at head
    [m_stack insertObject:entry atIndex:0];
    
    // if any matching entries are in the stack already, remove them.
    for( int i = 1; i < [m_stack count]; ++i )
    {
        EBlockMRUEntry *testEntry = (EBlockMRUEntry *)[m_stack objectAtIndex:i];
        if( [entry isSameAs:testEntry] )
        {
            [m_stack removeObjectAtIndex:i];
            break;
        }
    }
    
    // enforce max size.
    while( [m_stack count] > m_maxSize )
    {
        [m_stack removeObjectAtIndex:([m_stack count] - 1)];
    }
}


-(EBlockMRUEntry *)getEntryAtOffset:(int)offset
{
    NSAssert( offset >= 0 && offset < [self getCurrentSize], @"Don't be a dick." );
    return [m_stack objectAtIndex:offset];
}


-(int)getCurrentSize
{
    return [m_stack count];
}

@end
