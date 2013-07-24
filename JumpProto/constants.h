/*
 *  constants.h
 *
 *  Created by gideong on DATE.
 *  Copyright GoodGuyApps.com 2010. All rights reserved.
 *
 */

#import <limits.h>


#define GGA_APP_VERSION						@"0"

#define ANIMATION_FRAME_INTERVAL (1)

#define STOPWATCH_REPORT

//#define LOG_FRAMES

#define TIME_BETWEEN_WORLDUPDATE_SPEED_REPORTS (10.f)

// avoid initial frame jitter by burning through a few frames without updating anything.
#define BURN_FRAMES_ON_WORLD_RESET (5)

//#define DEBUG_VIEW_STARTS_FULLSIZE


//////////////////////////////////////////////////////////////////////////////////////////////////////////////// Emu, Fl transforms

// TODO: would be nice to have a more generalized coordinate transform object. how do you handle the "type transform" aspect?

// defines the size of the grid. this is the basic unit in level editing, so it's the world yardstick.
// the ratio between the Fl and Emu values here defines the overall transform between those spaces.
//  - the Emu version MUST be a power of 2.
#define GRID_SIZE_Fl  (48.f)
#define GRID_SIZE_Emu (256)

#define FlToEmu(x)  ( (Emu)   ( (x) * GRID_SIZE_Emu / GRID_SIZE_Fl  ) )
#define EmuToFl(x)  ( (float) ( (x) * GRID_SIZE_Fl  / GRID_SIZE_Emu ) )



//////////////////////////////////////////////////////////////////////////////////////////////////////////////// BlockUpdater stuff

#define WORLD_MIN_X (INT_MIN)
#define WORLD_MIN_Y (INT_MIN)
#define WORLD_MAX_X (INT_MAX)
#define WORLD_MAX_Y (INT_MAX)

// FlToEmu == 5.333

#define TERMINAL_VELOCITY ( -20000 )
#define GRAVITY_CONSTANT ( -44000 )

// note: this value comes in to play as a downward velocity at idle. This is important
//       because this * typical_frame_time_delta must be >= 1, else it will round to 
//       zero and we won't trigger gap checker logic.
#define VELOCITY_MIN ( 64 )

#define GROUND_FRICTION_DECEL ( 52000 )
#define AIR_FRICTION_DECEL    ( 32000 )

#define PLAYERINPUT_LR_MAX_V ( 7040 )
#define PLAYERINPUT_LR_ACCEL ( 140000 )

#define PLAYERINPUT_JUMP_MAX_V ( 8800 )
#define MAX_JUMP_DURATION ( 0.37f )

#define NUM_JUMPS_ALLOWED ( 2 )

#define ONE_BLOCK_SIZE_Emu GRID_SIZE_Emu
#define ONE_BLOCK_SIZE_Fl  GRID_SIZE_Fl

#define PLAYER_WIDTH  (4 * ONE_BLOCK_SIZE_Emu)
#define PLAYER_HEIGHT (8 * ONE_BLOCK_SIZE_Emu)

#define PLAYER_NOTBORNYET_TIME (0.005f)
#define PLAYER_BEINGBORN_TIME (0.5f)
#define PLAYER_DYING_TIME (1.25f)
#define PLAYER_WINNING_TIME (1.f)

#define VIEW_STANDARD_ZOOM (5.f)
#define PLAYER_BEINGBORN_ZOOMOUT_MIN    VIEW_STANDARD_ZOOM
#define PLAYER_BEINGBORN_ZOOMOUT_MAX   (VIEW_STANDARD_ZOOM * 1.9f)

// shared badguy values
#define BADGUY_NOTBORNYET_TIME (0.f)
#define BADGUY_BEINGBORN_TIME (0.f)
#define BADGUY_DYING_TIME (0.75f)
#define BADGUY_JUMP_MAX_V (22400)

// testMeanieB values
#define TESTMEANIEB_LR_ACCEL (80000)
#define TESTMEANIEB_LR_MAX_V (4000)

// facebone values
#define FACEBONE_CHILLTIME (0.6f)
#define FACEBONE_FAKEOUT_CHANCE (0.3f)
#define FACEBONE_PREJUMP_TIME (0.25f)
#define FACEBONE_JUMPTIME (MAX_JUMP_DURATION * 2.f)
#define BADGUY_MAX_JUMP_DURATION (MAX_JUMP_DURATION);

// crumbles1 values
#define CRUMBLES1_CRUMBLETIME  (0.45f)
#define CRUMBLES1_GONETIME     (2.75f)
#define CRUMBLES1_REAPPEARTIME (0.20f)

#define SPRING_VY (30000)

#define PLAYER_DEAD_GIB_COUNT  (8)
#define PLAYER_DEAD_GIB_V      (44000)

// misc world physics/prop values
#define MOVING_PLATFORM_RIGHT_MEDIUM_VX ( 2560 )
#define CONVEYOR_VX                     ( 3800 )
