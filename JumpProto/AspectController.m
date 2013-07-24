//
//  AspectController.m
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import "AspectController.h"

@interface AspectController (private)
-(id)initWithRect:(CGRect)rect;

@end


@implementation AspectController

@synthesize xAspect = m_xAspect, yAspect = m_yAspect, xPixel = m_xPixel, yPixel = m_yPixel, pixelAspectConversionFactor = m_pixelAspectConversionFactor;

static AspectController *aspectControllerGlobalInstance = nil;


-(id)initWithRect:(CGRect)rect flipCoords:(BOOL)flipCoords
{
	if( self = [super init] )
	{
        CGSize d;
        if( flipCoords )
        {
            d = CGSizeMake( rect.size.height, rect.size.width );
        }
        else
        {
            d = rect.size;
        }
		m_xAspect = d.width / d.height;
		m_yAspect = 1;
		
		m_xPixel = (GLint)d.width;
		m_yPixel = (GLint)d.height;
		
		m_pixelAspectConversionFactor = m_xAspect / (float)m_xPixel;

	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
}


+(void)initGlobalInstanceWithRect:(CGRect)rect flipCoords:(BOOL)flipCoords;
{
    NSAssert( aspectControllerGlobalInstance == nil, @"YOU FOOL! HOW CAN YOU INITIALIZE A SINGLETON TWICE??!?!???!? YOU MUST BE ESPECIALLY STUPID." );
	aspectControllerGlobalInstance = [[AspectController alloc] initWithRect:rect flipCoords:flipCoords];
}


+(AspectController *)instance
{
	return aspectControllerGlobalInstance;
}


+(void)releaseGlobalInstance
{
	[aspectControllerGlobalInstance release]; aspectControllerGlobalInstance = nil;
}



@end
