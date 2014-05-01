//
//  EExtentView.h
//

#import "EExtentView.h"
//#import "AspectController.h"
//#import "CGPointW.h"
//#import "gutil.h"
//#import "constants.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EExtentView.h
@interface EExtentView (private)
@end


@implementation EExtentView

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

-(void)drawInContext:(CGContextRef)context
{
    [super drawInContext:context];
    // TODO
}


// IPanZoomResultConsumer
-(void)onZoomByFactor:(float)factor centeredOnViewPoint:(CGPoint)centerPointView
{
    // TODO
    [self setNeedsDisplay];
}


-(void)onPanByViewUnits:(CGPoint)vector
{
    // this view doesn't care about pan
}


@end
