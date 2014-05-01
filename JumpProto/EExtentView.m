//
//  EExtentView.h
//

#import "EExtentView.h"
//#import "AspectController.h"
//#import "CGPointW.h"
//#import "gutil.h"
#import "constants.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EExtentView.h
@interface EExtentView (private)
@end


@implementation EExtentView

@synthesize worldViewSize;
@synthesize viewportSize;

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if( self = [super initWithCoder:aDecoder] )
	{
	}
	return self;
}


-(void)dealloc
{
    [super dealloc];
}


-(void)drawPlayerBoxInContext:(CGContextRef)context
{
    float w = worldToView( PLAYER_WIDTH_FL, 0.f, m_worldSize.width, self.viewportSize.width );
    float h = worldToView( PLAYER_HEIGHT_FL, 0.f, m_worldSize.height, self.viewportSize.height );
    float x = (self.viewportSize.width - w) / 2;
    float y = (self.viewportSize.height - h) / 2;
    CGContextSetRGBStrokeColor( context, 1.f, 0.f, 0.f, 0.8f );
    CGContextSetLineWidth( context, 2 );
    CGContextAddRect( context, CGRectMake( x, y, w, h ) );
    CGContextStrokePath( context );
}


-(void)drawJumpRangeInContext:(CGContextRef)context
{
//    CGContextMoveToPoint( context, 0.f, v );
//    CGContextAddLineToPoint( context, self.frame.size.width, v );
//    CGContextStrokePath(context);
}


-(void)drawScreenExtentInContext:(CGContextRef)context
{
    // there's probably a better way to do this but I'm sleepy.
    // draw two corresponding to iphone and ipad
    float w1 = worldToView( EEXTENT_IPAD_BLOCK_WIDTH * ONE_BLOCK_SIZE_Fl, 0.f, m_worldSize.width, self.viewportSize.width );
    float h1 = worldToView( EEXTENT_IPAD_BLOCK_HEIGHT * ONE_BLOCK_SIZE_Fl, 0.f, m_worldSize.height, self.viewportSize.height );
    float x1 = (self.viewportSize.width - w1) / 2;
    float y1 = (self.viewportSize.height - h1) / 2;
    CGContextSetRGBStrokeColor( context, 0.f, 0.8f, 0.8f, 0.8f );
    CGContextSetLineWidth( context, 2 );
    CGContextAddRect( context, CGRectMake( x1, y1, w1, h1 ) );
    CGContextStrokePath( context );
    float w2 = worldToView( EEXTENT_IPHONE_BLOCK_WIDTH * ONE_BLOCK_SIZE_Fl, 0.f, m_worldSize.width, self.viewportSize.width );
    float h2 = worldToView( EEXTENT_IPHONE_BLOCK_HEIGHT * ONE_BLOCK_SIZE_Fl, 0.f, m_worldSize.height, self.viewportSize.height );
    float x2 = (self.viewportSize.width - w2) / 2;
    float y2 = (self.viewportSize.height - h2) / 2;
    CGContextAddRect( context, CGRectMake( x2, y2, w2, h2 ) );
    CGContextStrokePath( context );
}


-(void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    [self drawPlayerBoxInContext:context];
    [self drawJumpRangeInContext:context];
    [self drawScreenExtentInContext:context];
}


-(void)setWorldViewSize:(CGSize)size
{
    m_worldSize = size;
    [self setNeedsDisplay];
}


@end
