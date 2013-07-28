//
//  EDocPropsViewController.h
//  JumpProto
//
//  Created by Gideon Goodwin on 1/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LevelUtil.h"
#import "EDoc.h"

@interface EDocPropsViewController : UIViewController
{
}

@property (nonatomic, retain) IBOutlet UITextField *levelNameTextField;
@property (nonatomic, retain) IBOutlet UITextField *tagsTextField;

@property (nonatomic, retain) EGridDocument *doc;


-(id)initWithNibName:(NSString *)nibNameIn bundle:(NSBundle *)bundleIn doc:(EGridDocument *)docIn;

-(void)updateValuesFromDoc;

@end
