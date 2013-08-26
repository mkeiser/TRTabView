//
//  TRViewController+DebugActions.m
//  TRTabViewExample
//
//  Created by Matthias Keiser on 24.08.13.
//  Copyright (c) 2013 Matthias Keiser. All rights reserved.
//	matthias@tristan-inc.com
//

#import "TRViewController+DebugActions.h"

typedef void(^TRBlockAlertCompletion)(UIAlertView *alertView, NSInteger clickedButtonIndex);

@interface TRBlockAlert : UIAlertView

@property (copy, nonatomic) TRBlockAlertCompletion completion;

@end

@implementation TRBlockAlert;

@end

@implementation TRViewController (DebugActions)

- (IBAction)reloadTabs:(id)sender {
	
	self.model = nil;
	self.globalTabCount = 0;
	[self.tabView reloadTabs];
}

- (IBAction)minTabWidthAction:(id)sender {
	
	[self showAlertTitle:@"Minimum Tab Width" oldValue:@(self.tabView.minimumTabWidth) completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.minimumTabWidth = [[alertView textFieldAtIndex:0].text doubleValue];
	}];
}

- (IBAction)maxNumVisibleTabsAction:(id)sender {
	
	[self showAlertTitle:@"Max. number Visible Tabs" oldValue:@(self.tabView.maximumNumberVisibleTabs) completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.maximumNumberVisibleTabs = [[alertView textFieldAtIndex:0].text integerValue];
	}];
}

- (IBAction)maxTabWidthAction:(id)sender {
	
	[self showAlertTitle:@"Maximum Tab Width" oldValue:@(self.tabView.maximumTabWidth) completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.maximumTabWidth = [[alertView textFieldAtIndex:0].text doubleValue];
	}];
}

- (IBAction)showAddButtonAction:(id)sender {
	
	[self showBoolAlertTitle:@"Show Add Button" oldValue:(self.tabView.showAddButton ? @"YES" : @"NO") completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.showAddButton = clickedButtonIndex == 1 ? YES : NO;
	}];
}

- (IBAction)tabReorderingAction:(id)sender {
	
	[self showBoolAlertTitle:@"Allow Tab Reordering" oldValue:(self.tabView.allowTabReordering ? @"YES" : @"NO") completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.allowTabReordering = clickedButtonIndex == 1 ? YES : NO;
	}];
}


- (IBAction)deleteModeAction:(id)sender {
	
	NSString *valueName;
	
	switch (self.tabView.deleteButtonMode) {
		case TRTabViewButtonModeNever:
			valueName = @"TRTabViewButtonModeNever";
			break;
		case TRTabViewButtonModeSelected:
			valueName = @"TRTabViewButtonModeSelected";
			break;
		case TRTabViewButtonModeSelectedExceptLast:
			valueName = @"TRTabViewButtonModeSelectedExceptLast";
			break;
		case TRTabViewButtonModeAlways:
			valueName = @"TRTabViewButtonModeAlways";
			break;
		default:
			valueName = @"INVALID";
			break;
	}
	[self showOptionsAlertTitle:[NSString stringWithFormat:@"Delete Mode (currently %@)", valueName] options:@[@"TRTabViewButtonModeNever", @"TRTabViewButtonModeSelected", @"TRTabViewButtonModeSelectedExceptLast", @"TRTabViewButtonModeAlways"] oldValue:nil completion:^(UIAlertView *alertView, NSInteger clickedButtonIndex) {
		
		self.tabView.deleteButtonMode = (TRTabViewButtonMode)(clickedButtonIndex - 1);
	}];
}

- (void)showAlertTitle:(NSString *)title oldValue:(id)oldValue completion:(TRBlockAlertCompletion)completion {
	
	TRBlockAlert *alertView = [[TRBlockAlert alloc] initWithTitle:title message:[NSString stringWithFormat:@"currently: %@", oldValue] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	alertView.delegate = self;
	alertView.completion = completion;
	[alertView show];
}

- (void)showBoolAlertTitle:(NSString *)title oldValue:(id)oldValue completion:(TRBlockAlertCompletion)completion {
	
	TRBlockAlert *alertView = [[TRBlockAlert alloc] initWithTitle:title message:[NSString stringWithFormat:@"currently: %@", oldValue] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES", @"NO", nil];
	alertView.delegate = self;
	alertView.completion = completion;
	[alertView show];
}

- (void)showOptionsAlertTitle:(NSString *)title options:(NSArray *)options oldValue:(id)oldValue completion:(TRBlockAlertCompletion)completion {
	
	TRBlockAlert *alertView = [[TRBlockAlert alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
	
	if (oldValue)
		alertView.message = [NSString stringWithFormat:@"currently: %@", oldValue];
	
	for (NSString *title in options) {
		
		[alertView addButtonWithTitle:title];
	}
	
	alertView.delegate = self;
	alertView.completion = completion;
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		return;
	}
	
	if ([alertView isKindOfClass:[TRBlockAlert class]]) {
		
		TRBlockAlert *blockAlert = (TRBlockAlert *)alertView;
		blockAlert.completion(blockAlert, buttonIndex);
	}	
}
@end
