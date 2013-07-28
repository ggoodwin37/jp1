//
//  EArchiveUtil.m
//  JumpProto
//
//  Created by gideong on 10/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EArchiveUtil.h"
#import "constants.h"
#import "SpriteAutoVariationDefines.h"
#import "LevelUtil.h"
#import "EBlockPresetSpriteNames.h"
#import "SpriteManager.h"

@implementation EArchiveUtil


+(void)addBlockMarkerForAFPresetBlock:(AFPresetBlockBase *)block toDoc:(EGridDocument *)doc
{
    // note we're using grid coords here, so this type of AFBlock gets serialized in a different
    //  coordinate system than the original view types. Since the decoder has flexibility to
    //  interpret each AF type as needed, this is fine.
    [doc setPreset:block.preset atXGrid:block.rect.origin.x yGrid:block.rect.origin.y w:block.rect.size.width h:block.rect.size.height groupId:block.groupId];
}


// when moving between AF space and EWorldView space, we go through this
//  transform. this compensates for the opposite y direction of quartz vs.
//  opengl and also applies a shift factor (which can be used to adjust
//  the coordinate space for optimal floating point precision, which may
//  not be a real thing).
// ^^ the fp precision thing no longer applies with Emus but it's still nice to have
//    normalized coords when debugging.

+(void)yFlip:(AFLevel *)level
{
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        thisBlock.rect = CGRectMake(  thisBlock.rect.origin.x,
                                     -thisBlock.rect.origin.y,
                                      thisBlock.rect.size.width,
                                      thisBlock.rect.size.height );
    }
}


+(void)normalize:(AFLevel *)level
{
    float xMinValue, yMinValue;
    
    xMinValue = FLT_MAX;
    yMinValue = FLT_MAX;
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        
        xMinValue = fminf( xMinValue, thisBlock.rect.origin.x );
        yMinValue = fminf( yMinValue, thisBlock.rect.origin.y );
    }
    
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        thisBlock.rect = CGRectMake( thisBlock.rect.origin.x - xMinValue,
                                     thisBlock.rect.origin.y - yMinValue,
                                     thisBlock.rect.size.width,
                                     thisBlock.rect.size.height );
    }
}


+(void)applyGlobalTranslation:(CGPoint)p toLevel:(AFLevel *)level
{
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        AFBlock *thisBlock = (AFBlock *)[level.blockList objectAtIndex:i];
        thisBlock.rect = CGRectMake( thisBlock.rect.origin.x + p.x,
                                     thisBlock.rect.origin.y + p.y,
                                     thisBlock.rect.size.width,
                                     thisBlock.rect.size.height );
    }
}


+(void)transformAFLevelBeforeReadingToDoc:(AFLevel *)level
{
    // AFs exist in "true" space (which is defined to be the same as opengl space).
    [EArchiveUtil yFlip:level];
    [EArchiveUtil normalize:level];
    
    CGPoint translation = CGPointMake( 128.f, 128.f );   // a fair bit of padding on each axis
    [EArchiveUtil applyGlobalTranslation:translation toLevel:level];
}


+(void)transformAFLevelAfterWritingFromDoc:(AFLevel *)level
{
    [EArchiveUtil yFlip:level];
    [EArchiveUtil normalize:level];
}


+(void)readDoc:(EGridDocument *)doc fromAF:(AFLevel *)level
{
    [EArchiveUtil transformAFLevelBeforeReadingToDoc:level];
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        id thisAFBlock = [level.blockList objectAtIndex:i];
        
        if( [thisAFBlock isMemberOfClass:[AFPresetBlockBase class]] )
        {
            AFPresetBlockBase *thisAFPresetBlock = (AFPresetBlockBase *)thisAFBlock;
            [EArchiveUtil addBlockMarkerForAFPresetBlock:thisAFPresetBlock toDoc:doc];
        }
        else
        {
            NSLog( @"readFromAF: ignoring block of type %@", [[thisAFBlock class] description] );
        }
    }
    
    doc.levelName = level.props.name;
    doc.levelDescription = level.props.description;
}


+(void)assignTokensForAF:(AFLevel *)level
{
    UInt32 startingToken = 256;
    for( int i = 0; i < [level.blockList count]; ++i )
    {
        if( ![[level.blockList objectAtIndex:i] isMemberOfClass:[AFPresetBlockBase class]] )
        {
            NSLog( @"assignTokensForAF: unexpected afBlockType." );
            continue;
        }
        AFPresetBlockBase *thisPresetBlock = (AFPresetBlockBase *)[level.blockList objectAtIndex:i];
        thisPresetBlock.token = startingToken++;
    }
}


// there's a whole class of undefined behavior around non-integral multiples, so the level author
//  just needs to Be Good.
+(CGSize)getAutoVariationMapSizeForMarker:(EGridBlockMarker *)marker
{
    NSString *spriteName = [EBlockPresetSpriteNames getSpriteNameForPreset:marker.preset];
    SpriteDef *spriteDef = [[SpriteManager instance] getSpriteDef:spriteName];
    int mapW = MAX( 1, (int)(ceilf( marker.gridSize.xGrid / spriteDef.worldSize.width ) ) );
    int mapH = MAX( 1, (int)(ceilf( marker.gridSize.yGrid / spriteDef.worldSize.height ) ) );
    return CGSizeMake( mapW, mapH );
}


