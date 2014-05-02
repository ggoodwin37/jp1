//
//  EExtentView.h
//

#import "EExtentView.h"
//#import "AspectController.h"
//#import "CGPointW.h"
#import "gutil.h"
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


-(void)drawPegLineFrom:(CGPoint)pFrom to:(CGPoint)pTo inContext:(CGContextRef)context
{
    CGContextMoveToPoint( context, pFrom.x, pFrom.y );
    CGContextAddLineToPoint( context, pTo.x, pTo.y );
    CGContextStrokePath( context );

    float theta;
    if( pTo.x != pFrom.x )
    {
        theta = atanf( (pTo.y - pFrom.y) / (pTo.x - pFrom.x) );
    } else {
        theta = (pFrom.y < pTo.y) ? (M_PI / 2) : (-M_PI / 2);
    }
    float pegLenHalf = 10.f;  // doesn't scale with screen zoom
    float dx = pegLenHalf * sinf( theta );  // cos(90-theta) == sin(theta)
    float dy = pegLenHalf * cosf( theta );  // sin(90-theta) == cos(theta)
    CGPoint pegStart = CGPointMake( pTo.x + dx, pTo.y - dy );
    CGPoint pegEnd = CGPointMake( pTo.x - dx, pTo.y + dy );
    CGContextMoveToPoint( context, pegStart.x, pegStart.y );
    CGContextAddLineToPoint( context, pegEnd.x, pegEnd.y );
    CGContextStrokePath( context );
}


-(void)drawJumpRangeInContext:(CGContextRef)context
{
    float cx = self.viewportSize.width / 2;
    float cy = self.viewportSize.height / 2;
    CGPoint center = CGPointMake( cx, cy );
    CGContextSetLineWidth( context, 4 );
    CGContextSetRGBStrokeColor( context, 0.9f, 0.2f, 1.f, 0.6f );

    float bSize = worldToView( 4 * ONE_BLOCK_SIZE_Fl, 0.f, m_worldSize.width, self.viewportSize.width );

    // TODO: tune all these values

    // 1 is single jump, 2 is double jump
    // a is straight up, b is max up plus forward, c is max forward
    float dx1a = 0.f;
    float dx2a = 0.f;
    float dy1a = 6.f * bSize;
    float dy2a = 12.f * bSize;
    [self drawPegLineFrom:center to:CGPointMake(cx + dx1a, cy - dy1a) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx + dx2a, cy - dy2a) inContext:context];

    float dx1b = 8.f * bSize;
    float dx2b = 16.f * bSize;
    float dy1b = 6.f * bSize;
    float dy2b = 12.f * bSize;
    [self drawPegLineFrom:center to:CGPointMake(cx + dx1b, cy - dy1b) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx + dx2b, cy - dy2b) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx - dx1b, cy - dy1b) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx - dx2b, cy - dy2b) inContext:context];

    float dx1c = 8.f * bSize;
    float dx2c = 16.f * bSize;
    float dy1c = 0.f * bSize;
    float dy2c = 0.f * bSize;
    [self drawPegLineFrom:center to:CGPointMake(cx + dx1c, cy - dy1c) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx + dx2c, cy - dy2c) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx - dx1c, cy - dy1c) inContext:context];
    [self drawPegLineFrom:center to:CGPointMake(cx - dx2c, cy - dy2c) inContext:context];
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
