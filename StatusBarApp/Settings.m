//
//  Settings.m
//  SAP HANA IDEL
//
//  Created by Paul Aschmann on 6/9/13.
//  Copyright (c) 2013 lepture.com. All rights reserved.
//

#import "Settings.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>
#import "AppDelegate.h"


@interface Settings ()

@end

@implementation Settings

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}

- (void) awakeFromNib{
    CGFloat x = (self.window.screen.frame.size.width - self.window.frame.size.width) /2;
    CGFloat y = (self.window.screen.frame.size.height - self.window.frame.size.height) - 40;
    NSRect newFrame = NSMakeRect(x, y, self.window.frame.size.width, self.window.frame.size.height);
    [self.window setFrame:newFrame display:YES animate:NO];
    
    NSApplication *thisApp = [NSApplication sharedApplication];
    [thisApp activateIgnoringOtherApps:YES];
    [self.window orderFrontRegardless];
    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    prefs = [NSUserDefaults standardUserDefaults];
    
    [username setStringValue:[prefs valueForKey:@"Username"]];
    [url setStringValue:[prefs valueForKey:@"Url"]];
    [devfolder setStringValue:[prefs valueForKey:@"DevFolder"]];
    [password setStringValue:[prefs valueForKey:@"Password"]];
    [path setStringValue:[prefs valueForKey:@"Path"]];
    [self.cboVersion selectItemWithObjectValue:[prefs valueForKey:@"Version"]];
    
    if ([prefs valueForKey:@"Username"]){
        [password becomeFirstResponder];
    } else {
        [username becomeFirstResponder];
    }
    
    [version setStringValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] ;
    
    if ([[prefs valueForKey:@"IgnoreDeletes"]  isEqual: @"TRUE"]){
        [ignoredeletes setState:1];
    } else {
        [ignoredeletes setState:0];
    }
    
    if ([[prefs valueForKey:@"MonitorChanges"]  isEqual: @"TRUE"]){
        [monitorChanges setState:1];
    } else {
        [monitorChanges setState:0];
    }
}


- (IBAction) showFolders:(id)sender{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setPrompt:@"Select"];
    
    if ([openPanel runModal] == NSOKButton)
    {
        [devfolder setStringValue:[openPanel.URL path]];
    }
}


- (void)windowWillClose:(NSNotification *)notification{
        
    @try {
        [prefs setObject:[username stringValue] forKey:@"Username"];
        [prefs setObject:[url stringValue] forKey:@"Url"];
        [prefs setObject:[devfolder stringValue] forKey:@"DevFolder"];
        [prefs setObject:[password stringValue] forKey:@"Password"];
        [prefs setObject:[path stringValue] forKey:@"Path"];
        if (ignoredeletes.state == 1){
            [prefs setObject:@"TRUE" forKey:@"IgnoreDeletes"];
        } else {
            [prefs setObject:@"FALSE" forKey:@"IgnoreDeletes"];
        }
        if (monitorChanges.state == 1){
            [prefs setObject:@"TRUE" forKey:@"MonitorChanges"];
        } else {
            [prefs setObject:@"FALSE" forKey:@"MonitorChanges"];
        }
        [prefs setObject:self.cboVersion.objectValueOfSelectedItem forKey:@"Version"];
    }
    @catch (NSException *exception) {
        NSLog(@"Error: %@", exception.description);
    }
    @finally {
        
    }
    
    [prefs synchronize];
    
    AppDelegate *theAppDelegate = (AppDelegate*) [NSApplication sharedApplication].delegate;
    [theAppDelegate getHeadToken];
    [theAppDelegate startWatch];
}


@end
