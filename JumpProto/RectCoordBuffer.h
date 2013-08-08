//
//  RectCoordBuffer.h
//  JumpProto
//
//  Created by Gideon iOS on 7/17/13.
//
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

// TODO: aside: what's the best practice for class constants in Obj-C?
#define GEO_COORD_VAL_PER_FRAME  (3 * 6)
#define TEX_COORD_VAL_PER_FRAME  (2 * 6)
#define COLOR_VAL_PER_FRAME      (4 * 6)

@interface RectCoordBuffer : NSObject {
    int m_currentFrame;
    int m_capacity;             // in frames
    
    GLfloat *m_geoCoordBuf;
    GLfloat *m_texCoordBuf;
    GLbyte *m_colorBuf;
    
    GLuint m_currentTexName;
    BOOL m_setTexNameYet;
    GLuint m_boundTexName;
    BOOL m_didBindTexYet;
    
    BOOL m_texEnabled;
}

-(id)initWithTexEnabled:(BOOL)texEnabled;

// these methods assume GL_TRIANGLES scheme
-(void)pushRectGeoCoord2dX1:(GLfloat)x1 Y1:(GLfloat)y1 X2:(GLfloat)x2 Y2:(GLfloat)y2;  // actually results in 18 floats
-(void)pushRectTexCoord2dBuf:(GLfloat *)buf;  // 12 floats
-(void)pushRectColors2dBuf:(GLbyte *)buf;     // 4 bytes * 6 points = 24 bytes
-(void)setTexName:(GLuint)name;               // will flush if changing
-(void)incPtr;
-(void)flush;

//#define LOG_COORDBUFFER

@end
