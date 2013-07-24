//
//  SpriteLoader.m
//  JumpProto
//
//  Created by gideong on 8/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SpriteLoader.h"
#import "LogStopWatch.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// SpriteDefLoader
@interface SpriteDefLoader (private)
@end

@implementation SpriteDefLoader

-(id)init
{
    if( self = [super init] )
    {
        m_spriteSheetTable = nil;
        m_resultSprites = nil;
    }
    return self;
}


-(void)dealloc
{
    // weak references
    m_spriteSheetTable = nil;
    m_resultSprites = nil;
    
    [super dealloc];
}


// take in a list of xml resource URIs, parse them, and return a list of SpriteDefs.
// the spriteSheetTable is populated lazily and incrementally. First we'll add an entry for a newly-referenced image,
// then we'll update this entry later when we load the corresponding texture.
-(NSArray *)loadSpriteDefsFrom:(NSArray *)spriteResources withSpriteSheetTable:(NSMutableDictionary *)spriteSheetTable
{
    // these weak references are only valid during the lifetime of parse, we don't own them.
    m_spriteSheetTable = spriteSheetTable;
    m_resultSprites = [NSMutableArray arrayWithCapacity:50]; // TODO: bigger capacity? :)

    LogStopWatch *stopWatch;
    stopWatch = [[LogStopWatch alloc] initWithName:@"spriteDefParse"];
    [stopWatch start];

    for( int iResource = 0; iResource < [spriteResources count]; ++iResource )
    {
        NSString *thisResource = (NSString *)[spriteResources objectAtIndex:iResource];

        // assume this resource lives in the main bundle for now.
        // FUTURE: optionally read these from Documents instead?
        NSURL *thisUrl = [[NSBundle mainBundle] URLForResource:thisResource withExtension:nil];
        
        NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:thisUrl] autorelease];
        parser.delegate = self;
        
        if( NO == [parser parse] )
        {
            NSAssert1( NO, @"Failed to parse resource at URL %@", [thisUrl absoluteString] );
            continue;
        }
    }
    
    [stopWatch stop];

    NSArray *returnVal = m_resultSprites;
    m_resultSprites = nil;
    m_spriteSheetTable = nil;
    return returnVal;
}


// NSXMLParser delegate stuff

static NSString *kName_SpriteDefRun = @"SpriteDefRun";
static NSString *kAttr_resourceName = @"resourceName";
static NSString *kAttr_xStart = @"xStart";
static NSString *kAttr_yStart = @"yStart";
static NSString *kAttr_xEnd = @"xEnd";
static NSString *kAttr_spriteWidth = @"spriteWidth";
static NSString *kAttr_spriteHeight = @"spriteHeight";
static NSString *kName_NextSprite = @"NextSprite";
static NSString *kAttr_name = @"name";
static NSString *kAttr_flippedX = @"xFlip";
static NSString *kAttr_worldWidth = @"worldWidth";
static NSString *kAttr_worldHeight = @"worldHeight";


-(void)initRunWithAttributes:(NSDictionary *)attr
{
    NSString *resourceName = (NSString *)[attr valueForKey:kAttr_resourceName];
    
    m_currentRunSpriteSheet = (SpriteSheet *)[m_spriteSheetTable valueForKey:resourceName];
    if( nil == m_currentRunSpriteSheet )
    {
        m_currentRunSpriteSheet = [[SpriteSheet alloc] initWithName:resourceName];
        // other spriteSheet attributes get set during texture load.
        [m_spriteSheetTable setValue:m_currentRunSpriteSheet forKey:resourceName];
    }
   
    m_currentRunXStart       = [[attr valueForKey:kAttr_xStart] intValue];
    m_currentRunYStart       = [[attr valueForKey:kAttr_yStart] intValue];
    m_currentRunXEnd         = [[attr valueForKey:kAttr_xEnd] intValue];
    m_currentRunSpriteWidth  = [[attr valueForKey:kAttr_spriteWidth] intValue];
    m_currentRunSpriteHeight = [[attr valueForKey:kAttr_spriteHeight] intValue];
    
    NSString *attrStr;
    attrStr = [attr valueForKey:kAttr_worldWidth];
    if( attrStr != nil ) {
        m_currentRunWorldWidth = [attrStr intValue];
    } else {
        m_currentRunWorldWidth = 4;
    }
    attrStr = [attr valueForKey:kAttr_worldHeight];
    if( attrStr != nil ) {
        m_currentRunWorldHeight = [attrStr intValue];
    } else {
        m_currentRunWorldHeight = 4;
    }

    m_currentRunX = m_currentRunXStart;
    m_currentRunY = m_currentRunYStart;
}


