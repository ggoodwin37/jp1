//
//  SpriteManager.m
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpriteManager.h"


@implementation SpriteManager

@synthesize spriteSheetListForTestPurposes;

-(id)init
{
    if( self = [super init] )
    {
        m_spriteDefMap = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
        m_animDefMap = [[NSMutableDictionary dictionaryWithCapacity:100] retain];
        m_toggleDefMap = [[NSMutableDictionary dictionaryWithCapacity:32] retain];
        
        m_imageMap = nil;
        
        self.spriteSheetListForTestPurposes = nil;
    }
    return self;
}


-(void)dealloc
{
    self.spriteSheetListForTestPurposes = nil;
    [m_imageMap release]; m_imageMap = nil;
    [m_toggleDefMap release]; m_toggleDefMap = nil;
    [m_spriteDefMap release]; m_spriteDefMap = nil;
    [m_animDefMap release]; m_animDefMap = nil;
    [super dealloc];
}


-(void)cacheTexCoordsForSprites
{
    NSArray *spriteDefs = [m_spriteDefMap allValues];
    for( int i = 0; i < [spriteDefs count]; ++i )
    {
        SpriteDef *thisSpriteDef = (SpriteDef *)[spriteDefs objectAtIndex:i];
        GLfloat x0, x1, y0, y1;
        x0 = thisSpriteDef.nativeBounds.origin.x / thisSpriteDef.spriteSheet.nativeSize.width;
        x1 = (thisSpriteDef.nativeBounds.origin.x + thisSpriteDef.nativeBounds.size.width) / thisSpriteDef.spriteSheet.nativeSize.width;
        y0 = thisSpriteDef.nativeBounds.origin.y / thisSpriteDef.spriteSheet.nativeSize.height;
        y1 = (thisSpriteDef.nativeBounds.origin.y + thisSpriteDef.nativeBounds.size.height) / thisSpriteDef.spriteSheet.nativeSize.height;
        
        // not exactly sure why this y invert is needed, but it is :P
        // y axis, y u no behave predictably when converting between CG and OpenGL??????
        // TODO: don't I have another "late night y invert" somewhere? maybe this is his evil nemesis.
        y0 = 1.f - y0;
        y1 = 1.f - y1;
        
        // assume GL_TRIANGLES scheme
        thisSpriteDef.texCoordsCache[ 0] = x0; thisSpriteDef.texCoordsCache[ 1] = y0;
        thisSpriteDef.texCoordsCache[ 2] = x1; thisSpriteDef.texCoordsCache[ 3] = y0;
        thisSpriteDef.texCoordsCache[ 4] = x0; thisSpriteDef.texCoordsCache[ 5] = y1;
        thisSpriteDef.texCoordsCache[ 6] = x0; thisSpriteDef.texCoordsCache[ 7] = y1;
        thisSpriteDef.texCoordsCache[ 8] = x1; thisSpriteDef.texCoordsCache[ 9] = y0;
        thisSpriteDef.texCoordsCache[10] = x1; thisSpriteDef.texCoordsCache[11] = y1;
    }
}


