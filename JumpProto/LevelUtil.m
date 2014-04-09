//
//  LevelUtil.h
//  JumpProto
//
//  Created by Gideon Goodwin on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LevelUtil.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////// LevelFileUtil

@implementation LevelFileUtil

-(id)init
{
    if( self = [super init] )
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
        m_documentsDirectoryPath = [[paths objectAtIndex:0] retain];

        // temp: cleanup junk levels that were created due to bugs or testing.
        //[self deleteAllLevelsOnDisk];
    }
    return self;
}


-(void)dealloc
{
    [m_documentsDirectoryPath release]; m_documentsDirectoryPath = nil;
    [super dealloc];
}


static LevelFileUtil *globalLevelFileUtilInstance = nil;

+(void)initGlobalInstance
{
    NSAssert( globalLevelFileUtilInstance == nil, @"initializing global LevelFileUtil more than once is BAD." );
    globalLevelFileUtilInstance = [[LevelFileUtil alloc] init];
}


+(void)releaseGlobalInstance
{
    [globalLevelFileUtilInstance release]; globalLevelFileUtilInstance = nil;
}


+(LevelFileUtil *)instance
{
    return globalLevelFileUtilInstance;
}


-(void)deleteAllFilesWithExtension:(NSString *)ext
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:m_documentsDirectoryPath error:NULL];
    NSMutableArray *targetPathList = [NSMutableArray arrayWithCapacity:128];
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSString *thisPath = (NSString *)[allFiles objectAtIndex:i];
        if( [thisPath hasSuffix:ext] )
        {
            // function is form
            BOOL exclude = NO;
            if( [thisPath rangeOfString:@"draw-stress-01"].location != NSNotFound
             || [thisPath rangeOfString:@"gap-logic-check-1"].location != NSNotFound
             || [thisPath rangeOfString:@"idle-crates-stress-01"].location != NSNotFound )
            {
                NSLog( @"deleteAllFiles: excluding %@", thisPath );
                exclude = YES;
            }
            
            if( !exclude )
            {
                [targetPathList addObject:thisPath];
            }
        }
    }
    
    NSLog( @"deleteAllFilesWithExtension: deleting %lu files with extension %@.", (unsigned long)[targetPathList count], ext );
    for( int i = 0; i < [targetPathList count]; ++i )
    {
        NSString *thisFilenameWithExtension = (NSString *)[targetPathList objectAtIndex:i];
        NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, thisFilenameWithExtension, nil];
        NSString *thisPath = [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
        NSLog( @"deleteAllFilesWithExtension: deleting %@", thisPath );
        if( ![[NSFileManager defaultManager] removeItemAtPath:thisPath error:NULL] )
        {
            NSLog( @"deleteAllFilesWithExtension: !!failed to delete %@", thisPath );
        }
    }
}


-(void)deleteAllLevelsOnDisk
{
    [self deleteAllFilesWithExtension:LEVEL_EXTENSION];
}


-(NSString *)getPathForLevelName:(NSString *)levelName
{
    NSString *filenameWithExtension = [NSString stringWithFormat:@"%@%@", levelName, LEVEL_EXTENSION];
    NSArray *pathComponents = [NSArray arrayWithObjects: m_documentsDirectoryPath, filenameWithExtension, nil];
    return [[NSString pathWithComponents:pathComponents] stringByStandardizingPath];
}


-(void)deleteFileAtPath:(NSString *)path
{
    if( ![[NSFileManager defaultManager] removeItemAtPath:path error:NULL] )
    {
        NSLog( @"deleteFileAtPath %@ failed!", path );
    }
}


-(BOOL)doesFileExistAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}


-(NSArray *)getAllDocumentsSortedByModified
{
    // courtesy of http://stackoverflow.com/questions/1523793/get-directory-contents-in-date-modified-order
    
    // Application documents directory
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsURL
                                                              includingPropertiesForKeys:@[NSURLContentModificationDateKey]
                                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                   error:nil];
    NSArray *sortedContent = [directoryContent sortedArrayUsingComparator:
                              ^(NSURL *file1, NSURL *file2)
                              {
                                  // compare
                                  NSDate *file1Date;
                                  [file1 getResourceValue:&file1Date forKey:NSURLContentModificationDateKey error:nil];
                                  
                                  NSDate *file2Date;
                                  [file2 getResourceValue:&file2Date forKey:NSURLContentModificationDateKey error:nil];
                                  
                                  // Ascending:
                                  //return [file1Date compare: file2Date];
                                  // Descending:
                                  return [file2Date compare: file1Date];
                              }];
    return sortedContent;
}


-(void)addAllLevelNamesTo:(NSMutableArray *)array
{
    NSArray *allFiles = [self getAllDocumentsSortedByModified];
    
    for( int i = 0; i < [allFiles count]; ++i )
    {
        NSURL *thisUrl = (NSURL *)[allFiles objectAtIndex:i];
        NSString *thisPath = thisUrl.path;
        if( [thisPath hasSuffix:LEVEL_EXTENSION] )
        {
            NSString *justFilename = [[thisPath lastPathComponent] stringByDeletingPathExtension];
            [array addObject:justFilename];
        }
    }
}

@end
