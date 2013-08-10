//
//  DSPMainViewController.m
//  DotSnap
//
//  Created by Robert Widmann on 7/24/13.
//
//

#import "DSPLabel.h"
#import "DSPMainView.h"
#import "DSPShadowBox.h"
#import "DSPMainWindow.h"
#import "DSPMainViewModel.h"
#import "DSPHistoryRowView.h"
#import "DSPHistoryTableView.h"
#import "DSPFilenameTextField.h"
#import "DSPPreferencesWindow.h"
#import "DSPMainViewController.h"
#import "DSPDirectoryPickerButton.h"
#import "DSPSpinningSettingsButton.h"
#import "DSPPreferencesViewController.h"
#import "LIFlipEffect.h"

@interface DSPMainViewController ()
@property (nonatomic, strong, readonly) DSPMainViewModel *viewModel;
@property (nonatomic, strong) DSPPreferencesViewController *preferencesViewController;
@property (nonatomic, strong) DSPPreferencesWindow *preferencesWindow;
@property (nonatomic, copy) void (^carriageReturnBlock)();
@property (nonatomic, copy) void (^mouseDownBlock)(NSEvent *event);
@property (nonatomic, copy) void (^mouseEnteredBlock)(NSEvent *event, BOOL entered);
@property (nonatomic, strong) RACSubject *historySubject;
@end

@implementation DSPMainViewController {
	BOOL _exemptOpenPanelCancellation;
}

#pragma mark - Lifecycle

- (id)initWithContentRect:(CGRect)rect {
	self = [super init];
	
	_contentFrame = rect;
	_viewModel = [DSPMainViewModel new];
	
	_preferencesViewController = [[DSPPreferencesViewController alloc]initWithContentRect:(CGRect){ .size = { 442, 382 } }];
	_preferencesWindow = [[DSPPreferencesWindow alloc]initWithView:self.preferencesViewController.view attachedToPoint:(NSPoint){ } onSide:MAPositionBottom];
	
	_historySubject = [RACSubject subject];
	
	return self;
}

