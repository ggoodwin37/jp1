//
//  LinkedList.m
//  JumpProto
//
//  Created by Gideon iOS on 8/6/13.
//
//

#import "LinkedList.h"


// ------------------------
@implementation LLNode
@synthesize next, prev, data;

-(id)init {
    if( self = [super init] ) {
        self.next = nil;
        self.prev = nil;
        self.data = nil;
    }
    return self;
}

-(void)dealloc {
    self.next = nil;
    self.prev = nil;
    self.data = nil;
    [super dealloc];
}

@end


// ------------------------
@implementation LinkedList

@synthesize head = m_head, tail = m_tail;

-(id)init
{
    if( self = [super init] )
    {
        m_head = nil;
        m_tail = nil;
    }
    return self;
}


-(void)dealloc
{
    while( m_tail )
    {
        m_tail = m_tail.prev;
        m_tail.next = nil;
    }
    m_head = nil;
    [super dealloc];
}


-(void)enqueueData:(id)data
{
    LLNode *newNode = [[[LLNode alloc] init] autorelease];
    newNode.data = data;
    if( m_head )
    {
        m_tail.next = [newNode retain];
        newNode.prev = m_tail;  // weak
    }
    else
    {
        m_head = [newNode retain];
    }
    m_tail = newNode;  // weak
}


-(LLNode *)nextOrWrap:(LLNode *)node
{
    return node.next ? node.next : m_head;
}

@end
