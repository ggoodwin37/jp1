//
//  EBlockPresetSpriteNames.m
//  JumpProto
//
//  Created by Gideon Goodwin on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EBlockPresetSpriteNames.h"

@implementation EBlockPresetSpriteNames


+(NSString *)getSpriteNameForPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        case EBlockPreset_None:
            return nil;
            
        // batch 1
        case EBlockPreset_Test0:
            return @"bl_brick";
        case EBlockPreset_PlayerStart:
            return @"pr1_still";
        case EBlockPreset_MovingPlatformRightMedium:
            return @"bl_ice";
        case EBlockPreset_TestCrate:
            return @"bl_clown";
        case EBlockPreset_GroundColumn:
            return @"bl_column_mid";
        case EBlockPreset_OneWayU:
            return @"bl_oneway0_up";
        case EBlockPreset_OneWayL:
            return @"bl_oneway0_left";
        case EBlockPreset_OneWayR:
            return @"bl_oneway0_right";
        case EBlockPreset_OneWayD:
            return @"bl_oneway0_down";
        case EBlockPreset_PropSpikes:
            return @"props0_spikes";
        case EBlockPreset_PropSkull:
            return @"props0_skull";
        case EBlockPreset_PropGoal:
            return @"props0_goalflag_0";
        case EBlockPreset_GroundBrickAVTest:
            return @"bl_brickAVTest0_avlf";
        case EBlockPreset_PropFancyCrate:
            return @"bl_fancyCrate0";
        case EBlockPreset_ConveyorL:
            return @"bl_convL_1";
        case EBlockPreset_ConveyorR:
            return @"bl_convR_1";
        case EBlockPreset_BLTurf:
            return @"bl_turf_avlf";
        case EBlockPreset_TestGroupA:
            return @"bl_clown";
        case EBlockPreset_TestGroupB:
            return @"bl_fancyCrate0";
        case EBlockPreset_SillyEm0:
            return @"bl_sillyEm0";
        case EBlockPreset_SillyMax0:
            return @"bl_sillyMax0";
        case EBlockPreset_TestMeanieB:
            return @"props0_testMeanieB_0";
        case EBlockPreset_FaceBone:
            return @"badguy_faceBone0";
        case EBlockPreset_MineFloat:
            return @"badguy_cheapMineBlue";
        case EBlockPreset_MineCrate:
            return @"badguy_cheapMineRed";
        case EBlockPreset_GroundRusty:
            return @"bl_rusty";
        case EBlockPreset_GroundWood:
            return @"bl_wood";
        case EBlockPreset_GroundQuilt:
            return @"bl_quilt";
        case EBlockPreset_PropSpring:
            return @"prop_testSpring";
        case EBlockPreset_Crumbles1:
            return @"bl_crumbles1_crumbling2";
        case EBlockPreset_WoodCrate:
            return @"bl_wood_crate";
        case EBlockPreset_Algae:
            return @"bl_algae_avlf";
        case EBlockPreset_Qik:
            return @"bl_qik_avlf";
        case EBlockPreset_RedBrick:
            return @"bl_half_redbrick";
        case EBlockPreset_Lavender:
            return @"bl_half_lavender";
            
        // batch 2
        case EBlockPreset_tiny_bl_0: return @"tiny-bl-0";
        case EBlockPreset_tiny_bl_1: return @"tiny-bl-1";
        case EBlockPreset_tiny_bl_2: return @"tiny-bl-2";
        case EBlockPreset_tiny_bl_3: return @"tiny-bl-3";
        case EBlockPreset_tiny_bl_4: return @"tiny-bl-4";
        case EBlockPreset_tiny_bl_5: return @"tiny-bl-5";
        case EBlockPreset_tiny_bl_6: return @"tiny-bl-6";
        case EBlockPreset_tiny_bl_7: return @"tiny-bl-7";
        case EBlockPreset_tiny_bl_8: return @"tiny-bl-8";
        case EBlockPreset_tiny_bl_9: return @"tiny-bl-9";
        case EBlockPreset_tiny_col: return @"tiny-col-m";
        case EBlockPreset_tiny_bl_stretch: return @"tiny-bl-stretch-m";
        case EBlockPreset_tiny_bl_turf1: return @"tiny-bl-turf1-m";
        case EBlockPreset_tiny_bl_turf2: return @"tiny-bl-turf2-m";
        case EBlockPreset_tiny_cr_1: return @"tiny-cr-1";
        case EBlockPreset_tiny_cr_2: return @"tiny-cr-2";
        case EBlockPreset_tiny_bigcr: return @"tiny-bigcr";
        case EBlockPreset_tiny_conveyor_l: return @"tiny-conveyor-l-edithint";
        case EBlockPreset_tiny_conveyor_r: return @"tiny-conveyor-r-edithint";
        case EBlockPreset_tiny_oneway_u: return @"tiny-oneway-u";
        case EBlockPreset_tiny_oneway_l: return @"tiny-oneway-l";
        case EBlockPreset_tiny_oneway_r: return @"tiny-oneway-r";
        case EBlockPreset_tiny_oneway_d: return @"tiny-oneway-d";
        case EBlockPreset_tiny_spikes_u: return @"tiny-spikes-u-0";
        case EBlockPreset_tiny_spikes_l: return @"tiny-spikes-l-0";
        case EBlockPreset_tiny_spikes_r: return @"tiny-spikes-r-0";
        case EBlockPreset_tiny_spikes_d: return @"tiny-spikes-d-0";
        case EBlockPreset_tiny_crum: return @"tiny-crum-2";
        case EBlockPreset_tiny_playerStart: return @"tiny-start-token";
        case EBlockPreset_tiny_bl_wallJump: return @"tiny-bl-walljump";
        case EBlockPreset_tiny_bl_exit: return @"tiny-exit";
        case EBlockPreset_tiny_lift: return @"tiny-lift-0";
        case EBlockPreset_tiny_mv_plat_l: return @"tiny-mv-plat-l-edithint";
        case EBlockPreset_tiny_mv_plat_r: return @"tiny-mv-plat-r-edithint";
        case EBlockPreset_tiny_btn1: return @"tiny-button-edithint";
        case EBlockPreset_tiny_sprtiny_0: return @"tiny-sprtiny-0";
        case EBlockPreset_tiny_sprtiny_1: return @"tiny-sprtiny-1";
        case EBlockPreset_tiny_sprtiny_2: return @"tiny-sprtiny-2";
        case EBlockPreset_tiny_sprtiny_3: return @"tiny-sprtiny-3";
        case EBlockPreset_tiny_pipe: return @"tiny-pipe-ud";
        case EBlockPreset_tiny_pipe_bub: return @"tiny-pipe-bub";
        case EBlockPreset_tiny_creep_fuzz_l: return @"tiny-creep-fuzz-0";
        case EBlockPreset_tiny_creep_fuzz_r: return @"tiny-creep-fuzz-reversed";
        case EBlockPreset_tiny_creep_martian: return @"tiny-creep-martian-0";
        case EBlockPreset_tiny_creep_mosquito: return @"tiny-creep-mosquito-0";
        case EBlockPreset_tiny_creep_jelly: return @"tiny-creep-jelly-0";
        case EBlockPreset_tiny_redblu_red: return @"tiny-redblu-red-off";  // represents initial blu-is-on state
        case EBlockPreset_tiny_redblu_blu: return @"tiny-redblu-blu-on";
        case EBlockPreset_tiny_bl_ice: return @"tiny-bl-ice";
        case EBlockPreset_tiny_aiBounceHint: return @"tiny-ai-bounce-edithint";
            
        default:
            return @"icon_close";  // TODO: better "unknown" tile?
            
    }
    
}

@end
