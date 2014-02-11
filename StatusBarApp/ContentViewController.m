//
//  ContentViewController.m
//  StatusItemPopup
//
//  Created by Alexander Schuch on 06/03/13.
//  Copyright (c) 2013 Alexander Schuch. All rights reserved.
//

#import "ContentViewController.h"
#import "Settings.h"
#import "AppDelegate.h"

@implementation ContentViewController

@synthesize settings, txtLog, txtStatus;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    
    return self;
}

- (void) awakeFromNib{
    [txtLog setFont:[NSFont fontWithName:@"Lucida Grande" size:10]];
    [txtLog setTextColor:[NSColor grayColor]];
    [txtLog setString:@""];
    prefs = [NSUserDefaults standardUserDefaults];
}

- (IBAction) downloadFiles:(id)sender{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setPrompt:@"Select"];
    [openPanel setCanCreateDirectories:YES];
    
    if ([openPanel runModal] == NSOKButton)
    {
        AppDelegate *theAppDelegate = (AppDelegate*) [NSApplication sharedApplication].delegate;
        theAppDelegate.strDownloadFolder = [openPanel.URL path];
        [theAppDelegate downloadFilesFromPath: [prefs valueForKey:@"Path"]];
    }
}

- (IBAction) openIDE: (id) sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/sap/hana/xs/ide/",[prefs valueForKey:@"Url"]]]];
}

- (IBAction) openEditor: (id) sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/sap/hana/xs/editor/",[prefs valueForKey:@"Url"]]]];
}


- (IBAction) closeApp:(id)sender{
    [NSApp terminate:self];
}


- (IBAction) showSettings:(id)sender{
    [self.statusItemPopup hidePopover];
    settings = [[Settings alloc]initWithWindowNibName:@"Settings"];
    [settings showWindow:self];
}

- (IBAction) clearLog:(id)sender{
    [txtLog setString:@""];
}

- (void) updateSyncStatus{
    NSDate *myDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *myDateString = [dateFormatter stringFromDate:myDate];
    [txtStatus setStringValue: [NSString stringWithFormat:@"Last Sync: %@", myDateString]];
}

- (void) updateLog: (NSString *) strLog{
    NSDate *myDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *myDateString = [dateFormatter stringFromDate:myDate];
    [txtLog insertText:[NSString stringWithFormat:@"%@ %@\n", myDateString, strLog]];
    [txtStatus setStringValue: [NSString stringWithFormat:@"Last Sync: %@", myDateString]];
}


@end
