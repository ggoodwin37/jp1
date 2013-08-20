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

// ownership starts with head and goes next. so next property is retain, but prev is assign (weak)
@property (nonatomic, retain) LLNode *next;
@property (nonatomic, assign) LLNode *prev;
@property (nonatomic, retain) id data;

@end


// ------------------------
@interface LinkedList : NSObject 

@property (nonatomic, readonly) LLNode *head;
@property (nonatomic, readonly) LLNode *tail;

-(void)enqueueData:(id)data;
-(LLNode *)nextOrWrap:(LLNode *)node;

@end
