//
//  Controller.h
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Controller : NSObject {

	IBOutlet NSMenu *appMenu;
	IBOutlet NSPanel *prefs;

	NSArray *currentAppsArray;
	NSMutableSet *ignored;
	NSMutableDictionary *currentApps;
	NSMutableDictionary *activityTimes;

	double maxAge;
}

-(NSArray*)currentApps;

@end
