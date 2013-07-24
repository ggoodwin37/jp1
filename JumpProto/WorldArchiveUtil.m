//
//  WorldArchiveUtil.m
//  JumpProto
//
//  Created by gideong on 10/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WorldArchiveUtil.h"
#import "ArchiveFormat.h"
#import "constants.h"
#import "SpriteAutoVariationDefines.h"
#import "Emu.h"
#import "LevelManifest.h"

@implementation WorldArchiveUtil


+(AFBlockProps *)readAFBlockPropsFromBlockProps:(BlockProps *)blockProps
{
    AFBlockProps *afBlockProps;
    afBlockProps = [[[AFBlockProps alloc] init] autorelease];
    afBlockProps.token = blockProps.token;
    afBlockProps.canMoveFreely = blockProps.canMoveFreely;
    afBlockProps.affectedByGravity = blockProps.affectedByGravity;
    afBlockProps.affectedByFriction = blockProps.affectedByFriction;
    afBlockProps.bounceDampFactor = blockProps.bounceDampFactor;
    afBlockProps.initialVelocity = FlPointFromEmuPoint( blockProps.initialVelocity );
    return afBlockProps;
}


+(void)setPropsForBlock:(Block *)block fromPreset:(EBlockPreset)preset
{
    // defaults
    block.props.canMoveFreely = NO;
    block.props.affectedByGravity = NO;
    block.props.affectedByFriction = NO;
    block.props.bounceDampFactor = 0.f;    
    block.props.initialVelocity = EmuPointMake( 0, 0 );
    block.props.solidMask = BlockEdgeDirMask_Full;
    block.props.xConveyor = 0.f;
    block.props.hurtyMask = BlockEdgeDirMask_None;
    block.props.isGoalBlock = NO;
    block.props.isActorBlock = NO;
    block.props.isPlayerBlock = NO;

    switch( preset )
    {
        // just ground
        case EBlockPreset_Test0:
        case EBlockPreset_GroundColumn:
        case EBlockPreset_GroundBrickAVTest:
        case EBlockPreset_BLTurf:
        case EBlockPreset_GroundRusty:
        case EBlockPreset_GroundWood:
        case EBlockPreset_GroundQuilt:
        case EBlockPreset_Algae:
        case EBlockPreset_RedBrick:
        case EBlockPreset_Lavender:
            break;
            
        // one-way ground
        case EBlockPreset_OneWayU:
            block.props.solidMask = BlockEdgeDirMask_Up;
            break;
        case EBlockPreset_OneWayL:
            block.props.solidMask = BlockEdgeDirMask_Left;
            break;
        case EBlockPreset_OneWayR:
            block.props.solidMask = BlockEdgeDirMask_Right;
            break;
        case EBlockPreset_OneWayD:
            block.props.solidMask = BlockEdgeDirMask_Down;
            break;
            
        case EBlockPreset_PropSpikes:
            block.props.hurtyMask = BlockEdgeDirMask_Up;
            break;
            
        case EBlockPreset_PropSkull:
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;
            
        case EBlockPreset_MineCrate:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;

        case EBlockPreset_MineFloat:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;    
            block.props.initialVelocity = EmuPointMake( MOVING_PLATFORM_RIGHT_MEDIUM_VX * 0.9f, 0.f );
            block.props.hurtyMask = BlockEdgeDirMask_Full;
            break;

        case EBlockPreset_PropGoal:
            block.props.isGoalBlock = YES;
            break;
            
        case EBlockPreset_PropSpring:
            block.props.springyMask = BlockEdgeDirMask_Up;
            break;

        case EBlockPreset_MovingPlatformRightMedium:
            block.props.canMoveFreely = YES;
            block.props.bounceDampFactor = 1.f;    
            block.props.initialVelocity = EmuPointMake( MOVING_PLATFORM_RIGHT_MEDIUM_VX, 0.f );
            break;
        
        case EBlockPreset_PropFancyCrate:
        case EBlockPreset_TestCrate:
        case EBlockPreset_WoodCrate:
        case EBlockPreset_Qik:
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            break;
        
        case EBlockPreset_ConveyorL:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor = -CONVEYOR_VX;
            break;
        case EBlockPreset_ConveyorR:
            block.props.solidMask = BlockEdgeDirMask_Up;
            block.props.xConveyor =  CONVEYOR_VX;
            break;
            
        case EBlockPreset_TestGroupA:
            NSLog( @"Deprecated code, I only expect to see testGroups in old levels." );
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.groupId = 0x1d1;
            break;
        case EBlockPreset_TestGroupB:
            NSLog( @"Deprecated code, I only expect to see testGroups in old levels." );
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            block.groupId = 0x1d2;
            break;

        case EBlockPreset_SillyEm0:
        case EBlockPreset_SillyMax0:
            // TODO: just act as crates for now...can use these to play with random effects if you get around to it.
            block.props.canMoveFreely = YES;
            block.props.affectedByGravity = YES;
            block.props.affectedByFriction = YES;
            break;
            
        // unknown or unexpected
        case EBlockPreset_PlayerStart:
        case EBlockPreset_None:
        default:
            NSLog( @"setPropsForBlock:fromPreset: unknown or unexpected block preset." );
            break;
    }
}