-(void)nextSpriteWithAttributes:(NSDictionary *)attr
{
    NSString *spriteName = [attr valueForKey:kAttr_name];
    if( spriteName != nil )
    {
        BOOL isFlipped = NO;
        NSNumber *isFlippedValue = [attr valueForKey:kAttr_flippedX];
        if( isFlippedValue != nil )
        {
            isFlipped = [isFlippedValue boolValue];
        }
        
        CGRect bounds = CGRectMake( m_currentRunX, m_currentRunY, m_currentRunSpriteWidth, m_currentRunSpriteHeight );
        CGSize worldSize = CGSizeMake( m_currentRunWorldWidth, m_currentRunWorldHeight);
        SpriteDef *spriteDef = [[SpriteDef alloc] initWithName:spriteName spriteSheet:m_currentRunSpriteSheet nativeBounds:bounds isFlipped:isFlipped worldSize:worldSize];
        [m_resultSprites addObject:spriteDef];
        [spriteDef release];  // now owned by result array.
    }
    else
    {
        // empty sprite name means do nothing for this space in the source image.
    }
    
    // increment state for nextSprite
    m_currentRunX += m_currentRunSpriteWidth;
    if( m_currentRunX >= m_currentRunXEnd )
    {
        m_currentRunX = m_currentRunXStart;
        m_currentRunY += m_currentRunSpriteHeight;
        // TODO/FUTURE: stride?
        //              actually I prefer numSpritesPerRow, which lets us calculate stride (with image width) but is easier to use.
    }
    
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if( [elementName isEqualToString:kName_SpriteDefRun] )
    {
        [self initRunWithAttributes:attributeDict];
    }
    else if( [elementName isEqualToString:kName_NextSprite] )
    {
        [self nextSpriteWithAttributes:attributeDict];
    }
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // I don't think we need to do anything in particular when a spriteDefRun ends.
}


-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // we don't need textNodes for this parser.
}


-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog( @"spriteParser parseErrorOccurred \"%@\"", [parseError localizedDescription] );
    // Handle errors as appropriate for your application.
}



@end




/////////////////////////////////////////////////////////////////////////////////////////////////////////// AnimDefLoader
@implementation AnimDefLoader

-(id)init
{
    if( self = [super init] )
    {
        m_resultAnims = nil;
        m_spriteDefTable = nil;
    }
    return self;
}


-(void)dealloc
{
    m_resultAnims = nil;    // weak
    m_spriteDefTable = nil; // weak
    [super dealloc];
}


