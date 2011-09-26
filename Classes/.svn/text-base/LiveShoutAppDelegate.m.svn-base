//
//  LiveShoutAppDelegate.m
//  LiveShout
//
//  Created by Niall Kelly on 24/05/2010.
//  Copyright Ecliptic Labs 2010. All rights reserved.
//

#import "LiveShoutAppDelegate.h"
#import "LiveShoutViewController.h"

@implementation LiveShoutAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
	window.backgroundColor = [UIColor blackColor];
    [window addSubview:viewController.view];
//	viewController.view.backgroundColor = [UIColor redColor];
	
    [window makeKeyAndVisible];
	
	
	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
