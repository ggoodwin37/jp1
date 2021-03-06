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
// TODO: is this for real?
#define BURN_FRAMES_ON_WORLD_RESET (5)

//#define DEBUG_VIEW_STARTS_FULLSIZE

//#define AUTOLOAD_FIRST_LEVEL


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

// edit view doesn't do negative values :( so start at a large offset to allow levels to go left/up if needed.
//  when play mode loads a level, blocks will all be normalized anyway.
#define EDITVIEW_START_OFFSET (GRID_SIZE_Fl * 4 * 10000.f)

// FlToEmu == 5.333

#define TERMINAL_VELOCITY ( -20000 )
#define GRAVITY_CONSTANT ( -44000 )

#define TERMINAL_VELOCITY_WALLJUMP ( -5000 )

// TODO: still relevant?
// note: this value comes in to play as a downward velocity at idle. This is important
//       because this * typical_frame_time_delta must be >= 1, else it will round to 
//       zero and we won't trigger gap checker logic.
#define VELOCITY_MIN ( 64 )

#define GROUND_FRICTION_DECEL ( 42000 )
#define AIR_FRICTION_DECEL    ( 20000 )

#define PLAYERINPUT_LR_MAX_V ( 7040 )
#define PLAYERINPUT_LR_ACCEL ( 140000 )

#define PLAYERINPUT_JUMP_MAX_V ( 8800 )
#define MAX_JUMP_DURATION ( 0.37f )

#define NUM_JUMPS_ALLOWED ( 2 )

#define ONE_BLOCK_SIZE_Emu GRID_SIZE_Emu
#define ONE_BLOCK_SIZE_Fl  GRID_SIZE_Fl

#define PLAYER_WIDTH  (4 * ONE_BLOCK_SIZE_Emu)
#define PLAYER_HEIGHT (8 * ONE_BLOCK_SIZE_Emu)
#define PLAYER_WIDTH_FL  (4 * ONE_BLOCK_SIZE_Fl)
#define PLAYER_HEIGHT_FL (8 * ONE_BLOCK_SIZE_Fl)

#define PLAYER_NOTBORNYET_TIME (0.005f)
#define PLAYER_BEINGBORN_TIME (0.5f)
#define PLAYER_DYING_TIME (1.6f)
#define PLAYER_WINNING_TIME (1.f)

#define PLAYER_DEAD_GIB_COUNT  (15)
#define PLAYER_DEAD_GIB_V      (42000)
#define GIB_ACCEL              (10000000)

// zoom factor is calculated based on tuned value of 4 at 768px height.
#define VIEW_STANDARD_ZOOM (4.f)
#define VIEW_STANDARD_HEIGHT (768.f)
#define PLAYER_BEINGBORN_ZOOMOUT_MAX_FACTOR   (1.9f)

// shared badguy values
#define BADGUY_NOTBORNYET_TIME (0.f)
#define BADGUY_BEINGBORN_TIME  (0.f)
#define BADGUY_DYING_TIME      (0.75f)
#define BADGUY_JUMP_MAX_V      (22400)

// testMeanieB values
#define TESTMEANIEB_LR_ACCEL (80000)
#define TESTMEANIEB_LR_MAX_V (4000)

// facebone values
#define FACEBONE_CHILLTIME       (0.6f)
#define FACEBONE_FAKEOUT_CHANCE  (0.3f)
#define FACEBONE_PREJUMP_TIME    (0.25f)
#define FACEBONE_JUMPTIME        (MAX_JUMP_DURATION * 2.f)
#define BADGUY_MAX_JUMP_DURATION (MAX_JUMP_DURATION);

// hop values
#define GENERIC_HOP_JUMP_MAX_V          (8000)
#define GENERIC_HOP_MAX_JUMP_DURATION   (0.05f)

// crumbles1 values
#define CRUMBLES1_CRUMBLETIME  (0.45f)
#define CRUMBLES1_GONETIME     (2.75f)
#define CRUMBLES1_REAPPEARTIME (0.20f)

// tinyAutoLift values
#define TINYAUTOLIFT_TRIGTIME  (0.20f)
#define TINYAUTOLIFT_GOING_V   (15000)
#define TINYAUTOLIFT_COMING_V  (-5000)
#define TINYAUTOLIFT_ACCEL     (40000)
#define TINYAUTOLIFT_RESETTIME (0.10f)

// tiny-fuzz values
#define TINYFUZZ_LR_ACCEL (40000)
#define TINYFUZZ_LR_MAX_V (2500)

// tiny-jelly values
#define TINYJELLY_V (2200)

#define SPRING_VY (30000)

// misc world physics/prop values
#define MOVING_PLATFORM_RIGHT_MEDIUM_VX ( 2560 )
#define CONVEYOR_VX                     ( 3800 )
#define PULL_DOWN_THRESHOLD             ( -380 )
// TODO: remove
#define TEST_EVENT_V                          ( 19000 )

// weight
#define DEFAULT_WEIGHT         (2)
#define PLAYER_WEIGHT          (10)
#define GIB_WEIGHT             (1)
#define BADGUY_WEIGHT          (PLAYER_WEIGHT)
#define CRATE_WEIGHT           (PLAYER_WEIGHT)
#define PLATFORM_WEIGHT        (20)
#define IMMOVABLE_WEIGHT       (99)
#define BUTTON_TRIGGER_WEIGHT  (46)
#define BUTTON_STOPPER_WEIGHT  (47)

// b-mode time dilation
#define B_MODE_TIME_DILATION_FACTOR (0.1f)

// how big is the screen for typical zooms (used to show screen extent in edit mode)
#define EEXTENT_IPAD_BLOCK_WIDTH      (22 * 4)
#define EEXTENT_IPAD_BLOCK_HEIGHT     (16 * 4)
#define EEXTENT_IPHONE_BLOCK_WIDTH    (29 * 4)
#define EEXTENT_IPHONE_BLOCK_HEIGHT   (16 * 4)