// take in a list of xml resource URIs, parse them, and return a list of AnimDefs.
-(NSArray *)loadAnimDefsFrom:(NSArray *)animResources withSpriteDefTable:(NSDictionary *)spriteDefTable
{
    // these weak references are only valid during the lifetime of parse, we don't own them.
    m_resultAnims = [NSMutableArray arrayWithCapacity:50]; // TODO: bigger capacity? :)
    m_spriteDefTable = spriteDefTable;
    
    LogStopWatch *stopWatch;
    stopWatch = [[LogStopWatch alloc] initWithName:@"animDefParse"];
    [stopWatch start];
    
    for( int iResource = 0; iResource < [animResources count]; ++iResource )
    {
        NSString *thisResource = (NSString *)[animResources objectAtIndex:iResource];
        
        // assume this resource lives in the main bundle for now.
        // FUTURE: optionally read these from Documents instead?
        NSURL *thisUrl = [[NSBundle mainBundle] URLForResource:thisResource withExtension:nil];
        
        NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:thisUrl] autorelease];
        parser.delegate = self;
        
        if( NO == [parser parse] )
        {
            NSAssert1( NO, @"Failed to parse resource at URL %@", [thisUrl absoluteString] );
            continue;
        }
    }
    
    [stopWatch stop];
    
    NSArray *returnVal = m_resultAnims;
    m_resultAnims = nil;
    m_spriteDefTable = nil;
    return returnVal;
}


// NSXMLParser delegate stuff

static NSString *kName_AnimDef = @"AnimDef";
static NSString *kName_AnimFrame = @"AnimFrame";
static NSString *kAttr_spriteName = @"spriteName";
static NSString *kAttr_dur = @"dur";

-(void)initAnimDefWithAttributes:(NSDictionary *)attr
{
    m_currentAnimName = [(NSString *)[attr valueForKey:kAttr_name] retain];
    m_currentAnimFrames = [[NSMutableArray arrayWithCapacity:20] retain];
}


-(void)addAnimFrameWithAttributes:(NSDictionary *)attr
{
    NSString *spriteName = [attr valueForKey:kAttr_spriteName];
    SpriteDef *thisSprite = (SpriteDef *)[m_spriteDefTable valueForKey:spriteName];
    if( thisSprite == nil )
    {
        NSLog( @"couldn't find referenced spriteName %@, ignoring frame.", spriteName );
        return;
    }
    float dur = [[attr valueForKey:kAttr_dur] floatValue];

    AnimFrameDef *thisFrame = [[AnimFrameDef alloc] initWithSprite:thisSprite relativeDur:dur];
    [m_currentAnimFrames addObject:thisFrame];
}


-(void)closeCurrentAnimDef
{
    AnimDef *thisAnimDef = [[AnimDef alloc] initWithName:m_currentAnimName frames:m_currentAnimFrames];
    [m_currentAnimName release]; m_currentAnimName = nil;
    [m_currentAnimFrames release]; m_currentAnimFrames = nil;
    
    [m_resultAnims addObject:thisAnimDef];
    //NSLog( @"added an animDef with name %@ and %d frames.", thisAnimDef.name, [thisAnimDef getNumFrames] );
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if( [elementName isEqualToString:kName_AnimDef] )
    {
        [self initAnimDefWithAttributes:attributeDict];
    }
    else if( [elementName isEqualToString:kName_AnimFrame] )
    {
        [self addAnimFrameWithAttributes:attributeDict];
    }
}


-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if( [elementName isEqualToString:kName_AnimDef] )
    {
        [self closeCurrentAnimDef];
    }
}


-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // we don't need textNodes for this parser.
}


-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog( @"spriteParser parseErrorOccurred \"%@\"", [parseError localizedDescription] );
    // Handle errors as appropriate for your application.
}

@end



/////////////////////////////////////////////////////////////////////////////////////////////////////////// DrawingResource
@implementation DrawingResource

@synthesize size, data;
@synthesize isWrapped;

-(id)initWithData:(void *)dataIn size:(CGSize)sizeIn
{
	if( self = [super init] )
	{
		self.size = sizeIn;
		self.data = dataIn;
        self.isWrapped = NO;
	}
	return self;
}


-(id)initWrappingData:(void *)dataIn size:(CGSize)sizeIn
{
	if( self = [super init] )
	{
		self.size = sizeIn;
		self.data = dataIn;
        self.isWrapped = YES;
	}
	return self;
}


