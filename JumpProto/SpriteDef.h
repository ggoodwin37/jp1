//
//  SpriteDef.h
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteSheet
@interface SpriteSheet : NSObject {
}

@property (nonatomic, assign) BOOL isMemImage;
@property (nonatomic, assign) CGImageRef memImage;
@property (nonatomic, retain) NSData *imageBuffer;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, assign) CGSize nativeSize;
@property (nonatomic, assign) GLuint texName;

-(id)initWithName:(NSString *)name;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteDef
@interface SpriteDef : NSObject {
    GLfloat m_texCoordsCache[12];  // assumes GL_TRIANGLES scheme
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) SpriteSheet *spriteSheet;
@property (nonatomic, readonly) CGRect nativeBounds;       // these are in image-space, so y increases downward.
@property (nonatomic, readonly) CGSize worldSize;
@property (nonatomic, readonly, getter=getTexCoordsCache) GLfloat *texCoordsCache;
@property (nonatomic, readonly) BOOL isFlipped;

-(id)initWithName:(NSString *)name spriteSheet:(SpriteSheet *)spriteSheet nativeBounds:(CGRect)nativeBounds isFlipped:(BOOL)isFlipped worldSize:(CGSize)worldSize;
-(void)updateWithNewSheet:(SpriteSheet *)newSheet newBounds:(CGRect)newBounds;

-(NSComparisonResult)compareHeightDecreasing:(SpriteDef *)other;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimFrameDef
@interface AnimFrameDef : NSObject {
}

@property (nonatomic, readonly) SpriteDef *sprite;
@property (nonatomic, assign) float relativeDur;

-(id)initWithSprite:(SpriteDef *)sprite relativeDur:(float)relativeDur;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimDef
@interface AnimDef : NSObject {
    NSArray *m_frames;
}

@property (nonatomic, readonly) NSString *name;

-(id)initWithName:(NSString *)name frames:(NSArray *)frames;
-(int)getNumFrames;
-(AnimFrameDef *)getFrame:(int)i;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ToggleDef
@interface ToggleDef : NSObject {
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) SpriteDef *offSprite;
@property (nonatomic, readonly) SpriteDef *onSprite;

-(id)initWithName:(NSString *)name offSprite:(SpriteDef *)offSprite onSprite:(SpriteDef *)onSprite;

@end