+(BOOL)presetBlocksAreDistinct:(EBlockPreset)preset
{
    // TODO: return YES here for presets that should only autovary within blocks, not across blocks.
    //       this will allow you to have variable size bricks with av but still have a nice visual differentiation
    //       between adjacent bricks.
    return NO;
}


+(void)generateAutoVariationHintMapForBlock:(AFPresetBlockBase *)presetBlock fromDoc:(EGridDocument *)doc origMarker:(EGridBlockMarker *)origMarker
{
    if( origMarker != nil && origMarker.shadowParent != nil ) origMarker = origMarker.shadowParent;

    NSString *spriteName = [EBlockPresetSpriteNames getSpriteNameForPreset:presetBlock.preset];
    SpriteDef *spriteDef = [[SpriteManager instance] getSpriteDef:spriteName];
    int xStep = spriteDef.worldSize.width;
    int yStep = spriteDef.worldSize.height;
    
    // note: this does a sparse check against adjacent markers, choosing sparseness step
    //       based on sprite's worldsize. this seems sort of strange but I think it's just
    //       because markers are more dense than needed to generate this info.
    for( int yOffs = 0; yOffs < presetBlock.autoVariationMap.size.height; ++yOffs )
    {
        for( int xOffs = 0; xOffs < presetBlock.autoVariationMap.size.width; ++xOffs )
        {
            UInt32 xGrid = presetBlock.rect.origin.x + (xOffs * xStep);
            int yOffsAdjusted = presetBlock.autoVariationMap.size.height - yOffs - 1;  // the ol' mystery flip.
            // I think this is because y polarity is different in grid coords and avmap coords. *waves hands*
            UInt32 yGrid = presetBlock.rect.origin.y + (yOffsAdjusted * yStep);
            UInt32 avHint = 0;

            EBlockPreset preset;
            EGridBlockMarker *marker;

            marker = [doc getMarkerAtXGrid:(xGrid + 0) yGrid:(yGrid + yStep)];
            if( marker != nil && marker.shadowParent != nil ) marker = marker.shadowParent;
            preset = ( marker != nil ) ? marker.preset : EBlockPreset_None;
            if( [EArchiveUtil presetBlocksAreDistinct:presetBlock.preset] && marker != origMarker ) preset = EBlockPreset_None;
            if( presetBlock.preset == preset )
                avHint |= AutoVariationMask_D;

            marker = [doc getMarkerAtXGrid:(xGrid - xStep) yGrid:(yGrid + 0)];
            if( marker != nil && marker.shadowParent != nil ) marker = marker.shadowParent;
            preset = ( marker != nil ) ? marker.preset : EBlockPreset_None;
            if( [EArchiveUtil presetBlocksAreDistinct:presetBlock.preset] && marker != origMarker ) preset = EBlockPreset_None;
            if( presetBlock.preset == preset )
                avHint |= AutoVariationMask_L;

            marker = [doc getMarkerAtXGrid:(xGrid + xStep) yGrid:(yGrid + 0)];
            if( marker != nil && marker.shadowParent != nil ) marker = marker.shadowParent;
            preset = ( marker != nil ) ? marker.preset : EBlockPreset_None;
            if( [EArchiveUtil presetBlocksAreDistinct:presetBlock.preset] && marker != origMarker ) preset = EBlockPreset_None;
            if( presetBlock.preset == preset )
                avHint |= AutoVariationMask_R;

            marker = [doc getMarkerAtXGrid:(xGrid + 0) yGrid:(yGrid - yStep)];
            if( marker != nil && marker.shadowParent != nil ) marker = marker.shadowParent;
            preset = ( marker != nil ) ? marker.preset : EBlockPreset_None;
            if( [EArchiveUtil presetBlocksAreDistinct:presetBlock.preset] && marker != origMarker ) preset = EBlockPreset_None;
            if( presetBlock.preset == preset )
                avHint |= AutoVariationMask_U;

            [presetBlock.autoVariationMap setHintAtX:xOffs y:yOffs to:avHint];
        }
    }
}


