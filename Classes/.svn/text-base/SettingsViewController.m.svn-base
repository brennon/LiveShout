//
//  SettingsViewController.m
//  LiveShout
//
//  Created by Niall Kelly on 11/06/2010.
//  Copyright 2010 Ecliptic Labs. All rights reserved.
//

#import "SettingsViewController.h"
#include "liveshout.h"


@implementation SettingsViewController
@synthesize delegate;

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	float storedQuality = [[NSUserDefaults standardUserDefaults] floatForKey:@"LS_VORBIS_QUALITY_USER_KEY"];
	
	if (storedQuality != 0.0) 
	{
		qualitySlider.value = storedQuality;
		qualityValueLabel.text = [NSString stringWithFormat:@"Stream Quality : %0.1f", storedQuality];
	}
	
	BOOL isStereo = [[NSUserDefaults standardUserDefaults] boolForKey:@"LS_IS_FOR_STEREO_CONNECTION"];
	channelSwitch.on = isStereo;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	UITextField *addressTextField = (UITextField *)[self.view viewWithTag:2];
	[addressTextField becomeFirstResponder];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

-(IBAction)qualitySliderAction:(UISlider *)slider {

	NSString *floatVal = [NSString stringWithFormat:@"%0.1f", slider.value];
	qualityValueLabel.text = [NSString stringWithFormat:@"Stream Quality : %@", floatVal];
	[[NSUserDefaults standardUserDefaults] setFloat:[floatVal floatValue] forKey:@"LS_VORBIS_QUALITY_USER_KEY"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

	[textField resignFirstResponder];
	
	if (textField.tag == 2) {
		
		
	
		UITextField *nextTextField = (UITextField *)[self.view viewWithTag:3];
		[nextTextField becomeFirstResponder];
		return YES;
		
	} 
	
	UITextField *addressTextField = (UITextField *)[self.view viewWithTag:2];
	
	NSArray *objects = [NSArray arrayWithObjects:addressTextField.text, textField.text, nil];
	NSArray *keys = [NSArray arrayWithObjects:@"address", @"mount", nil];
	NSDictionary *newSettings = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LS_AddressAndPortSettingsDidChangeNotification" object:newSettings];
	return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	if (indexPath.row != 2) {
		
		NSString *cellID = @"ELTextFieldTableViewCell";
		
		ELTextFieldTableViewCell *cell = (ELTextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell)
			cell = [[[ELTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		
		cell.textField.tag = indexPath.row+2;
		cell.textField.delegate = self;
		
		if (indexPath.row == 0) {
			
			cell.textField.text = @LS_ICECAST_IP;
			cell.textLabel.text = @"Address";

		} else {
			
			cell.textField.text = @LS_ICECAST_MOUNTPOINT;
			cell.textLabel.text = @"Mount";
		}
		
		return cell;
		
	} else {
		
		NSString *cellID = @"ChannelSwitchCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		
		if (!cell) 
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		
		cell.textLabel.text = @"Stereo";
		cell.textLabel.textColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		cell.textLabel.font = [UIFont systemFontOfSize:15.0f];
		cell.accessoryView = channelSwitch;
		
		return cell;
	}
}

-(IBAction)channelSwitchAction:(UISwitch *)switcher {
	[[NSUserDefaults standardUserDefaults] setBool:switcher.on forKey:@"LS_IS_FOR_STEREO_CONNECTION"];
}

- (IBAction)backButtonAction {
	
	UITextField *addressTextField = (UITextField *)[self.view viewWithTag:2];
	UITextField *mountTextField = (UITextField *)[self.view viewWithTag:3];
	
	if ([addressTextField isFirstResponder])
		[addressTextField resignFirstResponder];
	else if ([mountTextField isFirstResponder])
		[mountTextField resignFirstResponder];
	
	[self.delegate settingsViewControllerDidFinish:self];	
}


@end
