//
//  RectCoordBuffer
//  JumpProto
//
//  Created by Gideon iOS on 7/17/13.
//
//

#import "RectCoordBuffer.h"

@interface RectCoordBuffer (private)
@end


@implementation RectCoordBuffer

-(id)initWithTexEnabled:(BOOL)texEnabled
{
    if( self = [super init])
    {
        // TODO: tune this value down if possible
        m_capacity = 30 * 20 * 2;  // guess at typical screen size (in sprites) is 30 * 20, times fudge factor.
        m_currentFrame = 0;
        m_setTexNameYet = NO;
        m_currentTexName = 0;
        m_didBindTexYet = NO;
        m_boundTexName = 0;
        
        m_texEnabled = texEnabled;

        size_t geoCoordBufSize = m_capacity * GEO_COORD_VAL_PER_FRAME * sizeof(GLfloat);
        m_geoCoordBuf = (GLfloat *)malloc( geoCoordBufSize );
        NSAssert( m_geoCoordBuf, @"Assume we can allocate geometry coordinate cache." );

        // so z components can remain at 0
        for( size_t i = 0; i < m_capacity * GEO_COORD_VAL_PER_FRAME; ++i )
        {
            m_geoCoordBuf[i] = 0.f;
        }

        if( m_texEnabled )
        {
            size_t texCoordBufSize = m_capacity * TEX_COORD_VAL_PER_FRAME * sizeof(GLfloat);
            m_texCoordBuf = (GLfloat *)malloc( texCoordBufSize );
            NSAssert( m_texCoordBuf, @"Assume we can allocate texture coordinate cache." );
        }
        else m_texCoordBuf = nil;
            
        size_t colorBufSize = m_capacity * COLOR_VAL_PER_FRAME * sizeof(GLbyte);
        m_colorBuf = (GLbyte *)malloc( colorBufSize );
        NSAssert( m_colorBuf, @"Assume we can allocate color cache." );

        // pre-fill color buff with 0xff so clients can forget about it if they don't care
        memset( m_colorBuf, 0xff, colorBufSize );
        
#ifdef LOG_COORDBUFFER
        NSLog( @"RectCoordBuffer init: capacity=%d  sizes: geobuf: %lu texbuf: %lu colorBuf: %lu",
               m_capacity, geoCoordBufSize, texCoordBufSize, colorBufSize );
#endif
    }
    return self;
}


-(void)dealloc
{
#ifdef LOG_COORDBUFFER
    NSLog( @"RectCoordBuffer dealloc" );
#endif
    free( m_colorBuf ); m_colorBuf = NULL;
    free( m_texCoordBuf ); m_texCoordBuf = NULL;
    free( m_geoCoordBuf ); m_geoCoordBuf = NULL;

    [super dealloc];
}


-(void)pushRectGeoCoord2dX1:(GLfloat)x1 Y1:(GLfloat)y1 X2:(GLfloat)x2 Y2:(GLfloat)y2
{
    const int offs = m_currentFrame * GEO_COORD_VAL_PER_FRAME;
    GLfloat *targetPtr = m_geoCoordBuf + offs;

    // arranged for GL_TRIANGLES mode
    targetPtr [0]  = x1;
    targetPtr [1]  = y1;
    targetPtr [3]  = x2;
    targetPtr [4]  = y1;
    targetPtr [6]  = x1;
    targetPtr [7]  = y2;

    targetPtr [9]  = x1;
    targetPtr [10] = y2;
    targetPtr [12] = x2;
    targetPtr [13] = y1;
    targetPtr [15] = x2;
    targetPtr [16] = y2;
}


-(void)pushRectTexCoord2dBuf:(GLfloat *)buf
{
    NSAssert( m_texEnabled, @"You should only set texCoords when in texMode." );
    const int offs = m_currentFrame * TEX_COORD_VAL_PER_FRAME;
    GLfloat *targetPtr = m_texCoordBuf + offs;
    const size_t numBytes = TEX_COORD_VAL_PER_FRAME * sizeof( GLfloat );
    memcpy( targetPtr, buf, numBytes );
}


-(void)pushRectColors2dBuf:(GLbyte *)buf
{
    const int offs = m_currentFrame * COLOR_VAL_PER_FRAME;
    GLbyte *targetPtr = m_colorBuf + offs;
    const size_t numBytes = COLOR_VAL_PER_FRAME * sizeof( GLbyte );
    memcpy( targetPtr, buf, numBytes );
}


-(void)setTexName:(GLuint)name
{
    NSAssert( m_texEnabled, @"You should only set texName when in texMode." );
    if( !m_setTexNameYet )
    {
        m_currentTexName = name;
        m_setTexNameYet = YES;
        return;
    }
    
    if( name != m_currentTexName )
    {
        // FUTURE: consider having one bufferset per tex name, so we can do optimal flushes
        //         even with multiple textures (this implies depth buffer is being used
        //         since it will change relative draw order).
        // for now, we'll just have to flush every time this changes.
#ifdef LOG_COORDBUFFER
        NSLog( @"RectCoordBuffer::setTexName: tex name changing, forcing a flush." );
#endif
        [self flush];
        m_currentTexName = name;
    }
}


-(void)incPtr
{
    ++m_currentFrame;
    
    if( m_currentFrame >= m_capacity )
    {
#ifdef LOG_COORDBUFFER
        NSLog( @"RectCoordBuffer::incPtr: full, auto-flushing." );
#endif
        [self flush];
    }
}


-(void)flush
{
    if( m_currentFrame == 0 )
    {
#ifdef LOG_COORDBUFFER
        NSLog( @"RectCoordBuffer::flush: nothing to flush." );
#endif
        return;
    }
    
    glVertexPointer( 3, GL_FLOAT, 0, m_geoCoordBuf );
    glColorPointer( 4, GL_UNSIGNED_BYTE, 0, m_colorBuf );
    
    if( m_texEnabled )
    {
        BOOL needToBind = NO;
        if( !m_didBindTexYet || m_boundTexName != m_currentTexName )
        {
            needToBind = YES;
        }
        if( needToBind )
        {
            glBindTexture( GL_TEXTURE_2D, m_currentTexName );
            m_boundTexName = m_currentTexName;
            m_didBindTexYet = YES;
        }
        glTexCoordPointer( 2, GL_FLOAT, 0, m_texCoordBuf );
    }

    glLoadIdentity();
    
    const size_t numIndicesToDraw = 6 * m_currentFrame;  // 2 triangles per frame
    glDrawArrays( GL_TRIANGLES, 0, numIndicesToDraw );

    m_currentFrame = 0;
}

@end
