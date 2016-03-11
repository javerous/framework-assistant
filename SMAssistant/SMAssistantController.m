/*
 *  SMAssistantController.m
 *
 *  Copyright 2016 Avérous Julien-Pierre
 *
 *  This file is part of SMAssistant.
 *
 *  SMAssistant is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  SMAssistant is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with SMAssistant.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "SMAssistantController.h"

#import "SMAssistantPanel.h"


NS_ASSUME_NONNULL_BEGIN


/*
** Macros
*/
#pragma mark - Macros

#define SMLocalizedString(key, comment) \
	[[NSBundle bundleForClass:[SMAssistantController class]] localizedStringForKey:(key) value:@"" table:(nil)]



/*
** SMAssistantWindowController - Interface
*/
#pragma mark - SMAssistantWindowController - Interface

@interface SMAssistantWindowController : NSWindowController <SMAssistantProxy>
{
	NSArray					*_panels;
	NSMutableDictionary		*_panelsClass;
	NSMutableDictionary		*_panelsInstances;

	id <SMAssistantPanel>	_currentPanel;
	
	NSString				*_nextID;
	BOOL					_isLast;
	BOOL					_nextDisabled;
	
	SMAssistantCompletionBlock	_handler;
	
	SMAssistantWindowController *_selfRetain;
}

// -- Instance --
- (id)initWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback;

// -- Properties --
@property (strong, nonatomic)	IBOutlet NSTextField	*mainTitle;
@property (strong, nonatomic)	IBOutlet NSView			*mainView;
@property (strong, nonatomic)	IBOutlet NSButton		*cancelButton;
@property (strong, nonatomic)	IBOutlet NSButton		*nextButton;

// -- IBAction --
- (IBAction)doCancel:(id)sender;
- (IBAction)doNext:(id)sender;

// -- Tools --
- (void)_switchToPanel:(NSString *)panelID withContent:(nullable id)content;
- (void)_checkNextButton;

@end



/*
** SMAssistantController
*/
#pragma mark - SMAssistantController

@implementation SMAssistantController

+ (void)startAssistantWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback
{
	SMAssistantWindowController *assistant = [[SMAssistantWindowController alloc] initWithPanels:panels completionHandler:callback];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[assistant showWindow:nil];
	});
}

@end



/*
** SMAssistantWindowController
*/
#pragma mark - SMAssistantWindowController

@implementation SMAssistantWindowController


/*
** SMAssistantWindowController - Instance
*/
#pragma mark - SMAssistantWindowController - Instance

- (id)initWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback
{
	self = [super initWithWindowNibName:@"AssistantWindow"];
	
	if (self)
	{
		NSAssert([panels count] != 0, @"'panels' array shouldn't be nil and should contain at least one item");
		
		// Handle callback.
		_handler = callback;
		
		// Create containers.
		_panelsClass = [[NSMutableDictionary alloc] init];
		_panelsInstances = [[NSMutableDictionary alloc] init];
		
		// Handle pannels class.
		for (Class <SMAssistantPanel> class in panels)
			[_panelsClass setObject:class forKey:[class panelIdentifier]];
		
		// Handle panels.
		_panels = panels;
		
		// Self retain.
		_selfRetain = self;
	}
	
	return self;
}

- (void)dealloc
{
	//NSLog(@"SMAssistantWindowController dealloc");
}



/*
** SMAssistantWindowController - NSWindowController
*/
#pragma mark - SMAssistantWindowController - NSWindowController

- (void)windowDidLoad
{
	// Show first pannel.
	Class <SMAssistantPanel> class = _panels[0];
	
	[self _switchToPanel:[class panelIdentifier] withContent:nil];
	
	// Show window.
	[self.window center];
}



/*
** SMAssistantWindowController - IBAction
*/
#pragma mark - SMAssistantWindowController - IBAction

- (IBAction)doCancel:(id)sender
{
	// Close window.
	[self close];

	// Call cancel handler.
	if (_handler)
		_handler(SMAssistantCompletionTypeCanceled, nil);

	// Remove self retain.
	_selfRetain = nil;
}

- (IBAction)doNext:(id)sender
{
	if (!_currentPanel)
	{
		NSBeep();
		return;
	}
	
	id content = [_currentPanel panelContent];

	if (_isLast)
	{
		if (_handler)
			_handler(SMAssistantCompletionTypeDone, content);
		
		_currentPanel.panelProxy = (id)[NSNull null];
		_currentPanel.panelPreviousContent = nil;
		
		_handler = nil;
		_currentPanel = nil;

		[self close];
		
		_selfRetain = nil;
	}
	else
	{
		// Switch.
		[self _switchToPanel:_nextID withContent:content];
	}
}



/*
** SMAssistantWindowController - Tools
*/
#pragma mark - SMAssistantWindowController - Tools

- (void)_switchToPanel:(NSString *)panelID withContent:(nullable id)content
{
	// > main queue <
	
	// Check that the panel is not already loaded.
	if ([[[_currentPanel class] panelIdentifier] isEqualToString:panelID])
		return;
	
	// Remove it from current view.
	[[_currentPanel panelView] removeFromSuperview];
	
	_currentPanel.panelProxy = (id)[NSNull null];
	_currentPanel.panelPreviousContent = nil;
	
	// Get the panel instance.
	id <SMAssistantPanel> panel = _panelsInstances[panelID];
	
	if (!panel)
	{
		Class <SMAssistantPanel> class = _panelsClass[panelID];
		
		panel = [class panelInstance];
		
		if (panel)
			_panelsInstances[panelID] = panel;
	}
	
	// Set the view
	if (panel)
		[_mainView addSubview:[panel panelView]];
	
	// Set the title
	_mainTitle.stringValue = [[panel class] panelTitle];
	
	// Set the proxy
	_nextID = nil;
	_isLast = YES;
	[_nextButton setEnabled:NO];
	[_nextButton setTitle:SMLocalizedString(@"ac_next_finish", @"")];
	
	panel.panelProxy = self;
	panel.panelPreviousContent = content;
	
	[panel panelDidAppear];
	
	// Hold the panel
	_currentPanel = panel;
}

- (void)_checkNextButton
{
	// > main queue <
	
	if (_nextDisabled)
	{
		[_nextButton setEnabled:NO];
		return;
	}
	
	if (_isLast)
		[_nextButton setEnabled:YES];
	else
	{
		Class class = _panelsClass[_nextID];
		
		[_nextButton setEnabled:(class != nil)];
	}
}



/*
** SMAssistantWindowController - Proxy
*/
#pragma mark - SMAssistantWindowController - Proxy

- (void)setNextPanelID:(nullable NSString *)panelID
{
	dispatch_async(dispatch_get_main_queue(), ^{

		_nextID = panelID;
		
		[self _checkNextButton];
	});
}

- (void)setIsLastPanel:(BOOL)last
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		_isLast = last;
		
		if (_isLast)
			[_nextButton setTitle:SMLocalizedString(@"ac_next_finish", @"")];
		else
			[_nextButton setTitle:SMLocalizedString(@"ac_next_continue", @"")];
		
		[self _checkNextButton];
	});
}

- (void)setDisableContinue:(BOOL)disabled
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		_nextDisabled = disabled;
		
		[self _checkNextButton];
	});
}

@end


NS_ASSUME_NONNULL_END
