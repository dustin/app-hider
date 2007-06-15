//
//  Controller.h
//  AppHider
//
//  Created by Dustin Sallings on 2007/2/16.
//  Copyright 2007 Dustin Sallings <dustin@spy.net>. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppTracker.h>

#import "Sparkle/SUUPdater.h"

@interface Controller : NSObject {

	IBOutlet NSMenu *appMenu;
	IBOutlet NSPanel *prefs;

	IBOutlet NSStatusItem *statusItem;

	IBOutlet AppTracker *tracker;
	IBOutlet SUUpdater *sparkleUpdater;
}

-(IBAction)changeLoginItems:(id)sender;

@end
