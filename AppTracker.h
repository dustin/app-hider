//
//  AppTracker.h
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppTracker : NSObject {

	NSArray *currentAppsArray;
	NSMutableDictionary *currentApps;
	NSMutableDictionary *activityTimes;

	NSMutableSet *ignored;
}

-(NSArray*)currentApps;
-(NSDictionary *)objectAtIndex:(int)idx;

-(void)ignoreApp:(NSDictionary *)app;
-(void)dontIgnoreApp:(NSDictionary *)app;
-(BOOL)isIgnored:(NSDictionary *)app;

@end
