//
//  EDoc.h
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArchiveFormat.h"


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridPoint
@interface EGridPoint : NSObject {
    
}

@property (nonatomic, readonly) NSUInteger xGrid;
@property (nonatomic, readonly) NSUInteger yGrid;
@property (nonatomic, readonly) NSString *key;

-(id)initAtXGrid:(NSUInteger)xGrid yGrid:(NSUInteger)yGrid;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridBlockMarkerProps
@interface EGridBlockMarkerProps : NSObject {
    
}

@property (nonatomic, assign) GroupId groupId;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridBlockMarker
@interface EGridBlockMarker : NSObject {
    
}

@property (nonatomic, retain) EGridPoint *gridLocation;  // in grid units, so multiply by ONE_BLOCK_SIZE to get world units.
@property (nonatomic, retain) EGridPoint *gridSize;
@property (nonatomic, assign) EBlockPreset preset;
@property (nonatomic, retain) EGridBlockMarkerProps *props;
@property (nonatomic, assign) EGridBlockMarker *shadowParent; // weak, points to "shadow owner" of this block if non-nil.

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// EGridDocument
// this is a simplified document that the WorldView can edit. Blocks are stored in a map by location.
@interface EGridDocument : NSObject {
    
    NSMutableDictionary *m_gridMap;
    
}

@property (nonatomic, retain) NSString *levelName;
@property (nonatomic, retain) NSString *levelDescription;

-(BOOL)setPreset:(EBlockPreset)preset atXGrid:(NSUInteger)xGrid yGrid:(NSUInteger)yGrid w:(NSUInteger)wGrid h:(NSUInteger)hGrid groupId:(GroupId)groupId;
-(EGridBlockMarker *)getMarkerAtXGrid:(UInt32)xGrid yGrid:(UInt32)yGrid;
-(EGridBlockMarker *)getMarkerAt:(CGPoint)p;
-(NSArray *)getValues;

@end
