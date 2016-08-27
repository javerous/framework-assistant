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
** Globals
*/
#pragma mark - Globals

static char gSpecificQueueKey = '\0';
static char gMainQueueTag = '\0';



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
	BOOL					_nextDisabled;
	
	SMAssistantCompletionBlock	_handler;
	
	SMAssistantWindowController *_selfRetain;
}

// -- Instance --
- (instancetype)initWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithWindow:(nullable NSWindow *)window NS_UNAVAILABLE;

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
	CFRunLoopRef runLoop = CFRunLoopGetMain();
	
	CFRunLoopPerformBlock(runLoop, kCFRunLoopCommonModes, ^{
		
		SMAssistantWindowController *assistant = [[SMAssistantWindowController alloc] initWithPanels:panels completionHandler:callback];

		assistant.window.preventsApplicationTerminationWhenModal = YES;
		assistant.window.animationBehavior = NSWindowAnimationBehaviorDocumentWindow;
		
		[[NSApplication sharedApplication] runModalForWindow:assistant.window];
	});
	
	CFRunLoopWakeUp(runLoop);
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

- (instancetype)initWithPanels:(NSArray *)panels completionHandler:(nullable SMAssistantCompletionBlock)callback
{
	self = [super initWithWindow:nil];
	
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
			_panelsClass[[class panelIdentifier]] = class;
		
		// Handle panels.
		_panels = panels;
		
		// Mark main queue.
		dispatch_queue_set_specific(dispatch_get_main_queue(), &gSpecificQueueKey, &gMainQueueTag, NULL);
		
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

- (nullable NSString *)windowNibName
{
	return @"AssistantWindow";
}

- (id)owner
{
	return self;
}

- (void)windowDidLoad
{
	// Show first pannel.
	Class <SMAssistantPanel> class = _panels[0];
	
	[self _switchToPanel:[class panelIdentifier] withContent:nil];
}



/*
** SMAssistantWindowController - IBAction
*/
#pragma mark - SMAssistantWindowController - IBAction

- (IBAction)doCancel:(id)sender
{
	// Close window.
	[self close];
	[[NSApplication sharedApplication] stopModal];

	// Call cancelation.
	if ([_currentPanel respondsToSelector:@selector(canceled)])
		[_currentPanel canceled];

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

	if (_nextID)
	{
		// Switch.
		[self _switchToPanel:_nextID withContent:content];
	}
	else
	{
		if (_handler)
			_handler(SMAssistantCompletionTypeDone, content);
		
		_currentPanel.panelProxy = (id)[NSNull null];
		_currentPanel.panelPreviousContent = nil;
		
		_handler = nil;
		_currentPanel = nil;
		
		[self close];
		[[NSApplication sharedApplication] stopModal];
		
		_selfRetain = nil;
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
		
		if (!panel)
		{
			_currentPanel = nil;
			_nextID = nil;
			return;
		}
		
		_panelsInstances[panelID] = panel;
	}
	
	// Set the view
	[_mainView addSubview:[panel panelView]];
	
	// Set the title
	_mainTitle.stringValue = [[panel class] panelTitle];
	
	// Set the proxy
	_nextID = nil;

	panel.panelProxy = self;
	panel.panelPreviousContent = content;
	
	[panel panelDidAppear];
	
	// Update button.
	[self _checkNextButton];
	
	// Hold the panel
	_currentPanel = panel;
}

- (void)_checkNextButton
{
	// > main queue <
	
	// Update activation.
	if (_nextDisabled)
	{
		[_nextButton setEnabled:NO];
	}
	else
	{
		if (_nextID)
		{
			Class class = _panelsClass[_nextID];
			
			_nextButton.enabled = (class != nil);
		}
		else
		{
			[_nextButton setEnabled:YES];
		}
	}
	
	// Update title.
	if (_nextID)
		[_nextButton setTitle:SMLocalizedString(@"ac_next_continue", @"")];
	else
		[_nextButton setTitle:SMLocalizedString(@"ac_next_finish", @"")];
}



/*
** SMAssistantWindowController - Proxy
*/
#pragma mark - SMAssistantWindowController - Proxy

- (void)setNextPanelID:(nullable NSString *)panelID
{
	dispatch_block_t block = ^{
		_nextID = panelID;
		[self _checkNextButton];
	};
	
	if (dispatch_get_specific(&gSpecificQueueKey) == &gMainQueueTag)
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

- (void)setDisableContinue:(BOOL)disabled
{
	dispatch_block_t block = ^{
		_nextDisabled = disabled;
		[self _checkNextButton];
	};
	
	if (dispatch_get_specific(&gSpecificQueueKey) == &gMainQueueTag)
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

@end


NS_ASSUME_NONNULL_END