-(void)dealloc
{
	if( self.data && !self.isWrapped )
		free( self.data );
    self.data = NULL;
    
	[super dealloc];
}

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// TexLoader
@implementation TexLoader

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}

-(DrawingResource *)createWrappedDrawingResourceWithBytes:(void *)bytes size:(CGSize)size
{
    return [[DrawingResource alloc] initWrappingData:bytes size:size];
}


// makes a copy of the input image. this copy is owned by the returned DrawingResource.
-(DrawingResource *)copyDrawingResourceFromMemImage:(CGImageRef)theImage
{
    const float paddingPixels = 0.f;
	DrawingResource *dr = nil;

	size_t dstPixelWidth = CGImageGetWidth( theImage );
	size_t dstPixelHeight = CGImageGetHeight( theImage );
    
	if( theImage )
	{
		GLubyte *imageData = (GLubyte *)calloc( dstPixelWidth * dstPixelHeight * 4, sizeof( GLubyte ) );
		CGContextRef imageContext = CGBitmapContextCreate( imageData, dstPixelWidth, dstPixelHeight, 8, dstPixelWidth * 4, CGImageGetColorSpace( theImage ), kCGImageAlphaPremultipliedLast );
        
		CGContextDrawImage( imageContext, CGRectMake( paddingPixels, paddingPixels,
                                                     (CGFloat)dstPixelWidth - (2.0f * paddingPixels), (CGFloat)dstPixelHeight - (2.0f * paddingPixels) ), theImage );
        
        // transfer ownership of the imageData to the drawingResource.
		dr = [[DrawingResource alloc] initWithData:imageData size:CGSizeMake( dstPixelWidth, dstPixelHeight )];
	}
    else
    {
        NSLog( @"failed to create drawing resource." );
    }
	
	return dr;
}


-(DrawingResource *)createDrawingResourceFromAppResource:(NSString *)resourceName
{
	// TODO: use imageWithContentsOfFile here instead? see http://stackoverflow.com/questions/1484402/need-help-on-didrecievememorywarning-in-iphone/1484448#1484448
	CGImageRef theImage = [UIImage imageNamed:resourceName].CGImage;
    return [self copyDrawingResourceFromMemImage:theImage];
}


-(GLuint)uploadTextureForDrawingResource:(DrawingResource *)dr
{
    size_t xSheetDim = 1;
    while( xSheetDim < (size_t)dr.size.width )
        xSheetDim <<= 1;
    size_t ySheetDim = 1;
    while( ySheetDim < (size_t)dr.size.height )
        ySheetDim <<= 1;
    
    if( (xSheetDim != (size_t)dr.size.width ) || (ySheetDim != (size_t)dr.size.height) )
    {
        NSLog( @"Error: found a drawing resource with non-power-of-2 dimensions, fix the image or make this code more flexible." );
        return 0;
        // See BabyPop implementation for how to copy this image to a rightly size image, if we need this case.
        // (you'll probably want to support this eventually to make it easier to import random spriteSheets)
    }
    
    // create the OpenGL texture.
    GLuint texSheetName;		
    glGenTextures( 1, &texSheetName );
    NSAssert( texSheetName != 0, @"assumed that 0 is a special texture name, but evidently not." );
    glBindTexture( GL_TEXTURE_2D, texSheetName );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );   // FUTURE: ??
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, xSheetDim, ySheetDim, 0, GL_RGBA, GL_UNSIGNED_BYTE, dr.data );
    
    return texSheetName;
}