- (void)loadView {
	DSPMainView *view = [[DSPMainView alloc]initWithFrame:_contentFrame];
	view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	view.backgroundColor = [NSColor colorWithCalibratedRed:0.260 green:0.663 blue:0.455 alpha:1.000];
	view.layer.masksToBounds = YES;
	
	DSPBackgroundView *backgroundView = [[DSPBackgroundView alloc]initWithFrame:(NSRect){ .origin.y = 60, .size = { NSWidth(_contentFrame), 150 } }];
	backgroundView.autoresizingMask = NSViewMinYMargin;
	[view addSubview:backgroundView];
	
	DSPShadowBox *windowShadow = [[DSPShadowBox alloc]initWithFrame:(NSRect){ .origin.y = NSHeight(_contentFrame) - 2, .size = { (NSWidth(_contentFrame)/2) - 10, 2 } }];
	[view addSubview:windowShadow];
	
	DSPShadowBox *windowShadow2 = [[DSPShadowBox alloc]initWithFrame:(NSRect){ .origin.x = (NSWidth(_contentFrame)/2) + 10, .origin.y = NSHeight(_contentFrame) - 2, .size = { (NSWidth(_contentFrame)/2) - 10, 2 } }];
	[view addSubview:windowShadow2];
	
	DSPShadowBox *separatorShadow = [[DSPShadowBox alloc]initWithFrame:(NSRect){ .origin.y = NSHeight(_contentFrame) - 146, .size = { NSWidth(_contentFrame), 2 } }];
	separatorShadow.borderColor = [NSColor colorWithCalibratedRed:0.159 green:0.468 blue:0.307 alpha:1.000];
	separatorShadow.fillColor = [NSColor colorWithCalibratedRed:0.159 green:0.468 blue:0.307 alpha:1.000];
	[view addSubview:separatorShadow];
	
	DSPShadowBox *underSeparatorShadow = [[DSPShadowBox alloc]initWithFrame:(NSRect){ .origin.y = 0, .size = { NSWidth(_contentFrame), 2 } }];
	underSeparatorShadow.borderColor = [NSColor colorWithCalibratedRed:0.168 green:0.434 blue:0.300 alpha:1.000];
	underSeparatorShadow.fillColor = [NSColor colorWithCalibratedRed:0.181 green:0.455 blue:0.315 alpha:1.000];
	[view addSubview:underSeparatorShadow];
	
	DSPMainView *fieldBackground = [[DSPMainView alloc]initWithFrame:(NSRect){ .origin.y = 4, .size = { NSWidth(_contentFrame), 60 } }];
	fieldBackground.layer = CALayer.layer;
	fieldBackground.wantsLayer = YES;
	fieldBackground.layer.borderColor = [NSColor colorWithCalibratedRed:0.794 green:0.840 blue:0.864 alpha:1.000].dsp_CGColor;
	fieldBackground.layer.borderWidth = 2.f;
	fieldBackground.backgroundColor = [NSColor colorWithCalibratedRed:0.850 green:0.888 blue:0.907 alpha:1.000];
	fieldBackground.autoresizingMask = NSViewMinYMargin;
	[view addSubview:fieldBackground];
	
	DSPLabel *changeFolderLabel = [[DSPLabel alloc]initWithFrame:(NSRect){ .origin.x = 96, .origin.y = NSHeight(_contentFrame) - 80, .size = { NSWidth(_contentFrame), 36 } }];
	changeFolderLabel.autoresizingMask = NSViewMinYMargin;
	changeFolderLabel.stringValue = @"Change Folder";
	[view addSubview:changeFolderLabel];
		
	DSPLabel *saveToLabel = [[DSPLabel alloc]initWithFrame:(NSRect){ .origin.x = 96, .origin.y = NSHeight(_contentFrame) - 115, .size = { NSWidth(_contentFrame), 34 } }];
	saveToLabel.autoresizingMask = NSViewMinYMargin;
	saveToLabel.font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:11.f];
	saveToLabel.textColor = [NSColor colorWithCalibratedRed:0.171 green:0.489 blue:0.326 alpha:1.000];
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	self.viewModel.filepath = desktopPath;
	saveToLabel.stringValue = [NSString stringWithFormat:@"SAVE TO: %@", desktopPath];
	[view addSubview:saveToLabel];
	
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:(NSRect){ .origin.y = -270, .size = { 400, 246 } }];
	scrollView.autoresizingMask = NSViewMinYMargin;
	scrollView.layer = CALayer.layer;
	scrollView.wantsLayer = YES;
	scrollView.verticalScrollElasticity = NSScrollElasticityNone;
	DSPHistoryTableView *tableView = [[DSPHistoryTableView alloc] initWithFrame: scrollView.bounds];
	tableView.headerView = nil;
	tableView.focusRingType = NSFocusRingTypeNone;
	tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
	NSTableColumn *firstColumn  = [[NSTableColumn alloc] initWithIdentifier:@"firstColumn"];
	firstColumn.editable = NO;
	firstColumn.width = CGRectGetWidth(view.bounds);
	[tableView addTableColumn:firstColumn];
	tableView.delegate = self;
	tableView.dataSource = self.viewModel;
	scrollView.documentView = tableView;
	[view addSubview:scrollView];
	[scrollView setFrame:(NSRect){ .origin.y = 0, .size = { 400, 44 } }];
	[scrollView setAlphaValue:0.f];

	DSPFilenameTextField *filenameField = [[DSPFilenameTextField alloc]initWithFrame:(NSRect){ .origin.x = 30, .origin.y = 10, .size = { NSWidth(_contentFrame) - 84, 34 } }];
	filenameField.delegate = self;
	[view addSubview:filenameField];
	
	DSPDirectoryPickerButton *directoryButton = [[DSPDirectoryPickerButton alloc]initWithFrame:(NSRect){ .origin.x = 36, .origin.y = NSHeight(_contentFrame) - 96, .size = { 48, 48 } }];
	directoryButton.rac_command = [RACCommand command];
	[directoryButton.rac_command subscribeNext:^(NSButton *_) {
		((DSPMainWindow *)view.window).isInOpenPanel = YES;
		[self.openPanel beginSheetModalForWindow:view.window completionHandler:^(NSInteger result){
			((DSPMainWindow *)view.window).isInOpenPanel = NO;
			if (result == NSFileHandlingPanelOKButton) {
				NSArray *urls = [self.openPanel URLs];
				NSString *urlString = [[urls objectAtIndex:0] path];
				BOOL isDir;
				[NSFileManager.defaultManager fileExistsAtPath:urlString isDirectory:&isDir];
				if (isDir) {
					self.viewModel.filepath = urlString;
					saveToLabel.stringValue = [NSString stringWithFormat:@"SAVE TO: %@", urlString.stringByStandardizingPath.stringByAbbreviatingWithTildeInPath];
				} else {
					self.viewModel.filepath = urlString.stringByDeletingLastPathComponent;
					saveToLabel.stringValue = [NSString stringWithFormat:@"SAVE TO: %@", urlString.stringByDeletingLastPathComponent.stringByStandardizingPath.stringByAbbreviatingWithTildeInPath];
				}
			} else {
				_exemptOpenPanelCancellation = YES;
			}
		}];
	}];
	[view addSubview:directoryButton];

	DSPSpinningSettingsButton *optionsButton = [[DSPSpinningSettingsButton alloc]initWithFrame:(NSRect){ .origin.x = NSWidth(_contentFrame) - 45, .origin.y = 24, .size = { 17, 17 } } style:0];
	optionsButton.rac_command = [RACCommand command];
	[optionsButton.rac_command subscribeNext:^(NSButton *_) {
		[(DSPMainWindow *)view.window setIsFlipping:YES];
		self.preferencesViewController.presentingWindow = view.window;
		[[[LIFlipEffect alloc] initFromWindow:view.window toWindow:self.preferencesWindow] run];
		[(DSPMainWindow *)view.window setIsFlipping:NO];
	}];
	[view addSubview:optionsButton];
	
	DSPShadowBox *historySeparatorShadow = [[DSPShadowBox alloc]initWithFrame:(NSRect){ .origin.y = 2, .size = { NSWidth(_contentFrame), 2 } }];
	historySeparatorShadow.borderColor = [NSColor colorWithCalibratedRed:0.794 green:0.840 blue:0.864 alpha:1.000];
	historySeparatorShadow.fillColor = [NSColor colorWithCalibratedRed:0.794 green:0.840 blue:0.864 alpha:1.000];
	historySeparatorShadow.alphaValue = 0.f;
	[view addSubview:historySeparatorShadow];
		
	self.view = view;

	@weakify(self);
	[NSNotificationCenter.defaultCenter addObserverForName:NSControlTextDidChangeNotification object:filenameField queue:nil usingBlock:^(NSNotification *note) {
		@strongify(self);
		if (!CGRectEqualToRect(scrollView.frame, (NSRect){ .origin.y = 6, .size = { 400, 246 } })) {
			[view setNeedsDisplay:YES];
			historySeparatorShadow.alphaValue = 0.f;
			fieldBackground.backgroundColor = [NSColor whiteColor];
			fieldBackground.layer.borderColor = [NSColor colorWithCalibratedRed:0.794 green:0.840 blue:0.864 alpha:1.000].dsp_CGColor;
			
			NSRect rect = (NSRect){ .origin.x = view.window.frame.origin.x, .origin.y = NSMaxY(view.window.screen.frame) - 492, .size = { 400, 470 } };
			[(DSPMainWindow *)view.window setFrame:rect display:YES animate:NO];
			
			[NSAnimationContext beginGrouping];
			[scrollView.animator setFrame:(NSRect){ .origin.y = 6, .size = { 400, 246 } }];
			[scrollView.animator setAlphaValue:1.f];
			[NSAnimationContext endGrouping];
		}
		if (filenameField.stringValue.length == 0) {
			self.viewModel.filename = @"Screen Shot";
		}
		self.viewModel.filename = filenameField.stringValue;
	}];
	
	self.carriageReturnBlock = ^{
		[tableView reloadData];
		
		historySeparatorShadow.alphaValue = 1.f;

		[filenameField resignFirstResponder];
		filenameField.enabled = NO;

		fieldBackground.backgroundColor = [NSColor colorWithCalibratedRed:0.850 green:0.888 blue:0.907 alpha:1.000];
		fieldBackground.layer.borderColor = [NSColor colorWithCalibratedRed:0.850 green:0.888 blue:0.907 alpha:1.000].dsp_CGColor;
		[optionsButton spinOut];

		[NSAnimationContext beginGrouping];
		[scrollView.animator setFrame:(NSRect){ .origin.y = 0, .size = { 400, 44 } }];
		[scrollView.animator setAlphaValue:0.f];
		[NSAnimationContext.currentContext setCompletionHandler:^{
			[(DSPMainWindow *)view.window setFrame:(NSRect){ .origin.x = view.window.frame.origin.x, .origin.y = NSMaxY(view.window.screen.frame) - 246, .size = { 400, 224 } } display:YES animate:NO];
		}];
		[NSAnimationContext endGrouping];
	};
	
	self.mouseDownBlock = ^ (NSEvent *theEvent) {
		if (CGRectContainsPoint(fieldBackground.frame, [theEvent locationInWindow]) && !CGRectContainsPoint(optionsButton.frame, [theEvent locationInWindow])) {
			filenameField.enabled = YES;
			[filenameField becomeFirstResponder];
			[NSNotificationCenter.defaultCenter postNotificationName:NSControlTextDidChangeNotification object:filenameField];
		} else {
			filenameField.enabled = NO;
			[filenameField resignFirstResponder];
			
			historySeparatorShadow.alphaValue = 0.f;
			fieldBackground.backgroundColor = [NSColor colorWithCalibratedRed:0.850 green:0.888 blue:0.907 alpha:1.000];
			fieldBackground.layer.borderColor = [NSColor colorWithCalibratedRed:0.850 green:0.888 blue:0.907 alpha:1.000].dsp_CGColor;

			if (CGRectContainsPoint(backgroundView.frame, [theEvent locationInWindow])) {
				[directoryButton.rac_command performSelector:@selector(execute:) withObject:@0 afterDelay:0.3];
			}
			
			if (!CGRectEqualToRect(scrollView.frame, (NSRect){ .origin.y = 0, .size = { 400, 44 } })) {
				
				[NSAnimationContext beginGrouping];
				[scrollView.animator setFrame:(NSRect){ .origin.y = 0, .size = { 400, 44 } }];
				[scrollView.animator setAlphaValue:0.f];
				[NSAnimationContext.currentContext setCompletionHandler:^{
					[(DSPMainWindow *)view.window setFrame:(NSRect){ .origin.x = view.window.frame.origin.x, .origin.y = NSMaxY(view.window.screen.frame) - 246, .size = { 400, 224 } } display:YES animate:NO];
				}];
				[NSAnimationContext endGrouping];
			}
		}
	};
	
	self.mouseEnteredBlock = ^ (NSEvent *theEvent, BOOL entered) {
		if (entered) {
			[directoryButton mouseEntered:theEvent];
		} else {
			[directoryButton mouseExited:theEvent];
		}
	};
	
	self.viewModel.filename = [NSUserDefaults.standardUserDefaults stringForKey:DSPDefaultFilenameTemplateKey];
	[filenameField rac_liftSelector:@selector(setStringValue:) withSignals:self.historySubject, nil];
	[_historySubject sendNext:[NSUserDefaults.standardUserDefaults stringForKey:DSPDefaultFilenameTemplateKey]];
}

