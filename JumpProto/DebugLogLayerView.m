//
//  DebugLogLayerView.m
//  JumpProto
//
//  Created by gideong on 7/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DebugLogLayerView.h"
#import "AspectController.h"
#import "constants.h"


// DebugTextBuffer /////////////////////////////////////////////////////////////////


@interface DebugTextBuffer (private)
@end


@implementation DebugTextBuffer

#define TEXTBUFFERMAXLINES     (30)


// TODO: need thread safety in this class?

-(id)init
{
    if( self = [super init] )
    {
        m_entries = [[NSMutableArray arrayWithCapacity:TEXTBUFFERMAXLINES] retain];
        
    }
    return self;
}


-(void)dealloc
{
    [m_entries release]; m_entries = nil;
    [super dealloc];
}


-(UInt32)getCount
{
    return (UInt32)[m_entries count];
}


-(void)addEntry:(NSString *)entry
{
    [m_entries addObject:entry];
    while( [m_entries count] >= TEXTBUFFERMAXLINES )
    {
        [m_entries removeObjectAtIndex:0];
    }
}


// zero-based
-(NSString *)getNthNewestEntry:(UInt32)n
{
    UInt32 count = (UInt32)[m_entries count];
    if( n >= count )
    {
        NSAssert( NO, @"getNthOldestEntry out of range." );
        return nil;
    }
    
    return (NSString *)[m_entries objectAtIndex:(count - n - 1)];
}


-(void)clear
{
    [m_entries removeAllObjects];
}


@end



// DebugPaneBackgroundDrawer ///////////////////////////////////////////////////////


@interface DebugPaneBackgroundDrawer (private)
@end


@implementation DebugPaneBackgroundDrawer

-(id)initWithArgs:(id)args
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


-(void)drawToRect:(CGRect)rect
{
    // TODO: add outer?
   
    static GLbyte innerColorData[] = { 
		0x10, 0x10, 0x10, 0xdd, 
		0x10, 0x10, 0x10, 0xdd, 
		0x10, 0x10, 0x10, 0xee, 
		0x10, 0x10, 0x40, 0xee, 
	};
	
	static float innerQuadVerts[12];

    innerQuadVerts[ 0 ]  = rect.origin.x;
    innerQuadVerts[ 1 ]  = rect.origin.y;
    innerQuadVerts[ 2 ]  = 0.f;
    innerQuadVerts[ 3 ]  = rect.origin.x + rect.size.width;
    innerQuadVerts[ 4 ]  = rect.origin.y;
    innerQuadVerts[ 5 ]  = 0.f;
    innerQuadVerts[ 6 ]  = rect.origin.x;
    innerQuadVerts[ 7 ]  = rect.origin.y + rect.size.height;
    innerQuadVerts[ 8 ]  = 0.f;
    innerQuadVerts[ 9 ]  = rect.origin.x + rect.size.width;
    innerQuadVerts[ 10 ] = rect.origin.y + rect.size.height;
    innerQuadVerts[ 11 ] = 0.f;
    
    glLoadIdentity();
    
    // render the shape in color.
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(3, GL_FLOAT, 0, innerQuadVerts );
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, innerColorData );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4 );
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);

}


@end



// DebugPaneTextDrawerArgsStruct ///////////////////////////////////////////////////////

@implementation DebugPaneTextDrawerArgs

@synthesize fontName, fontSize, numTextColumns, numTextRows;

@end



// DebugPaneTextDrawer /////////////////////////////////////////////////////////////



@interface DebugPaneTextDrawer (private)

-(void)checkFontMetrics;
-(void)initializeTexture;
-(void)releaseTexture;

@end


@implementation DebugPaneTextDrawer

@synthesize oneCharWidth = m_oneCharWidth, oneCharHeight = m_oneCharHeight;



-(id)initWithTextBuffer:(DebugTextBuffer *)buffer args:(DebugPaneTextDrawerArgs *)args
{
    if( self = [super init] )
    {
        m_buffer = [buffer retain];
        m_args = [args retain];
        [self checkFontMetrics];        
        [self initializeTexture];
    }
    return self;
}

-(void)dealloc
{
    [self releaseTexture];
    [m_buffer release]; m_buffer = nil;
    [m_args release]; m_args = nil;
    [super dealloc];
}


-(void)checkFontMetrics
{
    
    //NSArray *availableFamilyNames = [UIFont familyNames];
    //for( int i = 0; i < [availableFamilyNames count]; ++i )
    //{
    //    NSLog( @"available family: %@", (NSString *)[availableFamilyNames objectAtIndex:i] );
    //}
    
    UIFont *myUIFont = [UIFont fontWithName:m_args.fontName size:m_args.fontSize];
    NSAssert( myUIFont != nil, @"Couldn't load requested font name?" );
    NSDictionary *attr = [NSDictionary dictionaryWithObject:myUIFont forKey:NSFontAttributeName];
    CGSize textRect = [@"X" sizeWithAttributes:attr];
    m_oneCharWidth = textRect.width;
    m_oneCharHeight = textRect.height;
    
    NSLog( @"Using font \"%@\" with size %f, oneCharSize is %fx%f.", m_args.fontName, m_args.fontSize, m_oneCharWidth, m_oneCharHeight );
    
}


