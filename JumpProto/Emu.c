//
//  Emu.c
//  JumpProto
//
//  Created by Gideon Goodwin on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include "Emu.h"


EmuPoint EmuPointMake( Emu x, Emu y )
{
    EmuPoint r;
    r.x = x;
    r.y = y;
    return r;
}


EmuSize EmuSizeMake( Emu width, Emu height )
{
    EmuSize r;
    r.width = width;
    r.height = height;
    return r;
}


EmuRect EmuRectMake( Emu x, Emu y, Emu width, Emu height )
{
    EmuRect r;
    r.origin = EmuPointMake( x, y );
    r.size = EmuSizeMake( width, height );
    return r;
}


void LogEmuUnitTests()
{
    // isn't there an NSFoo for this?
    
    printf( "Test printf" );
    printf( "TODO: LogEmuUnitTests" );
    
}
