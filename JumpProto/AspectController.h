//
//  AspectController.h
//  Created by gideong on DATE.
//  Copyright GoodGuyApps.com 2010. All rights reserved.

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


@interface AspectController : NSObject {
@private
	float			m_xAspect;
	float			m_yAspect;
	
	GLint			m_xPixel;
	GLint			m_yPixel;

	float m_pixelAspectConversionFactor;				// Used to convert from/to screen coords. May have to adjust Y axis.

}


@property(nonatomic,readonly) float xAspect, yAspect, pixelAspectConversionFactor;
@property(nonatomic,readonly) GLint xPixel, yPixel;

// flipCoords: depending on relative orientation of view to device and the calling view's properties, the rect may be flipped
//   compared to what we expect.
+(void)initGlobalInstanceWithRect:(CGRect)rect flipCoords:(BOOL)flipCoords;

+(AspectController *)instance;
+(void)releaseGlobalInstance;



@end