+(AFLevel *)writeToAFFromDoc:(EGridDocument *)doc
{
    NSArray *markerList = [doc getValues];
    
    NSMutableArray *afBlockList = [NSMutableArray arrayWithCapacity:[markerList count]];
    for( int i = 0; i < [markerList count]; ++i )
    {
        EGridBlockMarker *thisMarker = (EGridBlockMarker *)[markerList objectAtIndex:i];
        if( thisMarker.shadowParent != nil )
        {
            // don't save shadow markers
            continue;
        }
        GroupId thisGroupId = thisMarker.props.groupId;
        
        CGRect thisRect = CGRectMake( thisMarker.gridLocation.xGrid,
                                      thisMarker.gridLocation.yGrid,
                                      thisMarker.gridSize.xGrid,
                                      thisMarker.gridSize.yGrid );
        
        CGSize avMapSize = [EArchiveUtil getAutoVariationMapSizeForMarker:thisMarker];
        AFAutoVariationMap *avMap = [[[AFAutoVariationMap alloc] initWithSize:avMapSize] autorelease];
        AFPresetBlockBase *thisAFBlock = [[AFPresetBlockBase alloc] initWithPreset:thisMarker.preset rect:thisRect groupId:thisGroupId autoVariationMap:avMap];
        [EArchiveUtil generateAutoVariationHintMapForBlock:thisAFBlock fromDoc:doc origMarker:thisMarker];
        [afBlockList addObject:thisAFBlock];
    }
    
    AFLevelProps *levelProps = [[[AFLevelProps alloc] init] autorelease];
    levelProps.name = doc.levelName != nil ? doc.levelName : @"Unnamed level";
    levelProps.description = doc.levelDescription != nil ? doc.levelDescription : @"No description.";
    
    AFLevel *result = [[[AFLevel alloc] initWithProps:levelProps blockList:afBlockList] autorelease];
    [EArchiveUtil transformAFLevelAfterWritingFromDoc:result];
    [EArchiveUtil assignTokensForAF:result];
    return result;
}


//#define LOG_BLOCK_DISK_ACTIVITY

+(void)loadDoc:(EGridDocument *)doc fromDiskForName:(NSString *)levelName
{
    NSString *path = [[LevelManifestManager instance] getPathForLevelName:levelName];
    NSDictionary *rootObject;
    
    // TODO: error handling
    rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    AFLevel *afLevel = (AFLevel *)[rootObject valueForKey:@"afLevel"];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSLog( @"EArchiveUtil loadDoc:fromDiskForName reading %d blocks:", [afLevel.blockList count] );
    for( int i = 0; i < [afLevel.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[afLevel.blockList objectAtIndex:i];
        NSLog( @"  reading a block at %fx%f with groupId %lu", thisAFBlock.rect.origin.x, thisAFBlock.rect.origin.y, thisAFBlock.groupId );
    }
#endif

    [EArchiveUtil readDoc:doc fromAF:afLevel];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSArray *markerList = [doc getValues];
    NSLog( @"EArchiveUtil loadDoc: read with %d markers:", [markerList count] );
    for( int i = 0; i < [markerList count]; ++i )
    {
        EGridBlockMarker *thisMarker = (EGridBlockMarker *)[markerList objectAtIndex:i];
        NSLog( @"  a %@marker is at grid %dx%d with groupId %lu", thisMarker.shadowParent != nil ? @"shadow " : @"",
              thisMarker.gridLocation.xGrid, thisMarker.gridLocation.yGrid, thisMarker.props.groupId );
    }
#endif

}


+(void)saveToDisk:(EGridDocument *)doc
{
    if( doc.levelName == nil )
    {
        NSLog( @"EArchiveUtil saveToDisk error: tried to save an unnamed level, aborted." );
        return;
    }
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSArray *markerList = [doc getValues];
    NSLog( @"EArchiveUtil saveToDisk: starting with %d markers:", [markerList count] );
    for( int i = 0; i < [markerList count]; ++i )
    {
        EGridBlockMarker *thisMarker = (EGridBlockMarker *)[markerList objectAtIndex:i];
        NSLog( @"  a %@marker is at grid %dx%d", thisMarker.shadowParent != nil ? @"shadow " : @"",
              thisMarker.gridLocation.xGrid, thisMarker.gridLocation.yGrid );
    }
#endif
    
    NSString *path = [[LevelManifestManager instance] getPathForLevelName:doc.levelName];
    
    // check for existing file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if( [fileManager fileExistsAtPath:path] )
    {
        if( [fileManager removeItemAtPath:path error:NULL] )
        {
            NSLog( @"EArchiveUtil saveToDisk: deleting existing item at %@", path );
        }
        else
        {
            NSLog( @"EArchiveUtil saveToDisk: failed to remove existing item at %@", path );
        }
    }
    
    AFLevel *afLevel = [EArchiveUtil writeToAFFromDoc:doc];
    
#ifdef LOG_BLOCK_DISK_ACTIVITY    
    NSLog( @"EArchiveUtil saveToDisk: writing %d blocks:", [afLevel.blockList count] );
    for( int i = 0; i < [afLevel.blockList count]; ++i )
    {
        AFBlock *thisAFBlock = (AFBlock *)[afLevel.blockList objectAtIndex:i];
        NSLog( @"  writing a block size %fx%f at %fx%f", thisAFBlock.rect.size.width, thisAFBlock.rect.size.height, thisAFBlock.rect.origin.x, thisAFBlock.rect.origin.y );
    }
#endif
    
    NSMutableDictionary * rootObject;
    rootObject = [NSMutableDictionary dictionary];    
    [rootObject setValue:afLevel forKey:@"afLevel"];
    [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
}

@end