// this work is shared between the texture and UIImage flavors. This parses all xml and stores it in member vars.
-(void)populateDefMaps
{
    NSMutableDictionary *spriteSheetTable = [NSMutableDictionary dictionaryWithCapacity:20];
    
    NSArray *spriteDefResources = [NSArray arrayWithObjects:@"Sprites0.xml", @"Sprites1.xml", nil];
    SpriteDefLoader *spriteDefLoader = [[SpriteDefLoader alloc] init];
    NSArray *spriteDefs = [spriteDefLoader loadSpriteDefsFrom:spriteDefResources withSpriteSheetTable:spriteSheetTable];
    [spriteDefLoader release];
    for( int i = 0; i < [spriteDefs count]; ++i )
    {
        SpriteDef *thisSpriteDef = (SpriteDef *)[spriteDefs objectAtIndex:i];
        id existingValue = [m_spriteDefMap valueForKey:thisSpriteDef.name];
        if( existingValue == nil )
        {        
            [m_spriteDefMap setValue:thisSpriteDef forKey:thisSpriteDef.name];
        }
        else
        {
            NSLog( @"ignoring duplicate spritedef with name \"%@\".", thisSpriteDef.name );
        }
    }
    
    NSArray *animDefResources = [NSArray arrayWithObjects:@"Anims0.xml", @"Anims1.xml", nil];
    AnimDefLoader *animDefLoader = [[AnimDefLoader alloc] init];
    NSArray *animDefs = [animDefLoader loadAnimDefsFrom:animDefResources withSpriteDefTable:m_spriteDefMap];
    [animDefLoader release];
    for( int i = 0; i < [animDefs count]; ++i )
    {
        AnimDef *thisAnimDef = (AnimDef *)[animDefs objectAtIndex:i];
        id existingValue = [m_animDefMap valueForKey:thisAnimDef.name];
        if( existingValue == nil )
        {
            [m_animDefMap setValue:thisAnimDef forKey:thisAnimDef.name];
        }
        else
        {
            NSLog( @"ignoring duplicate animdef with name \"%@\".", thisAnimDef.name );
        }
    }
    
    NSArray *toggleDefResources = [NSArray arrayWithObjects:@"Sprites1.xml", nil];
    ToggleDefLoader *toggleDefLoader = [[[ToggleDefLoader alloc] init] autorelease];
    NSArray *toggleDefs = [toggleDefLoader loadToggleDefsFrom:toggleDefResources withSpriteDefTable:m_spriteDefMap];
    for( int i = 0; i < [toggleDefs count]; ++i )
    {
        ToggleDef *thisToggleDef = (ToggleDef *)[toggleDefs objectAtIndex:i];
        id existingValue = [m_toggleDefMap valueForKey:thisToggleDef.name];
        if( existingValue == nil )
        {
            [m_toggleDefMap setValue:thisToggleDef forKey:thisToggleDef.name];
        }
        else
        {
            NSLog( @"ignoring duplicate toggledef with name \"%@\".", thisToggleDef.name );
        }
    }
}


-(SpriteSheet *)getNewOptSheetWidth:(size_t)width height:(size_t)height identifier:(int)dentifier
{
    SpriteSheet *sheet = [[SpriteSheet alloc] initWithName:[NSString stringWithFormat:@"optsheet%d", dentifier]];
    sheet.isMemImage = YES;
    sheet.nativeSize = CGSizeMake( width, height );
    
    static const size_t kComponentsPerPixel = 4;
    static const size_t kBitsPerComponent = sizeof(unsigned char) * 8;
    
    size_t bufferLength = width * height * kComponentsPerPixel;
    unsigned char *buffer = calloc( width * height, kComponentsPerPixel );
    memset( buffer, 0, bufferLength );
    
    NSData *bufferData = [NSData dataWithBytesNoCopy:buffer length:bufferLength];
    sheet.imageBuffer = bufferData;  // ownership transferred, don't need to free explicitly.
    
    CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData( NULL, buffer, bufferLength, NULL );

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();  // TODO free?
    sheet.memImage = CGImageCreate( width, height,
                                    kBitsPerComponent,
                                    kComponentsPerPixel * kBitsPerComponent,
                                    kComponentsPerPixel * width,
                                    rgbColorSpace,
                                    kCGBitmapByteOrderDefault | kCGImageAlphaLast,
                                    dataProviderRef,
                                    NULL,
                                    NO /*shouldInterpolate*/,
                                    kCGRenderingIntentDefault );
    
    NSLog( @"created optSheet with name %@ of size %ld bytes.", sheet.name, bufferLength );

    return sheet;
}


