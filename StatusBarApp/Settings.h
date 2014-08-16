//
//  Settings.h
//  SAP HANA IDEL
//
//  Created by Paul Aschmann on 6/9/13.
//  Copyright (c) 2013 lepture.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Settings : NSWindowController{
    IBOutlet NSTextField *username;
    IBOutlet NSTextField *password;
    IBOutlet NSTextField *url;
    IBOutlet NSTextField *devfolder;
    IBOutlet NSTextField *path;
    IBOutlet NSTextField *version;
    IBOutlet NSButton *ignoredeletes;
    NSUserDefaults *prefs;
}

- (IBAction) showFolders:(id)sender;
@property (weak) IBOutlet NSComboBox *cboVersion;


@end
