//
//  SettingsViewController.h
//  LiveShout
//
//  Created by Niall Kelly on 11/06/2010.
//  Copyright 2010 Ecliptic Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELTextFieldTableViewCell.h"

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
	
	id <SettingsViewControllerDelegate> delegate;
	
	IBOutlet UILabel	*qualityValueLabel;
	IBOutlet UISlider	*qualitySlider;
	IBOutlet UISwitch	*channelSwitch;
}

@property (nonatomic, assign) id <SettingsViewControllerDelegate> delegate;

-(IBAction)backButtonAction;
-(IBAction)qualitySliderAction:(UISlider *)slider;
-(IBAction)channelSwitchAction:(UISwitch *)switcher;

@end


@protocol SettingsViewControllerDelegate
- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller;
@end