-(void)copySprite:(SpriteDef *)sourceDef fromImage:(UIImage *)sourceUIImage toContext:(CGContextRef)destContext atP:(CGPoint)destP
{
    NSAssert( sizeof( GLubyte ) == sizeof( unsigned char ), @"casting ptrs to these back and forth...better way?" );
    
    CGImageRef targetImageTransfer = CGImageCreateWithImageInRect( sourceUIImage.CGImage, sourceDef.nativeBounds );
    
    CGRect destRect = CGRectMake( destP.x, destP.y, sourceDef.nativeBounds.size.width, sourceDef.nativeBounds.size.height );
    CGContextDrawImage( destContext, destRect, targetImageTransfer );

    CGImageRelease( targetImageTransfer );
}


-(CGContextRef)createTempContextForSheet:(SpriteSheet *)destSheet
{
    NSAssert( destSheet.isMemImage, @"getTempContextForSheet: bad input sheet type." );
    void *backingBuffer = (void *)[destSheet.imageBuffer bytes];

    CGContextRef destContext = CGBitmapContextCreate( backingBuffer,
                                                      destSheet.nativeSize.width, destSheet.nativeSize.height,
                                                      8 /*bitsPerComponent*/, destSheet.nativeSize.width * 4 /*bytesPerRow*/,
                                                      CGImageGetColorSpace( destSheet.memImage ), kCGImageAlphaPremultipliedLast );
    NSAssert( destContext != 0, @"bad destContext" );
    return destContext;
}


-(NSArray *)sortSpriteDefListByHeight:(NSArray *)spriteDefList
{
    NSMutableArray *result = [NSMutableArray arrayWithArray:spriteDefList];

    [result sortUsingSelector:@selector(compareHeightDecreasing:)];
    return result;
}


-(NSArray *)optimizeSheets
{
    NSMutableDictionary *imageNameToImageMap = [NSMutableDictionary dictionaryWithCapacity:32];
    NSArray *instanceSpriteDefList = [m_spriteDefMap allValues];
    
    // load all images referenced by unoptimized sheets from the bundle.
    for( int i = 0; i < [instanceSpriteDefList count]; ++i )
    {
        SpriteDef *thisSpriteDef = (SpriteDef *)[instanceSpriteDefList objectAtIndex:i];
        NSString *thisSpriteSheetImageName = thisSpriteDef.spriteSheet.name;
        if( [imageNameToImageMap valueForKey:thisSpriteSheetImageName] == nil )
        {
            UIImage *thisSpriteSheetImage = [UIImage imageNamed:thisSpriteSheetImageName];
            [imageNameToImageMap setValue:thisSpriteSheetImage forKey:thisSpriteSheetImageName];
        }
    }

    const size_t compositeSheetWidth  = 512;
    const size_t compositeSheetHeight = 512;
    const int padding = 2;
    
    NSMutableArray *optimizedSheetList = [NSMutableArray arrayWithCapacity:4];
    SpriteSheet *currentOptimizedSheet = [self getNewOptSheetWidth:compositeSheetWidth height:compositeSheetHeight identifier:0];
    
    // create a temporary context to draw into, backed by the memory we already allocated.
    CGContextRef destContext = [self createTempContextForSheet:currentOptimizedSheet];

    int xDraw = 0;
    int yDraw = 0;
    int maxHeightForThisRow = 0;

    // iterate over sorted sprite def list.
    NSArray *spriteDefList = [self sortSpriteDefListByHeight:instanceSpriteDefList];
    
    for( int i = 0; i < [spriteDefList count]; ++i )
    {
        SpriteDef *thisSpriteDef = (SpriteDef *)[spriteDefList objectAtIndex:i];

        if( xDraw + 2 * padding + thisSpriteDef.nativeBounds.size.width >= compositeSheetWidth )
        {
            xDraw = 0;
            yDraw += 2 * padding + maxHeightForThisRow;  // may have overflowed current sprite sheet, in which case we'll create a new one next loop.
            maxHeightForThisRow = 0;
        }

        // check if we need to overflow to a new optSheet
        if( yDraw + thisSpriteDef.nativeBounds.size.height + (2 * padding) >= compositeSheetHeight )
        {
            [optimizedSheetList addObject:currentOptimizedSheet];
            currentOptimizedSheet = [self getNewOptSheetWidth:compositeSheetWidth height:compositeSheetHeight identifier:[optimizedSheetList count]];
            xDraw = yDraw = maxHeightForThisRow = 0;
            
            // update temp context
            CGContextRelease( destContext );
            destContext = [self createTempContextForSheet:currentOptimizedSheet];
        }
        
        // copy the image to the new sheet
        UIImage *origImage = [imageNameToImageMap valueForKey:thisSpriteDef.spriteSheet.name];
        NSAssert( origImage != nil, @"missing origImage" );
        CGPoint pTarget = CGPointMake( xDraw + padding, yDraw + padding );
        [self copySprite:thisSpriteDef fromImage:origImage toContext:destContext atP:pTarget];
        
        // update the spritedef with the new sheet's info so that we cache coords from the new optimized texture.
        [thisSpriteDef updateWithNewSheet:currentOptimizedSheet newBounds:CGRectMake( pTarget.x, pTarget.y, thisSpriteDef.nativeBounds.size.width, thisSpriteDef.nativeBounds.size.height )];
        
        // keep track of max height for this row so we know how much to increment y when we reach end of row.
        if( thisSpriteDef.nativeBounds.size.height > maxHeightForThisRow )
        {
            maxHeightForThisRow = thisSpriteDef.nativeBounds.size.height;
        }

        // advance draw pointer to next row.
        xDraw += 2 * padding + thisSpriteDef.nativeBounds.size.width;
    }

    // add the last sheet we were working on.
    [optimizedSheetList addObject:currentOptimizedSheet];

    // release the last temp context
    CGContextRelease( destContext );

    return optimizedSheetList;
}


