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
@synthesize next, data;

-(id)init {
    if( self = [super init] ) {
        self.next = nil;
        self.data = nil;
    }
    return self;
}

-(void)dealloc {
    self.next = nil;
    self.data = nil;
    [super dealloc];
}

@end


// ------------------------
@implementation LinkedList

-(id)init
{
    if( self = [super init] )
    {
        m_ptr = nil;
        m_head = nil;
    }
    return self;
}


-(void)dealloc
{
    [m_ptr release]; m_ptr = nil;
    while( m_head )
    {
        LLNode *temp = m_head.next;
        m_head.next = nil;
        [m_head release];
        m_head = temp;
    }
    [super dealloc];
}


-(void)enqueueData:(id)data
{
    LLNode *newNode = [[[LLNode alloc] init] autorelease];
    newNode.data = data;
    if( m_head )
    {
        LLNode *temp = m_head;
        while( temp.next ) temp = temp.next;
        temp.next = newNode;
    }
    else
    {
        m_head = [newNode retain];
    }
}


-(void)reset
{
    m_ptr = m_head;
}


-(id)next
{
    if( !m_ptr ) return nil;
    id result = m_ptr.data;
    m_ptr = m_ptr.next;
    return result;
}

@end
