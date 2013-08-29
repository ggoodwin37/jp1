//
//  EBlockPreset.h
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

/////////////////////////////////////////////////////////////////////////////////////////////////////////// EBlockPreset

// note: Don't change the order of these or insert new ones before end. These get serialized.
enum EBlockPresetEnum
{
    EBlockPreset_None = 0,
    
    // batch 1: early test assets (24x24)
    EBlockPreset_Test0,
    EBlockPreset_PlayerStart,
    EBlockPreset_MovingPlatformRightMedium,
    EBlockPreset_TestCrate,
    
    EBlockPreset_GroundColumn,
    EBlockPreset_OneWayU,
    EBlockPreset_OneWayL,
    EBlockPreset_OneWayR,
    EBlockPreset_OneWayD,
    EBlockPreset_PropSpikes,
    EBlockPreset_PropSkull,
    EBlockPreset_PropGoal,
    EBlockPreset_GroundBrickAVTest,
    EBlockPreset_PropFancyCrate,
    
    EBlockPreset_ConveyorL,
    EBlockPreset_ConveyorR,
    
    EBlockPreset_BLTurf,
    
    EBlockPreset_TestGroupA,
    EBlockPreset_TestGroupB,
    
    EBlockPreset_SillyEm0,
    EBlockPreset_SillyMax0,
    
    EBlockPreset_TestMeanieB,
    
    EBlockPreset_FaceBone,
    EBlockPreset_MineFloat,
    EBlockPreset_MineCrate,
    
    EBlockPreset_GroundRusty,
    EBlockPreset_GroundWood,
    EBlockPreset_GroundQuilt,
    EBlockPreset_PropSpring,
    
    EBlockPreset_Crumbles1,
    
    EBlockPreset_WoodCrate,
    EBlockPreset_Algae,
    EBlockPreset_Qik,
    EBlockPreset_RedBrick,
    EBlockPreset_Lavender,
    
    // batch 2: slightly less early test assets, "tiny" motif, 8x8.
    EBlockPreset_tiny_bl_0,
    EBlockPreset_tiny_bl_1,
    EBlockPreset_tiny_bl_2,
    EBlockPreset_tiny_bl_3,
    EBlockPreset_tiny_bl_4,
    EBlockPreset_tiny_bl_5,
    EBlockPreset_tiny_bl_6,
    EBlockPreset_tiny_bl_7,
    EBlockPreset_tiny_bl_8,
    EBlockPreset_tiny_bl_9,
    EBlockPreset_tiny_col,
    EBlockPreset_tiny_bl_stretch,
    EBlockPreset_tiny_bl_turf1,
    EBlockPreset_tiny_bl_turf2,
    EBlockPreset_tiny_cr_1,
    EBlockPreset_tiny_cr_2,
    EBlockPreset_tiny_bigcr,
    EBlockPreset_tiny_conveyor_l,
    EBlockPreset_tiny_conveyor_r,
    EBlockPreset_tiny_oneway_u,
    EBlockPreset_tiny_oneway_l,
    EBlockPreset_tiny_oneway_r,
    EBlockPreset_tiny_oneway_d,
    EBlockPreset_tiny_hbeam_emitter_l,
    EBlockPreset_tiny_hbeam_emitter_r,
    EBlockPreset_tiny_spikes_u,
    EBlockPreset_tiny_spikes_l,
    EBlockPreset_tiny_spikes_r,
    EBlockPreset_tiny_spikes_d,
    EBlockPreset_tiny_crum,
    EBlockPreset_tiny_playerStart,
    EBlockPreset_tiny_bl_wallJump,
    EBlockPreset_tiny_bl_exit,
    EBlockPreset_tiny_autolift,
    EBlockPreset_tiny_mv_plat_l,
    EBlockPreset_tiny_mv_plat_r,
    EBlockPreset_tiny_btn1,
    EBlockPreset_tiny_sprtiny_0,
    EBlockPreset_tiny_sprtiny_1,
    EBlockPreset_tiny_sprtiny_2,
    EBlockPreset_tiny_sprtiny_3,
    EBlockPreset_tiny_pipe,
    EBlockPreset_tiny_pipe_bub,
    EBlockPreset_tiny_creep_fuzz_l,
    EBlockPreset_tiny_creep_fuzz_r,
    EBlockPreset_tiny_creep_martian,
    EBlockPreset_tiny_creep_mosquito,
    EBlockPreset_tiny_creep_jelly_LR,
    EBlockPreset_tiny_redblu_red,
    EBlockPreset_tiny_redblu_blu,
    EBlockPreset_tiny_bl_ice,
    EBlockPreset_tiny_aiBounceHint,
    EBlockPreset_tiny_avPlain,
    EBlockPreset_tiny_avCrate,
    EBlockPreset_tiny_creep_jelly_UD,
    EBlockPreset_tiny_mineCrate,
    EBlockPreset_tiny_springUp,
    
    EBlockPresetCount,
};
typedef enum EBlockPresetEnum EBlockPreset;


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ICurrentBlockPresetStateHolder
@protocol ICurrentBlockPresetStateHolder

-(void)currentBlockPresetUpdated:(EBlockPreset)preset;
-(EBlockPreset)getCurrentBlockPreset;

@end


/////////////////////////////////////////////////////////////////////////////////////////////////////////// ICurrentBlockPresetStateConsumer
@protocol ICurrentBlockPresetStateConsumer

-(void)setPresetStateHolder:(id<ICurrentBlockPresetStateHolder>)holder;

@end