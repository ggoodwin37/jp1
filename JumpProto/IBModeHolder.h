//
//  IBModeHolder.h
//  JumpProto
//
//  Created by Gideon iOS on 9/17/13.
//
//

#import <Foundation/Foundation.h>

@protocol IBModeHolder <NSObject>

-(BOOL)isBModeActive;
-(void)setBModeActive:(BOOL)bModeActive;

@end
