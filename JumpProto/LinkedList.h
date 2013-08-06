//
//  LinkedList.h
//  JumpProto
//
//  Created by Gideon iOS on 8/6/13.
//
//

#import <Foundation/Foundation.h>

// ------------------------
@interface LLNode : NSObject

@property (nonatomic, retain) LLNode *next;
@property (nonatomic, retain) id data;

@end


// ------------------------
@interface LinkedList : NSObject {
    LLNode *m_ptr;
    LLNode *m_head;
}

-(void)enqueueData:(id)data;

-(void)reset;
-(id)next;
@end