-(void)loadAllSpriteTextures
{
    [self populateDefMaps];
    NSArray *optSpriteSheetArray = [self optimizeSheets];
    NSLog( @"optimized to %d composite sheet(s).", [optSpriteSheetArray count] );
    
    TexLoader *texLoader = [[TexLoader alloc] init];
    [texLoader loadTexturesForSpriteSheets:optSpriteSheetArray];
    [texLoader release];
    
    [self cacheTexCoordsForSprites];
    
    self.spriteSheetListForTestPurposes = optSpriteSheetArray;
}


-(SpriteDef *)getSpriteDef:(NSString *)name
{
    return (SpriteDef *)[m_spriteDefMap objectForKey:name];    
}


-(AnimDef *)getAnimDef:(NSString *)name
{
    return (AnimDef *)[m_animDefMap objectForKey:name];    
}


-(ToggleDef *)getToggleDef:(NSString *)name
{
    return (ToggleDef *)[m_toggleDefMap objectForKey:name];
}


// UIImage API for Edit mode.

-(void)loadAllImages
{
    [self populateDefMaps];
    NSArray *spriteDefs = [m_spriteDefMap allValues];
    NSLog( @"loading images for %d sprites.", [spriteDefs count] );
    
    ImageLoader *imageLoader = [[ImageLoader alloc] init];
    m_imageMap = [[imageLoader loadImagesForSpriteDefList:spriteDefs] retain];
    [imageLoader release];
}


-(UIImage *)getImageForSpriteName:(NSString *)name
{
    if( m_imageMap == nil )
    {
        NSLog( @"SpriteManager getImageForSpriteName: image map is not initialized." );
        return nil;
    }
    if( name == nil )
    {
        return nil;
    }
    return (UIImage *)[m_imageMap valueForKey:name];
}


static SpriteManager *globalSpriteManagerInstance = nil;

+(void)initGlobalInstance
{
    NSAssert( globalSpriteManagerInstance == nil, @"initializing global SpriteManager more than once is BAD." );
    globalSpriteManagerInstance = [[SpriteManager alloc] init];
}


+(void)releaseGlobalInstance
{
    [globalSpriteManagerInstance release]; globalSpriteManagerInstance = nil;
}


+(SpriteManager *)instance
{
    return globalSpriteManagerInstance;
}

@end
