//
//  SpriteManager.h
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpriteLoader.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteManager
@interface SpriteManager : NSObject {
    
    NSMutableDictionary *m_spriteDefMap;
    NSMutableDictionary *m_animDefMap;
    
    NSDictionary        *m_imageMap;
    
}

// allow easy access to the flat list of all sprite sheets. this is only needed for testing purposes.
@property (nonatomic, retain) NSArray *spriteSheetListForTestPurposes;

-(void)loadAllSpriteTextures;
-(SpriteDef *)getSpriteDef:(NSString *)name;
-(AnimDef *)getAnimDef:(NSString *)name;

// UIImage API for Edit mode.
-(void)loadAllImages;
-(UIImage *)getImageForSpriteName:(NSString *)name;

+(void)initGlobalInstance;
+(void)releaseGlobalInstance;
+(SpriteManager *)instance;

@end
