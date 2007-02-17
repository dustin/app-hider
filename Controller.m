//
//  Controller.m
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import "Controller.h"


@implementation Controller

-(NSArray *)sortDescriptors {
	NSSortDescriptor *sdesc=[[NSSortDescriptor alloc]
		initWithKey:@"NSApplicationName" ascending:YES
		selector:@selector(caseInsensitiveCompare:)];
	[[sdesc retain] autorelease];
	return [NSArray arrayWithObject: sdesc];
}

-(NSArray*)currentApps {
	return currentAppsArray;
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

-(void)hideApp:(NSDictionary*)app {
	NSAppleScript *script=[[NSAppleScript alloc] initWithSource:
		[NSString stringWithFormat:@"tell application \"System Events\" to set visible of process id %@ to false",
			[app valueForKey:@"NSApplicationProcessSerialNumberLow"]]];
	NSDictionary *err=nil;
	[script executeAndReturnError: &err];
	if(err != nil) {
		NSLog(@"Got error:  %@", err);
	}
}

-(void)doubleClicked:(id)something {
	NSLog(@"Double clicked with %@", [something valueForKey:@"NSApplicationName"]);
	[self hideApp: something];
}

-(void)checkCurrentApp:(NSTimer*)timer {
	NSDictionary *active=[[NSWorkspace sharedWorkspace] activeApplication];
	// When this app launches, active is nil.
	if(active != nil) {
		NSDate *now=[[NSDate alloc] init];
		[activityTimes setObject:now forKey:[active valueForKey:@"NSApplicationPath"]];
		[now release];
	}
	// NSLog(@"%@ is active", [active valueForKey:@"NSApplicationPath"]);
}

-(void)checkIdleApps:(NSTimer*)timer {
	NSEnumerator *enumerator = [activityTimes keyEnumerator];
    id nm;
	while ((nm = [enumerator nextObject]) != nil) {
		NSDate *lastUpdate=[activityTimes valueForKey:nm];
		if(lastUpdate != nil) {
			NSDictionary *app=[currentApps valueForKey:nm];
			// NSLog(@"Interval since %@:  %f", nm, [lastUpdate timeIntervalSinceNow]);
			if([lastUpdate timeIntervalSinceNow] + maxAge < 0
				&& ![ignored containsObject: [app valueForKey:@"NSApplicationPath"]]) {
				NSLog(@"Hiding %@", nm);
				[self hideApp: app];
				// Take it out of the list we're enumerating
				[activityTimes removeObjectForKey:nm];
			}
		}
	}
}

-(void)toggleItem:(id)sender {
	NSDictionary *p=[currentAppsArray objectAtIndex:[sender tag]];
	NSLog(@"Changing ignore state of %@", [p valueForKey:@"NSApplicationName"]);
	if([sender state] == NSOffState) {
		[ignored addObject: [p valueForKey:@"NSApplicationPath"]];
		[sender setState: NSOnState];
	} else {
		[ignored removeObject: [p valueForKey:@"NSApplicationPath"]];
		[sender setState: NSOffState];
	}
	[[NSUserDefaults standardUserDefaults]
		setObject:[ignored allObjects] forKey:@"ignored"];
}

-(void)updateCurrentAppsArray {
	if(currentAppsArray != nil) {
		[currentAppsArray release];
	}
	NSMutableArray *arry=[[NSMutableArray alloc] initWithCapacity: [currentApps count]];
	[arry addObjectsFromArray: [currentApps allValues]];
	[arry sortUsingDescriptors: [self sortDescriptors]];
	currentAppsArray=[[NSArray alloc] initWithArray: arry];
	[arry release];
}

-(void)observeValueForKeyPath:(NSString *)path ofObject:(id)object
	change:(NSDictionary*)change context:(void *)context {

	[self updateCurrentAppsArray];

	// Remove existing items -- except quit at the bottom.
	while([appMenu numberOfItems] > 0) {
		[appMenu removeItemAtIndex: 0];
	}

	NSEnumerator *e = [currentAppsArray objectEnumerator];
    id anAppDict;
	int i=0;
	while((anAppDict = [e nextObject]) != nil) {
		NSMenuItem *item=[[NSMenuItem alloc]
			initWithTitle: [anAppDict valueForKey:@"NSApplicationName"]
			action:@selector(toggleItem:) keyEquivalent:@""];
		[item setEnabled:YES];
		[item setState: [ignored containsObject:[anAppDict valueForKey:@"NSApplicationPath"]]
			? NSOnState : NSOffState];
		[item setTarget:self];
		[item setTag:i++];
		[appMenu addItem:item];
		[item release];
	}

	// Add some common items
	[appMenu addItem: [NSMenuItem separatorItem]];

	// Prefs
	NSMenuItem *prefsItem=[[NSMenuItem alloc]
		initWithTitle: @"Preferences"
		action:@selector(makeKeyAndOrderFront:) keyEquivalent:@";"];
	[prefsItem setTarget: prefs];
	[prefsItem setEnabled:YES];
	[appMenu addItem: prefsItem];
	[prefsItem release];

	// Quit 
	NSMenuItem *quitItem=[[NSMenuItem alloc]
		initWithTitle: @"Quit"
		action:@selector(terminate:) keyEquivalent:@""];
	[quitItem setTarget: NSApp];
	[quitItem setEnabled:YES];
	[appMenu addItem: quitItem];
	[quitItem release];
}

-(void)initAppList {
	[self willChangeValueForKey:@"currentApps"];
	NSEnumerator *e=[[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	id anAppDict;
	NSDate *now=[[NSDate alloc] init];
	while((anAppDict = [e nextObject]) != nil) {
		[currentApps setObject:anAppDict forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
		[activityTimes setObject:now forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
		
	}
	[now release];
	[self didChangeValueForKey:@"currentApps"];
}

-(void)initStatusBar {
	NSStatusItem *newItem=[[NSStatusBar systemStatusBar] statusItemWithLength: 40.0];
	NSLog(@"Initializing %@ with length %f", newItem, [newItem length]);
	[newItem setTitle: @"App Hider"];
	[newItem setMenu: appMenu];
	[newItem setEnabled:YES];
	[newItem retain];
}

-(void)setDefaultDefaults {
	[[NSUserDefaults standardUserDefaults]
		registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:180.0], @"freq",
			[NSArray array], @"ignored", nil, nil]];
	// This looks dumb, but preferences doesn't work correctly without it
	[[NSUserDefaults standardUserDefaults]
		setFloat:[[NSUserDefaults standardUserDefaults] floatForKey:@"freq"]
		forKey:@"freq"];
}

-(void)awakeFromNib {
	[self setDefaultDefaults];
	maxAge=(double)[[NSUserDefaults standardUserDefaults] floatForKey:@"freq"];
	NSLog(@"maxAge=%f", maxAge);

	currentApps = [[NSMutableDictionary alloc] initWithCapacity:100];
	activityTimes = [[NSMutableDictionary alloc] initWithCapacity:100];
	ignored = [[NSMutableSet alloc] initWithCapacity:100];
	[ignored addObjectsFromArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"ignored"]];

	[self addObserver:self forKeyPath:@"currentApps" options:NSKeyValueObservingOptionNew context:nil];

	[self initAppList];
	[self initStatusBar];

	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCurrentApp:)
		userInfo:nil repeats:YES];
	[NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkIdleApps:)
		userInfo:nil repeats:YES];

	// Register to hear about new apps being launched
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver:self selector:@selector(appLaunched:)
		name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter]
		addObserver:self selector:@selector(appQuit:)
		name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}

@end