-(void)drawToRect:(CGRect)rect
{
    
    // TODO: can we make the text texture sharper by disabling any filtering options?
    
    
    static GLbyte quadColorData[] = { 
		0x22, 0xee, 0x22, 0xff, 
		0x22, 0xee, 0x22, 0xff, 
		0x22, 0xee, 0x22, 0xff, 
		0x22, 0xee, 0x22, 0xff, 
	};
	
	static float quadVerts[12];
    
    quadVerts[ 0 ]  = rect.origin.x;
    quadVerts[ 1 ]  = rect.origin.y;
    quadVerts[ 2 ]  = 0.f;
    quadVerts[ 3 ]  = rect.origin.x + rect.size.width;
    quadVerts[ 4 ]  = rect.origin.y;
    quadVerts[ 5 ]  = 0.f;
    quadVerts[ 6 ]  = rect.origin.x;
    quadVerts[ 7 ]  = rect.origin.y + rect.size.height;
    quadVerts[ 8 ]  = 0.f;
    quadVerts[ 9 ]  = rect.origin.x + rect.size.width;
    quadVerts[ 10 ] = rect.origin.y + rect.size.height;
    quadVerts[ 11 ] = 0.f;
    
    // assume we are in modelView matrix mode already.
    glLoadIdentity();
    
	glEnable( GL_TEXTURE_2D );
    glBindTexture( GL_TEXTURE_2D, m_texName );
	
	glTexCoordPointer( 2, GL_FLOAT, 0, m_texCoords );
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    
    glEnableClientState(GL_COLOR_ARRAY);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, quadColorData);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer( 3, GL_FLOAT, 0, quadVerts );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
}


-(void)initializeTexture
{
    m_trueWidth = m_oneCharWidth * m_args.numTextColumns;
    m_trueHeight = m_oneCharHeight * m_args.numTextRows;

    m_paddedWidth = 1;
    while( m_paddedWidth < m_trueWidth )
        m_paddedWidth <<= 1;
    m_paddedHeight = 1;
    while( m_paddedHeight < m_trueHeight )
        m_paddedHeight <<= 1;
    
    size_t bitmapDataLen = m_paddedWidth * m_paddedHeight * 4;
    m_rawBitmapData = (GLubyte *) calloc( bitmapDataLen, sizeof( GLubyte ) );
    NSAssert( m_rawBitmapData, @"Couldn't allocate raw data." );
    memset( m_rawBitmapData, 0, bitmapDataLen * sizeof( GLubyte ) );
    NSLog( @"Allocated %ld bytes for DebugPaneTextDrawer bitmapData of size %dx%d.", bitmapDataLen * sizeof( GLubyte ), m_paddedWidth, m_paddedHeight );
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    m_cgContext = CGBitmapContextCreate( m_rawBitmapData, m_paddedWidth, m_paddedHeight, 8, m_paddedWidth * 4, rgbColorSpace, kCGImageAlphaPremultipliedLast );
    CGColorSpaceRelease( rgbColorSpace );  // assuming the context retains the colorSpace
    NSAssert( m_cgContext, @"Failed to create bitmap context for DebugPaneTextDrawer bitmapData." );
    
    glGenTextures( 1, &m_texName );

}


-(void)releaseTexture
{
    free( m_rawBitmapData ); m_rawBitmapData = NULL;
    CGContextRelease( m_cgContext ); m_cgContext = NULL;
}


-(void)updateRaster
{
    CGContextClearRect( m_cgContext, CGRectMake( 0, 0, m_paddedWidth, m_paddedHeight ) );
	CGContextSetCharacterSpacing( m_cgContext, 1 );
	CGContextSetTextDrawingMode( m_cgContext, kCGTextFill );

    float textR = 1.0f;  // color is applied at render time.
    float textG = 1.0f;
    float textB = 1.0f;
    float textA = 1.0f;
	CGContextSetRGBFillColor( m_cgContext, textR, textG, textB, textA );
	
    // since CG is y-flipped relative to openGL, render the text with a flip transform so we
    //  can draw the texture natively later.
	CGAffineTransform flipTransform = CGAffineTransformMake( 1.0, 0.0, 0.0, -1.0, 0.0, 0.0 );
    CGContextSetTextMatrix( m_cgContext, flipTransform );

    UIGraphicsPushContext(m_cgContext );

    NSDictionary *fontAttr = @{NSFontAttributeName:[UIFont fontWithName:m_args.fontName size:m_args.fontSize]};

    // draw strings in order from oldest at the top, on down.
    float x = 0.f;
    float y = m_oneCharHeight - 2.f;
    
    int maxCount = MIN( m_buffer.count, m_args.numTextRows );
    
    for( int iRow = 0; iRow < m_args.numTextRows; ++iRow )
    {
        if( iRow >= maxCount )
        {
            break;
        }

        int thisIndex = maxCount - iRow - 1;
        [[m_buffer getNthNewestEntry:thisIndex] drawAtPoint:CGPointMake(x, y) withAttributes:fontAttr];
        y += m_oneCharHeight;
    }
    UIGraphicsPopContext();

    // next, upload the texture to openGL
    
    glBindTexture( GL_TEXTURE_2D, m_texName );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );   // FUTURE: ??
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, m_paddedWidth, m_paddedHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, m_rawBitmapData );
    
    // remember tex coords.
    GLfloat x0, x1, y0, y1;
    x0 = 0.f;
    y0 = 1.f - ((GLfloat)m_trueHeight / (GLfloat)m_paddedHeight);
    x1 = (GLfloat)m_trueWidth / (GLfloat)m_paddedWidth;
    y1 = 1.f;
    
    // standard triangle strip coords
    m_texCoords[0] = x0; m_texCoords[1] = y0;
    m_texCoords[2] = x1; m_texCoords[3] = y0;
    m_texCoords[4] = x0; m_texCoords[5] = y1;
    m_texCoords[6] = x1; m_texCoords[7] = y1;
    
}