-(void)loadTexturesForSpriteSheets:(NSArray *)spriteSheets
{
    LogStopWatch *stopWatch;
    stopWatch = [[LogStopWatch alloc] initWithName:@"loadTextures"];
    [stopWatch start];

    for( int i = 0; i < [spriteSheets count]; ++i )
    {
        SpriteSheet *thisSpriteSheet = (SpriteSheet *)[spriteSheets objectAtIndex:i];
        
        // first, copy or wrap the image with a DrawingResource. the image may come from the bundle or directly from memory in the optimize case.
        DrawingResource *thisDr;
        if( thisSpriteSheet.isMemImage )
        {
            void *uploadBytes = (void *)[thisSpriteSheet.imageBuffer bytes];
            CGSize drSize = CGSizeMake( CGImageGetWidth( thisSpriteSheet.memImage ), CGImageGetHeight( thisSpriteSheet.memImage ) );            
            thisDr = [self createWrappedDrawingResourceWithBytes:uploadBytes size:drSize];
        }
        else
        {
            thisDr = [self createDrawingResourceFromAppResource:thisSpriteSheet.name];
        }
        
        // next, upload image data to OpenGL
        if( thisDr != nil )
        {
            GLuint texName = [self uploadTextureForDrawingResource:thisDr];
            thisSpriteSheet.texName = texName;
            thisSpriteSheet.nativeSize = thisDr.size;  // only needed in from-bundle case (else we already chose our native size when creating opt sheet)
            
            // don't need to keep the intermediate image around.
            //  (revisit this if we ever need to re-upload textures for some reason).
            [thisDr release];
        }
        else
        {
            NSLog( @"failed to create drawingResource for resource \"%@\".", thisSpriteSheet.name );
        }
    }
    
    [stopWatch stop];
    
}


@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ImageLoader
@implementation ImageLoader

-(id)init
{
    if( self = [super init] )
    {
    }
    return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(UIImage *)getUIImageFromCGImage:(CGImageRef)cgImageRef isFlipped:(BOOL)isFlipped
{
    // note: something funky going on with y-flipped-ness here. If you try to draw this image using CGDrawImage type functions, it will be
    //       upside-down. I've worked around this at EWorldView by using the UIImage flavor of the draw function. This handles y-orientation
    //       correctly, but precludes the use of fancy CGContext manipulation. It might be better to do the flip here, at the CG-source level,
    //       to allow more freedom when drawing the image. If necessary we can do some fancy new image-transform-redraw type of stuff, but I'd
    //       hope there's a better way.
    
    // here's some discussion on the subject:
    // http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage

    
    // note: using a different image orientation doesn't appear to work here if we are drawing the underlying CGImage (only works when
    //       using the UIImage drawer)
    return [UIImage imageWithCGImage:cgImageRef scale:1.f orientation:( isFlipped ? UIImageOrientationUpMirrored : UIImageOrientationUp)];

}


-(NSDictionary *)loadImagesForSpriteDefList:(NSArray *)spriteDefList
{
    LogStopWatch *stopWatch;
    stopWatch = [[LogStopWatch alloc] initWithName:@"loadImages"];
    [stopWatch start];
    
    NSMutableDictionary *resultMap = [NSMutableDictionary dictionaryWithCapacity:50];
    
    // TODO: if this goes slowly, can save a little time by loading each sheet only once.
    //  (currently this will reload a given sheet for each sprite that references it)
    
    // TODO: double check memory ownership here, I am assuming that thisImage gets ownership of the CGImageRef's memory,
    //       then will correctly release it when we release all of the images.
    
    for( int i = 0; i < [spriteDefList count]; ++i )
    {
        SpriteDef *thisSpriteDef = (SpriteDef *)[spriteDefList objectAtIndex:i];
        UIImage *sheetImage = [UIImage imageNamed:thisSpriteDef.spriteSheet.name];
        CGImageRef croppedImageRef = CGImageCreateWithImageInRect( [sheetImage CGImage], thisSpriteDef.nativeBounds );
        UIImage *thisImage = [self getUIImageFromCGImage:croppedImageRef isFlipped:thisSpriteDef.isFlipped];
        
        [resultMap setValue:thisImage forKey:thisSpriteDef.name];
    }
    
    [stopWatch stop];
                              
    return resultMap;
}


@end
