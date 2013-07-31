//
//  EBlockMRUList.h
//  JumpProto
//
//  Created by Gideon iOS on 5/30/13.
//
//

#import <Foundation/Foundation.h>
#import "EDoc.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockMRUEntry
@interface EBlockMRUEntry : NSObject
{
    EBlockPreset m_preset;
}

@property (nonatomic, readonly) EBlockPreset preset;

-(id)initWithPreset:(EBlockPreset)preset;
-(BOOL)isSameAs:(EBlockMRUEntry *)other;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockMRUList
@interface EBlockMRUList : NSObject
{
    int m_maxSize;
    NSMutableArray *m_stack;
}

-(id)initWithMaxSize:(int)maxSize;
-(void)pushEntry:(EBlockMRUEntry *)entry;
-(EBlockMRUEntry *)getEntryAtOffset:(int)offset;
-(int)getCurrentSize;

@end
