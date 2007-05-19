//
//  AppTracker.h
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Growl-WithInstaller/GrowlApplicationBridge.h"

@interface AppTracker : NSObject <GrowlApplicationBridgeDelegate> {

	NSArray *currentAppsArray;
	NSMutableDictionary *currentApps;
	NSMutableDictionary *activityTimes;

	NSMutableSet *ignored;

	BOOL isGrowlReady;
}

-(NSArray*)currentApps;
-(NSDictionary *)objectAtIndex:(int)idx;

-(void)ignoreApp:(NSDictionary *)app;
-(void)dontIgnoreApp:(NSDictionary *)app;
-(BOOL)isIgnored:(NSDictionary *)app;

@end
