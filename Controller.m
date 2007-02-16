//
//  Controller.m
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import "Controller.h"


@implementation Controller

-(NSArray*)currentApps {
	return [currentApps allValues];
}

-(void)appLaunched:(NSNotification*)notification {
	[self willChangeValueForKey:@"currentApps"];
	id anAppDict=[notification userInfo];
	[currentApps setObject:anAppDict forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	[self didChangeValueForKey:@"currentApps"];
}

-(void)appQuit:(NSNotification*)notification {
	[self willChangeValueForKey:@"currentApps"];
	id anAppDict=[notification userInfo];
	[currentApps removeObjectForKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	[self didChangeValueForKey:@"currentApps"];
}

-(void)doubleClicked:(id)something {
	NSLog(@"Double clicked with %@", [something valueForKey:@"NSApplicationName"]);
	NSAppleScript *script=[[NSAppleScript alloc] initWithSource:
		[NSString stringWithFormat:@"tell application \"System Events\" to set visible of process id %@ to false",
			[something valueForKey:@"NSApplicationProcessSerialNumberLow"]]];
	NSDictionary *err=nil;
	[script executeAndReturnError: &err];
	if(err != nil) {
		NSLog(@"Got error:  %@", err);
	}
}

-(void)awakeFromNib {
	currentApps = [[NSMutableDictionary alloc] initWithCapacity:100];
	[self willChangeValueForKey:@"currentApps"];
	NSEnumerator *e=[[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	id anAppDict;
	while((anAppDict = [e nextObject]) != nil) {
		[currentApps setObject:anAppDict forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	}
	[self didChangeValueForKey:@"currentApps"];

	// Register to hear about new apps being launched
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver:self selector:@selector(appLaunched:)
		name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver:self selector:@selector(appQuit:)
		name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}

@end
