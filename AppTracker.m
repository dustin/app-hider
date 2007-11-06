//
//  AppTracker.m
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import "AppTracker.h"


@implementation AppTracker

-(NSArray *)sortDescriptors {
	NSSortDescriptor *sdesc=[[NSSortDescriptor alloc]
		initWithKey:@"NSApplicationName" ascending:YES
		selector:@selector(caseInsensitiveCompare:)];
	[sdesc autorelease];
	return [NSArray arrayWithObject: sdesc];
}

-(NSArray*)currentApps {
	return currentAppsArray;
}

-(void)updateArray {
	if(currentAppsArray != nil) {
		[currentAppsArray release];
	}
	NSMutableArray *arry=[[NSMutableArray alloc] initWithCapacity: [currentApps count]];
	[arry addObjectsFromArray: [currentApps allValues]];
	[arry sortUsingDescriptors: [self sortDescriptors]];
	currentAppsArray=[[NSArray alloc] initWithArray: arry];
	[arry release];
}

-(NSData *)getAppIcon:(NSString *)path {
	NSData *rv=nil;
	if(path != nil) {
		NSImage *icon=[[NSWorkspace sharedWorkspace] iconForFile: path];
		// This avoids a minor memory leak due to the image being cached.
		[icon setCachedSeparately:YES];
		[icon setCacheMode:NSImageCacheNever];
		rv=[icon TIFFRepresentation];
	}
	return rv;
}

-(void)appLaunched:(NSNotification*)notification {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	[self willChangeValueForKey:@"currentApps"];
	id anAppDict=[notification userInfo];

	[GrowlApplicationBridge
        notifyWithTitle:[NSString stringWithFormat: @"Launched %@", [anAppDict valueForKey:@"NSApplicationName"]]
        description:[NSString stringWithFormat: @"Detected launch of %@", [anAppDict valueForKey:@"NSApplicationPath"]]
        notificationName:@"AppLaunched"
        iconData:[self getAppIcon: [anAppDict objectForKey:@"NSApplicationPath"]]
        priority:0
        isSticky:NO
        clickContext:nil];

	[currentApps setObject:anAppDict forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	NSDate *now=[[NSDate alloc] init];
	[activityTimes setObject:now forKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	[now release];

	[self updateArray];
	[self didChangeValueForKey:@"currentApps"];
	[pool release];
}

-(void)appQuit:(NSNotification*)notification {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	[self willChangeValueForKey:@"currentApps"];
	id anAppDict=[notification userInfo];

	[GrowlApplicationBridge
        notifyWithTitle:[NSString stringWithFormat: @"Quit %@", [anAppDict valueForKey:@"NSApplicationName"]]
        description:[NSString stringWithFormat: @"Detected quit of %@", [anAppDict valueForKey:@"NSApplicationPath"]]
        notificationName:@"AppQuit"
        iconData:[self getAppIcon: [anAppDict objectForKey:@"NSApplicationPath"]]
        priority:0
        isSticky:NO
        clickContext:[anAppDict objectForKey:@"NSApplicationPath"]];

	[currentApps removeObjectForKey:[anAppDict valueForKey:@"NSApplicationPath"]];
	[activityTimes removeObjectForKey:[anAppDict valueForKey:@"NSApplicationPath"]];

	[self updateArray];
	[self didChangeValueForKey:@"currentApps"];
		[pool release];
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
	[self updateArray];
	[self didChangeValueForKey:@"currentApps"];
}

-(void)checkCurrentApp:(NSTimer*)timer {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSDictionary *active=[[NSWorkspace sharedWorkspace] activeApplication];
	// When this app launches, active is nil.
	if(active != nil) {
		[activityTimes setObject:[NSDate date] forKey:[active valueForKey:@"NSApplicationPath"]];
	}
	// NSLog(@"%@ is active", [active valueForKey:@"NSApplicationPath"]);
	[pool release];
}

-(void)hideApp:(NSDictionary*)app name:(NSString *)name {
    [GrowlApplicationBridge
        notifyWithTitle:[NSString stringWithFormat: @"Hiding %@", name]
        description:[NSString stringWithFormat: @"Hiding application %@", name]
        notificationName:@"Hiding"
        iconData:[self getAppIcon:[app objectForKey:@"NSApplicationPath"]]
        priority:0
        isSticky:NO
        clickContext:name];

	NSAppleScript *script=[[NSAppleScript alloc] initWithSource:
		[NSString stringWithFormat:@"tell application \"System Events\" to set visible of process id %@ to false",
			[app valueForKey:@"NSApplicationProcessSerialNumberLow"]]];
	NSDictionary *err=nil;
	[script executeAndReturnError: &err];
	if(err != nil) {
		NSLog(@"Got error:  %@", err);
	}
	[script release];
}

-(void)checkIdleApps:(NSTimer*)timer {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	double maxAge=(double)[[NSUserDefaults standardUserDefaults] floatForKey:@"freq"];
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
				[self hideApp: app name:nm];
				// Take it out of the list we're enumerating
				[activityTimes removeObjectForKey:nm];
			}
		}
	}

	[pool release];
}

-(void)updateDefaults {
	[[NSUserDefaults standardUserDefaults]
		setObject:[ignored allObjects] forKey:@"ignored"];
}

-(void)ignoreApp:(NSDictionary *)app {
	[ignored addObject: [app valueForKey:@"NSApplicationPath"]];
	[self updateDefaults];
}

-(void)dontIgnoreApp:(NSDictionary *)app {
	[ignored removeObject: [app valueForKey:@"NSApplicationPath"]];
	[self updateDefaults];
}

-(BOOL)isIgnored:(NSDictionary *)app {
	return [ignored containsObject:[app valueForKey:@"NSApplicationPath"]];
}

-(NSDictionary *)objectAtIndex:(int)idx {
	return [[[currentAppsArray objectAtIndex: idx] retain] autorelease];
}

-(void)awakeFromNib {
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	currentApps = [[NSMutableDictionary alloc] initWithCapacity:100];
	activityTimes = [[NSMutableDictionary alloc] initWithCapacity:100];
	ignored = [[NSMutableSet alloc] initWithCapacity:100];
	[ignored addObjectsFromArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"ignored"]];

    // Setup growl delegation
    [GrowlApplicationBridge setGrowlDelegate:self];

	[self initAppList];

	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCurrentApp:)
		userInfo:nil repeats:YES];
	[NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(checkIdleApps:)
		userInfo:nil repeats:YES];

	[pool release];
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSArray *allNotifications=[[NSArray alloc] initWithObjects:
        @"Hiding", @"AppLaunched", @"AppQuit", nil];
    NSArray *defaultNotifications=[[NSArray alloc] initWithObjects:
        @"Hiding", nil];

    NSDictionary *dict=[[NSDictionary alloc] initWithObjectsAndKeys:
        allNotifications, GROWL_NOTIFICATIONS_ALL,
        defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
        nil];

    [allNotifications release];
    [defaultNotifications release];

	// Autorelease everything that was built to be autoreleased
	[pool release];
	// This is the return value, so need to set it up for autorelease after releasing the pool
    [dict autorelease];
    return(dict);
}

-(NSString *)applicationNameForGrowl
{
    return(@"AppHider");
}

-(void)growlNotificationWasClicked:(id)clickContext
{
    NSLog(@"Hey!  Someone clicked on the notification:  %@", clickContext);
	[[NSWorkspace sharedWorkspace] launchApplication:clickContext];
}

@end
