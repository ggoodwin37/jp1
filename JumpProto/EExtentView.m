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

@synthesize currentZoomFactor;

-(id)initWithCoder:(NSCoder *)aDecoder
{
	if( self = [super initWithCoder:aDecoder] )
	{
        self.currentZoomFactor = 1.f;
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
    NSLog( @"extent view drawing" );
    // TODO
}


// IPanZoomResultConsumer
-(void)onZoomByFactor:(float)factor centeredOnViewPoint:(CGPoint)centerPointView
{
    self.currentZoomFactor = factor;
    NSLog( @"zoomed to: %f", factor );
    [self setNeedsDisplay];
}


-(void)onPanByViewUnits:(CGPoint)vector
{
    // this view doesn't care about pan
}


@end
