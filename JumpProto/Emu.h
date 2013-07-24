//
//  Emu.h
//  JumpProto
//
//  Emus are an integer coordinate system that I am trying to
//     use to eliminate floating-point error issues that plague the World logic.
//
//  Created by Gideon Goodwin on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef JumpProto_Emu_h
#define JumpProto_Emu_h

#import "constants.h"


//////////////////////////////////////////////////////////////////////////////////////////////// Emu stuff

typedef int Emu;

typedef struct
{
    Emu x;
    Emu y;
} EmuPoint;

typedef struct
{
    Emu width;
    Emu height;
} EmuSize;

typedef struct
{
    EmuPoint origin;
    EmuSize size;
} EmuRect;

EmuPoint EmuPointMake( Emu x, Emu y );
EmuSize  EmuSizeMake( Emu width, Emu height );
EmuRect  EmuRectMake( Emu x, Emu y, Emu width, Emu height );
void LogEmuUnitTests();

// fl -> em
#define EmuPointMakeFromFl(x,y)     EmuPointMake( FlToEmu(x), FlToEmu(y) )
#define EmuSizeMakeFromFl(w,h)      EmuSizeMake ( FlToEmu(w), FlToEmu(h) )
#define EmuRectMakeFromFl(x,y,w,h)  EmuRectMake ( FlToEmu(x), FlToEmu(y), FlToEmu(w), FlToEmu(h) )

#define EmuRectFromFlRect(fr)       EmuRectMakeFromFl( fr.origin.x, fr.origin.y, fr.size.width, fr.size.height )
#define EmuPointFromFlPoint(point)  EmuPointMakeFromFl( point.x, point.y )

// em -> fl

#define FlRectMakeFromEmu(x,y,w,h)  CGRectMake ( EmuToFl(x), EmuToFl(y), EmuToFl(w), EmuToFl(h) )

#define FlRectFromEmuRect(em)       FlRectMakeFromEmu( em.origin.x, em.origin.y, em.size.width, em.size.height )
#define FlPointFromEmuPoint(point)  CGPointMake( EmuToFl(point.x), EmuToFl(point.y) )


// gridline stuff.
//  if input is a gridline, result should be the same value.

#define EmuIsGridLine(val)   ( (val) == ((val) & (GRID_SIZE_Emu - 1)) )

// if input is already a gridline, this will return the same one.
#define EmuPrevGridLine(val) ( (val) -  ((val) & (GRID_SIZE_Emu - 1)) )

// if input is already a gridline, return same, else return next one higher.
#define EmuNextGridLine(val) ( EmuIsGridLine(val) ? (val) : (EmuPrevGridLine(val) + GRID_SIZE_Emu) )


#endif
