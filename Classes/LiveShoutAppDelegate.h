//
//  LiveShoutAppDelegate.h
//  LiveShout
//
//  Created by Niall Kelly on 24/05/2010.
//  Copyright Ecliptic Labs 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LiveShoutViewController;

@interface LiveShoutAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    LiveShoutViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LiveShoutViewController *viewController;

@end

