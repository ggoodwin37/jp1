//
//  ArchiveFormat.h
//  JumpProto
//
//  Created by gideong on 10/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sharedTypes.h"
#import "EBlockPreset.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFBlockProps
@interface AFBlockProps : NSObject<NSCoding> {
    
}

// note about AFBlockProps: usually you assign properties by preset via a big switch statement in WorldArchiveUtil.
//  you don't normally have to serialize these since Edit doesn't care about them.

@property (nonatomic, assign) UInt32 token;

@property (nonatomic, assign) BOOL canMoveFreely;
@property (nonatomic, assign) BOOL affectedByGravity;
@property (nonatomic, assign) BOOL affectedByFriction;
@property (nonatomic, assign) float bounceDampFactor;
@property (nonatomic, assign) CGPoint initialVelocity;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFBlock
@interface AFBlock : NSObject<NSCoding> {
    
}
@property (nonatomic, retain) AFBlockProps *props;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) GroupId groupId;

-(id)initWithProps:(AFBlockProps *)props rect:(CGRect)rect groupId:(GroupId)groupId;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFSpriteBlock
@interface AFSpriteBlock : AFBlock {
    
}
@property (nonatomic, retain) NSString *resourceName;
@property (nonatomic, assign) float animDur;

-(id)initWithProps:(AFBlockProps *)props rect:(CGRect)rect groupId:(GroupId)groupId
      resourceName:(NSString *)resourceName animDur:(float)animDur;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFAutoVariationMap
@interface AFAutoVariationMap : NSObject<NSCoding> {
    NSMutableData *m_data;
}
@property (nonatomic, readonly) CGSize size;

-(id)initWithSize:(CGSize)size;
-(UInt32)getHintAtX:(int)x y:(int)y;
-(void)setHintAtX:(int)x y:(int)y to:(UInt32)hint;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFPresetBlockBase
@interface AFPresetBlockBase : NSObject<NSCoding> {
    
}
@property (nonatomic, assign) UInt32 token;
@property (nonatomic, assign) EBlockPreset preset;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) GroupId groupId;
@property (nonatomic, retain) AFAutoVariationMap *autoVariationMap;

-(id)initWithPreset:(EBlockPreset)preset rect:(CGRect)rect groupId:(GroupId)groupId autoVariationMap:(AFAutoVariationMap *)avMap;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFLevelProps
@interface AFLevelProps : NSObject<NSCoding> {
    
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AFLevel
@interface AFLevel : NSObject<NSCoding>
{

    
}
@property (nonatomic, retain) AFLevelProps *props;
@property (nonatomic, retain) NSArray *blockList;
@property (nonatomic, assign) CGRect boundingBox;

-(id)initWithProps:(AFLevelProps *)props blockList:(NSArray *)blockList;

@end

