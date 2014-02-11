//
//  ContentViewController.h
//  StatusItemPopup
//
//  Created by Alexander Schuch on 06/03/13.
//  Copyright (c) 2013 Alexander Schuch. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AXStatusItemPopup.h"
#import "Settings.h"

@interface ContentViewController : NSViewController{
    NSUserDefaults *prefs;
}

@property(weak, nonatomic) AXStatusItemPopup *statusItemPopup;
@property (strong) Settings *settings;
@property (nonatomic, strong) IBOutlet NSTextView *txtLog;
@property (nonatomic, strong) IBOutlet NSTextField *txtStatus;

- (IBAction) showSettings:(id)sender;
- (IBAction) clearLog:(id)sender;
- (IBAction) closeApp:(id)sender;
- (void) updateLog: (NSString *) strLog;
- (void) updateSyncStatus;
- (IBAction) openIDE: (id) sender;
- (IBAction) openEditor: (id) sender;

@end