#pragma mark - Event Handling

- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	self.mouseDownBlock(theEvent);
}

- (void)mouseEntered:(NSEvent *)theEvent {
	self.mouseEnteredBlock(theEvent, YES);
}

- (void)mouseExited:(NSEvent *)theEvent {
	self.mouseEnteredBlock(theEvent, NO);
}

- (void)windowDidResignKey:(NSNotification *)aNotification {
	if (!_exemptOpenPanelCancellation) {
		[NSApp endSheet:self.openPanel];
		[(DSPMainWindow *)self.view.window orderOutWithDuration:0.3 timing:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] animations:^(CALayer *layer) {
			layer.transform = CATransform3DMakeTranslation(0.f, -50.f, 0.f);
			layer.opacity = 0.f;
		}];
	}
	_exemptOpenPanelCancellation = NO;
}

#pragma mark - NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
	if (commandSelector == @selector(insertNewline:)) {
		[self.viewModel addFilenameToHistory:textView.string];
		self.carriageReturnBlock();
		return YES;
	} else if (commandSelector == @selector(cancelOperation:)) {
		self.mouseDownBlock(nil);
		return YES;
	}
	return NO;
}

- (void)controlTextDidChange:(NSNotification *)obj {
	
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	return 60.f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	DSPHistoryRowView *tableCellView = (DSPHistoryRowView*)[tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	return tableCellView;
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(DSPHistoryRowView *)rowView forRow:(NSInteger)row {
	rowView.title = self.viewModel.filenameHistory[row];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	DSPHistoryRowView *rowView = [[DSPHistoryRowView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(_contentFrame), 110)];
	return rowView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSTableView *table = notification.object;
	[self.historySubject sendNext:self.viewModel.filenameHistory[table.selectedRow]];
	self.carriageReturnBlock();
}

#pragma mark - Overrides

- (NSOpenPanel *)openPanel {
	static NSOpenPanel *panel;
	if (!panel) {
		panel = [NSOpenPanel openPanel];
		panel.canChooseDirectories = YES;
		panel.allowsMultipleSelection = NO;
		panel.becomesKeyOnlyIfNeeded = YES;
		panel.canCreateDirectories = YES;
		panel.message = @"Import one or more files or directories.";
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:panel];
	}
	return panel;
}

@end