@end





// DebugLogLayerView ///////////////////////////////////////////////////////////////


// various perf improvements are possible:
// - move the texture up a line and just draw the new one
// x don't update texture yet if currently minimized
// - use a lower BPP for the texture, like a lightmap for example



@interface DebugLogLayerView (private)

+(CGRect)applyPaddingToRect:(CGRect)rect;

@end


@implementation DebugLogLayerView

static DebugLogLayerView *g_anyInstance = nil;

-(id)init
{
    if( self = [super init] )
    {
        m_textBuffer = [[DebugTextBuffer alloc] init];

        m_backgroundDrawer = [[DebugPaneBackgroundDrawer alloc] initWithArgs:nil];  // TODO args
        
        DebugPaneTextDrawerArgs *textDrawerArgs = [[DebugPaneTextDrawerArgs alloc] init];
        textDrawerArgs.fontName = @"Courier";
        textDrawerArgs.fontSize = 12.f;
        textDrawerArgs.numTextColumns = 80;
        textDrawerArgs.numTextRows = 21;
        m_textDrawer = [[DebugPaneTextDrawer alloc] initWithTextBuffer:m_textBuffer args:textDrawerArgs];

        float w = textDrawerArgs.numTextColumns * m_textDrawer.oneCharWidth;
        float h = textDrawerArgs.numTextRows * m_textDrawer.oneCharHeight;
        [textDrawerArgs release]; 
        
#ifdef DEBUG_VIEW_STARTS_FULLSIZE
        m_fullSize = YES;
#else
        m_fullSize = NO;
#endif
        m_fullSizeRect = CGRectMake( 50.f, 50.f, w, h );
        m_minSizeRect = CGRectMake( 50.f, 50.f, w / 10.f, h / 10.f );
        
        m_hitZone = [[RectHitZone alloc] initWithRect:m_minSizeRect];
        
        [m_textDrawer updateRaster];

        g_anyInstance = self;
    }
    return self;
}

-(void)dealloc
{
    [m_hitZone release]; m_hitZone = nil;
    [m_textDrawer release]; m_textDrawer = nil;
    [m_backgroundDrawer release]; m_backgroundDrawer = nil;
    [m_textBuffer release]; m_textBuffer = nil;
    [super dealloc];
}


+(DebugLogLayerView *)anyInstance
{
    return g_anyInstance;
}


// override
-(void)buildScene
{
    
    [self setupStandardOrthoView];
    
    if( m_fullSize )
    {
        [m_backgroundDrawer drawToRect: [DebugLogLayerView applyPaddingToRect:m_fullSizeRect] ];
        [m_textDrawer drawToRect:m_fullSizeRect];
    }
    else
    {
        [m_backgroundDrawer drawToRect: [DebugLogLayerView applyPaddingToRect:m_minSizeRect] ];
        [m_textDrawer drawToRect:m_minSizeRect];
    }
    
    
}


// override
-(void)updateWithTimeDelta:(float)timeDelta
{
}


-(void)writeLine:(NSString *)str
{
#ifdef ECHO_TO_CONSOLE
    NSLog( @"%@", str );  // get a warning without this silly syntax...?
#endif
    [m_textBuffer addEntry:str];
    
    // only update the texture if it is currently maximized.
    if( m_fullSize )
    {
        [m_textDrawer updateRaster];
    }
}


-(void)receivedTouchAt:(CGPoint)p
{
    if( ![m_hitZone containsPoint:p] )
        return;
    
    m_fullSize = !m_fullSize;
    if( m_fullSize )
    {
        // make sure our texture is fresh for fullSize mode.
        [m_textDrawer updateRaster];
    }
}


+(CGRect)applyPaddingToRect:(CGRect)rect
{
    const int paddingPixels = 2;
    return CGRectMake( rect.origin.x - paddingPixels,
                       rect.origin.y - paddingPixels,
                       rect.size.width + 2 * paddingPixels,
                       rect.size.height + 2 * paddingPixels
                      );
}



@end