+(float)getAnimDurForPreset:(EBlockPreset)preset
{
    switch( preset )
    {
        case EBlockPreset_PropGoal:
            return 0.5f;
            
        case EBlockPreset_ConveyorL:
        case EBlockPreset_ConveyorR:
            return 0.1f;
            
        default:
            return 0.f;
    }
}


+(NSString *)getSpriteResourceNameForPreset:(EBlockPreset)preset fourWayAVCode:(UInt32)fourWayAVCode
{
    switch( preset )
    {
        // just ground
        case EBlockPreset_Test0:
            return @"bl_brick";
            
        case EBlockPreset_MovingPlatformRightMedium:
            return @"bl_ice";
            
        case EBlockPreset_TestCrate:
            return @"bl_clown";

            
        case EBlockPreset_GroundColumn:
            if( ! (fourWayAVCode & AutoVariationMask_U) )
            {
                return @"bl_column_top";
            }
            else if( ! (fourWayAVCode & AutoVariationMask_D) )
            {
                return @"bl_column_bottom";
            }
            else
            {
                return @"bl_column_mid";
            }
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
            return @"props0_goalflag_anim";
        case EBlockPreset_GroundBrickAVTest:
            return [NSString stringWithFormat:@"bl_brickAVTest0_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_PropFancyCrate:
            return @"bl_fancyCrate0";
        case EBlockPreset_ConveyorL:
            return @"convL";
        case EBlockPreset_ConveyorR:
            return @"convR";
        case EBlockPreset_BLTurf:
            return [NSString stringWithFormat:@"bl_turf_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_TestGroupA:
            return @"bl_clown";
        case EBlockPreset_TestGroupB:
            return @"bl_fancyCrate0";
        case EBlockPreset_SillyEm0:
            return @"bl_sillyEm0";
        case EBlockPreset_SillyMax0:
            return @"bl_sillyMax0";
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
        case EBlockPreset_WoodCrate:
            return @"bl_wood_crate";
        case EBlockPreset_Algae:
            return [NSString stringWithFormat:@"bl_algae_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_Qik:
            return [NSString stringWithFormat:@"bl_qik_avl%lx", (fourWayAVCode & 0x0f)];
        case EBlockPreset_RedBrick:
            return @"bl_half_redbrick";
        case EBlockPreset_Lavender:
            return @"bl_half_lavender";
            
        // unknown or unexpected
        case EBlockPreset_PlayerStart:
        case EBlockPreset_None:
        default:
            NSLog( @"getSpriteNameForPresetBlock:fromPreset: unknown or unexpected block preset." );
            return nil;
    }
}


+(SpriteStateMap *)getSpriteStateMapForPresetBlock:(AFPresetBlockBase *)presetBlock
{
    SpriteStateMap *resultMap = [[[SpriteStateMap alloc] initWithSize:presetBlock.autoVariationMap.size] autorelease];
    for( int y = 0; y < presetBlock.autoVariationMap.size.height; ++y )
    {
        for( int x = 0; x < presetBlock.autoVariationMap.size.width; ++x )
        {
            UInt32 thisHint = [presetBlock.autoVariationMap getHintAtX:x y:y];
            float animDur = [WorldArchiveUtil getAnimDurForPreset:presetBlock.preset];
            NSString *resourceName = [WorldArchiveUtil getSpriteResourceNameForPreset:presetBlock.preset fourWayAVCode:thisHint];
            SpriteState *spriteState;
            if( animDur > 0.f )
            {
                spriteState = [[[AnimSpriteState alloc] initWithAnimName:resourceName animDur:animDur] autorelease];
            }
            else
            {
                spriteState = [[[StaticSpriteState alloc] initWithSpriteName:resourceName] autorelease];
            }
            [resultMap setSpriteStateAtX:x y:y to:spriteState];
        }
    }
    return resultMap;
}


+(void)setGroupAndPropsForBlock:(Block *)block fromAFBlock:(AFBlock *)afBlock
{
    // usually none. may be overwritten by presets.
    block.groupId = afBlock.groupId;
    
    // note: ignoring archived token property and just sticking with the one we
    //       got from blockProps ctor. this is guaranteed to be unique with other
    //       blocks that may get spawned. this means we won't be able to assume
    //       tokens are consistent between view and edit, may need to change.
    // TODO: come to think of it, this will probably break event scenarios where
    //       we need to be able to specify an event target in edit.
    if( [afBlock isMemberOfClass:[AFPresetBlockBase class]] )
    {
        AFPresetBlockBase *afPresetBlock = (AFPresetBlockBase *)afBlock;
        [WorldArchiveUtil setPropsForBlock:block fromPreset:afPresetBlock.preset];
    }
    else
    {
        block.props.canMoveFreely = afBlock.props.canMoveFreely;
        block.props.affectedByGravity = afBlock.props.affectedByGravity;
        block.props.affectedByFriction = afBlock.props.affectedByFriction;
        block.props.bounceDampFactor = afBlock.props.bounceDampFactor;    
        block.props.initialVelocity = EmuPointFromFlPoint( afBlock.props.initialVelocity );
    }
}


+(EmuPoint)getBlockDimsForPresetBlock:(AFPresetBlockBase *)presetBlock
{
    float wBl = presetBlock.rect.size.width;
    float hBl = presetBlock.rect.size.height;
    
    // read the value as grid units, then convert to worldEmu units on return.
    return EmuPointMake( GRID_SIZE_Emu * wBl, GRID_SIZE_Emu * hBl );
}


+(BOOL)isActor:(EBlockPreset)preset
{
    switch( preset )
    {
        case EBlockPreset_TestMeanieB:
        case EBlockPreset_FaceBone:
        case EBlockPreset_Crumbles1:
            return YES;

        case EBlockPreset_PlayerStart:
            // player start is handled specially.
            return NO;

        default:
            return NO;
    }
}


+(Actor *)createActorForPresetBlock:(AFPresetBlockBase *)block
{
    EmuPoint pStart = EmuPointMake( block.rect.origin.x * ONE_BLOCK_SIZE_Emu,
                                    block.rect.origin.y * ONE_BLOCK_SIZE_Emu );
    
    switch( block.preset )
    {
        case EBlockPreset_TestMeanieB:            
            return [[[TestMeanieBActor alloc] initAtStartingPoint:pStart] autorelease];
        
        case EBlockPreset_FaceBone:
            return [[[FaceboneActor alloc] initAtStartingPoint:pStart] autorelease];
            
        case EBlockPreset_Crumbles1:
            return [[[Crumbles1Actor alloc] initAtStartingPoint:pStart] autorelease];
            
        default:
            NSLog( @"don't know how to create actor for preset." );
            return nil;
    }
}


+(void)readWorld:(World *)world fromAF:(AFLevel *)level
{
    // assume [world reset] was called already.
    
    // TODO: do we need to be able to read/write this value to disk, or can we always use a standard value?
    // TODO: need to put more thought into this. One_Block strikes me as too small for actors. works well for movingplatform stuff that stays constrained.
    // TODO: reconsider this now that you jacked the grid size by 4
    world.elbowRoom.stripSize = ONE_BLOCK_SIZE_Emu;
    
    EmuPoint playerStart = EmuPointMake( 0, 0 );
    
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        Block *thisBlock = nil;
        AFPresetBlockBase *thisActorPresetBlock = nil;
        
        if( [thisAFBlock isMemberOfClass:[AFSpriteBlock class]] )
        {
            NSAssert( NO, @"support for very old serialized-from-play-mode blocks has been removed." );
        }
        else if( [thisAFBlock isMemberOfClass:[AFPresetBlockBase class]] )
        {
            AFPresetBlockBase *thisAFPresetBlockBase = (AFPresetBlockBase *)thisAFBlock;
            
            if( [WorldArchiveUtil isActor:thisAFPresetBlockBase.preset] )
            {
                // set up an actor instead of a block
                thisBlock = nil;
                thisActorPresetBlock = thisAFPresetBlockBase;
            }
            else
            {
                // set up a block directly
                
                EmuPoint blockDims = [WorldArchiveUtil getBlockDimsForPresetBlock:thisAFPresetBlockBase];
                int x = thisAFPresetBlockBase.rect.origin.x * ONE_BLOCK_SIZE_Emu;
                int y = thisAFPresetBlockBase.rect.origin.y * ONE_BLOCK_SIZE_Emu - blockDims.y;  // late night y-flipped-ness correction.
                EmuRect thisRectEmu = EmuRectMake( x, y, blockDims.x, blockDims.y );
                
                if( thisAFPresetBlockBase.preset == EBlockPreset_PlayerStart )
                {
                    playerStart = EmuPointMake( thisRectEmu.origin.x, thisRectEmu.origin.y );
                    continue;
                }
                SpriteStateMap *spriteStateMap = [WorldArchiveUtil getSpriteStateMapForPresetBlock:thisAFPresetBlockBase];
                thisBlock = [[[SpriteBlock alloc] initWithRect:thisRectEmu spriteStateMap:spriteStateMap] autorelease];
            }
        }
        else
        {
            NSLog( @"readWorldFromAF: unrecognized block type in AFBlockList." );
            continue;
        }

        // TODO: WorldArchiveUtil has too much smarts. It shouldn't know how to create World blocks and actors for every preset.
        //       This should probably be a separate helper. Sort of academic for now.
        
        if( thisBlock != nil )
        {
            [WorldArchiveUtil setGroupAndPropsForBlock:thisBlock fromAFBlock:thisAFBlock];
            
            if( thisBlock.groupId == GROUPID_NONE )
            {
                [world addWorldBlock:thisBlock];
            }
            else
            {
                BlockGroup *thisGroup = [world ensureGroupForId:thisBlock.groupId];
                [world addBlock:thisBlock toGroup:thisGroup];
            }
        }
        
        if( thisActorPresetBlock != nil )
        {
            Actor *thisActor = [WorldArchiveUtil createActorForPresetBlock:thisActorPresetBlock];
            [world addNPCActor:thisActor];
        }
    }
    
    world.levelName = level.props.name;
    world.levelDescription = level.props.description;
    
    // is this right? Could also just store the starting point and actually init later, depending on usage.
    [world initPlayerAt:playerStart];
}


+(AFBlock *)getAFBlockForBlock:(Block *)thisBlock
{
    AFBlock *thisAFBlock;
    AFBlockProps *thisAFBlockProps = [WorldArchiveUtil readAFBlockPropsFromBlockProps:thisBlock.props];
    EmuRect thisRect = EmuRectMake( thisBlock.x, thisBlock.y, thisBlock.w, thisBlock.h );
    GroupId thisGroupId = thisBlock.groupId;
    
    // TODO: this should call a method on the block, so we don't have to do RTTI
    if( [thisBlock isMemberOfClass:[SpriteBlock class]] )
    {
        SpriteBlock *thisSpriteBlock = (SpriteBlock *)thisBlock;
        float animDur;
        if( [thisSpriteBlock.defaultSpriteState isMemberOfClass:[AnimSpriteState class]] )
        {
            AnimSpriteState *animSpriteState = (AnimSpriteState *)thisSpriteBlock.defaultSpriteState;
            animDur = animSpriteState.animDur;
        }
        else if( [thisSpriteBlock.defaultSpriteState isMemberOfClass:[StaticSpriteState class]] )
        {
            animDur = 0.f;  // not animating
        }
        else
        {
            NSLog( @"writeAFFromWorld: unrecognized spriteState type on SpriteBlock." );
            return nil;                
        }
        thisAFBlock = [[[AFSpriteBlock alloc] initWithProps:thisAFBlockProps rect:FlRectFromEmuRect(thisRect) groupId:thisGroupId resourceName:thisSpriteBlock.defaultSpriteState.resourceName animDur:animDur] autorelease];
    }
    else
    {
        NSLog( @"writeAFFromWorld: unrecognized block type in worldBlock list." );
        return nil;
    }
    return thisAFBlock;
}


+(AFLevel *)writeAFFromWorld:(World *)world
{
    NSMutableArray *afBlockList = [NSMutableArray arrayWithCapacity:[world worldSOCount]];
    for( int i = 0; i < [world worldSOCount]; ++i )
    {
        ASolidObject *thisSO = [world getWorldSO:i];
        if( [thisSO isGroup] )
        {
            BlockGroup *thisGroup = (BlockGroup *)thisSO;
            for( int j = 0; j < [thisGroup.blocks count]; ++j )
            {
                Block *thisBlock = (Block *)[thisGroup.blocks objectAtIndex:j];
                AFBlock *thisAFBlock = [WorldArchiveUtil getAFBlockForBlock:thisBlock];
                if( thisAFBlock != nil )
                {
                    [afBlockList addObject:thisAFBlock];
                }
            }
        }
        else
        {
            Block *thisBlock = (Block *)thisSO;
            AFBlock *thisAFBlock = [WorldArchiveUtil getAFBlockForBlock:thisBlock];
            if( thisAFBlock != nil )
            {
                [afBlockList addObject:thisAFBlock];
            }
        }
    }
    
    AFLevelProps *levelProps = [[[AFLevelProps alloc] init] autorelease];
    levelProps.name = world.levelName != nil ? world.levelName : @"Unnamed level";
    levelProps.description = world.levelDescription != nil ? world.levelDescription : @"No description.";
    
    return [[[AFLevel alloc] initWithProps:levelProps blockList:afBlockList] autorelease];
}


//#define LOG_BLOCK_DISK_ACTIVITY

+(void)loadWorld:(World *)world fromDiskForName:(NSString *)levelName
{
    NSString *path = [[LevelManifestManager instance] getPathForLevelName:levelName];
    NSLog( @"loading world from disk path: %@", path );
    NSDictionary *rootObject;
    
    // TODO: error handling
    rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    AFLevel *afLevel = (AFLevel *)[rootObject valueForKey:@"afLevel"];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSLog( @"WorldArchiveUtil loadWorld: reading %d blocks:", [afLevel.blockList count] );
    for( int i = 0; i < [afLevel.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[afLevel.blockList objectAtIndex:i];
        NSLog( @"  reading a block at %fx%f", thisAFBlock.rect.origin.x, thisAFBlock.rect.origin.y );
    }
#endif

    [WorldArchiveUtil readWorld:world fromAF:afLevel];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY
    NSLog( @"WorldArchiveUtil loadWorld: finished reading AFLevel." );
    for( int i = 0; i < [world worldSOCount]; ++i )
    {
        Block *thisBlock = (Block *)[world getWorldSO:i];
        NSLog( @"  created a Block at %dx%d of type %@ ", thisBlock.x, thisBlock.y, [[thisBlock class] description] );
    }
#endif
}


// this method isn't typically used. It's only needed to get hardcoded levels onto disk.
+(void)saveToDisk:(World *)world
{
    if( world.levelName == nil )
    {
        NSLog( @"WorldArchiveUtil saveToDisk error: tried to save an unnamed level, aborted." );
        return;
    }
    
    NSString *path = [[LevelManifestManager instance] getPathForLevelName:world.levelName];
    
    // check for existing file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if( [fileManager fileExistsAtPath:path] )
    {
        if( [fileManager removeItemAtPath:path error:NULL] )
        {
            NSLog( @"WorldArchiveUtil saveToDisk: an item with path %@ already existed, so I deleted it first.", path );
        }
        else
        {
            NSLog( @"WorldArchiveUtil saveToDisk: I wanted to remove an existing item at path %@, but failed!", path );
        }
    }
    
    AFLevel *afLevel = [WorldArchiveUtil writeAFFromWorld:world];
    
    NSMutableDictionary * rootObject;
    rootObject = [NSMutableDictionary dictionary];    
    [rootObject setValue:afLevel forKey:@"afLevel"];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}


@end
