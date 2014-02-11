//
//  AppDelegate.h
//  StatusBarApp
//
//  Created by Yang Hsiaoming on 7/20/12.
//  Copyright (c) 2012 lepture.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CDEvents.h"
#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "CDEventsDelegate.h"
#import "Settings.h"
#import "ContentViewController.h"
#import "Base64.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    CDEvents *_events;
    NSUserDefaults *prefs;
    NSString *strCSRFToken;
    
    NSData *databuffer;
    NSString *strPackagePathFileName;
    NSString *strFileName;
    NSString *strEncodePackagePathFileName;
    NSString *fileOperation;
    
    NSInteger currentFrame;
    NSTimer* animTimer;
    
    NSTimer* tokenTimer;
    
    ContentViewController *contentViewController;
    Base64 *base64;
    
    NSString *strOldFilename;
    NSString *strOldFolder;
}

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *devfolder;
@property (nonatomic, strong) NSString *strDownloadFolder;

@property (strong) Settings *settings;

- (void) startWatch;
- (NSMutableURLRequest *) buildRequest: (NSString *) params;
- (void) getHeadToken;
- (void) getFileContents: (NSString *) filePath : (NSString *) fileURL;
- (IBAction) showSettings:(id)sender;
- (void) setStatus: (NSString *) imgName;
- (void)startAnimating;
- (void)stopAnimating;
- (void)updateImage:(NSTimer*)timer;
- (void) downloadFilesFromPath: (NSString *) path;


@end
