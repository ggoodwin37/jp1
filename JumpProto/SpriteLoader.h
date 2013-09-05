//
//  SpriteLoader.h
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpriteDef.h"



/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteDefLoader
@interface SpriteDefLoader : NSObject<NSXMLParserDelegate> {

    NSMutableDictionary *m_spriteSheetTable;
    NSMutableArray *m_resultSprites;
    
    int m_currentRunX;
    int m_currentRunY;
    
    int m_currentRunXStart;
    int m_currentRunYStart;
    int m_currentRunXEnd;
    int m_currentRunSpriteWidth;
    int m_currentRunSpriteHeight;
    int m_currentRunWorldWidth;
    int m_currentRunWorldHeight;

    SpriteSheet *m_currentRunSpriteSheet;
}

// take in a list of xml resource URIs, parse them, and return a list of SpriteDefs.
// the spriteSheetTable is populated lazily and incrementally. First we'll add an entry for a newly-referenced image,
// then we'll update this entry later when we load the corresponding texture.
-(NSArray *)loadSpriteDefsFrom:(NSArray *)spriteResources withSpriteSheetTable:(NSMutableDictionary *)spriteSheetTable;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimDefLoader
@interface AnimDefLoader : NSObject<NSXMLParserDelegate> {
    NSMutableArray *m_resultAnims;
    
    NSString *m_currentAnimName;
    NSMutableArray *m_currentAnimFrames;
    
    NSDictionary *m_spriteDefTable; // weak    
}

// take in a list of xml resource URIs, parse them, and return a list of AnimDefs.
-(NSArray *)loadAnimDefsFrom:(NSArray *)animResources withSpriteDefTable:(NSDictionary *)spriteDefTable;
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ToggleDefLoader
@interface ToggleDefLoader : NSObject<NSXMLParserDelegate> {
    NSMutableArray *m_resultDefs;
    NSDictionary *m_spriteDefTable; // weak
}

// take in a list of xml resource URIs, parse them, and return a list of ToggleDefs.
-(NSArray *)loadToggleDefsFrom:(NSArray *)resources withSpriteDefTable:(NSDictionary *)spriteDefTable;
@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// DrawingResource
@interface DrawingResource : NSObject {
}
@property(nonatomic,assign) CGSize size;
@property(nonatomic,assign) void *data;
@property(nonatomic,assign) BOOL isWrapped;

-(id)initWithData:(void *)dataIn size:(CGSize)sizeIn;
-(id)initWrappingData:(void *)dataIn size:(CGSize)sizeIn;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TexLoader
@interface TexLoader : NSObject {
}

// take in a list of SpriteSheets and create textures for all image resources (sprite sheet pngs or in-mem clustered textures) they reference.
// the spriteSheets in the array are in_out because we'll assign texture sheet names and
//  native dims to them as we load textures.
-(void)loadTexturesForSpriteSheets:(NSArray *)spriteSheets;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ImageLoader
@interface ImageLoader : NSObject {
}

// take in a list of SpriteSheets and create UIImages for all image resources (sprite sheet pngs) they reference.
// the spriteSheets in the array are in_out because we'll assign native dims to them as we go.
-(NSDictionary *)loadImagesForSpriteDefList:(NSArray *)spriteDefList;

@end
