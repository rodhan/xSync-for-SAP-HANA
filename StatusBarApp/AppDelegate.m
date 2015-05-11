//
//  AppDelegate.m
//  StatusBarApp
//
//  Created by Yang Hsiaoming on 7/20/12.
//  Copyright (c) 2012 lepture.com. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "AFHTTPClient.h"
#import "AFNetworking.h"
#import "AXStatusItemPopup.h"
#import "ContentViewController.h"
#import "Base64.h"
#import "JSONKit.h"

@interface AppDelegate () {
    AXStatusItemPopup *_statusItemPopup;
}
@end

@implementation AppDelegate


@synthesize settings, password, url, username, devfolder, strDownloadFolder;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    contentViewController = [[ContentViewController alloc] initWithNibName:@"ContentViewController" bundle: nil];
    _statusItemPopup = [[AXStatusItemPopup alloc] initWithViewController:contentViewController image:[NSImage imageNamed:@"Status"]];
    
    [_statusItemPopup setHighlighted:NO];
    [_statusItemPopup showPopover];
    [self setStatus:@"Status-Down"];
    
    prefs = [NSUserDefaults standardUserDefaults];
    
    if ([[prefs valueForKey:@"Url"] length] != 0){
        [self getHeadToken];
        if ([strCSRFToken length] == 0){
            [self setStatus:@"Status-Down"];
        }
    }
    
    if ([[prefs valueForKey:@"DevFolder"] length] == 0){
        [self showSettings: nil];
    } else {
        [self startWatch];
    }

    tokenTimer = [NSTimer scheduledTimerWithTimeInterval:300.0 target:self selector:@selector(getHeadToken) userInfo:nil repeats:YES];
    
}


- (void) startWatch{
    if (![[prefs valueForKey:@"MonitorChanges"] isEqual: @"TRUE"]){
        return;
    }
    
    return;
    
    
    if ([[prefs valueForKey:@"DevFolder"] length] > 0 && [[prefs valueForKey:@"Url"] length] > 0){
        NSArray *urls = [NSArray arrayWithObject:[NSURL URLWithString:[prefs valueForKey:@"DevFolder"]]];
        NSArray *urlexcl  = [NSURL URLWithString:@"/nonexistingfolder"];
        NSArray *urlsexcl = [NSArray arrayWithObject:urlexcl];
        
        _events = [[CDEvents alloc] initWithURLs:urls
                                          block:^(CDEvents *watcher, CDEvent *event) {
                                              
                                              NSString *filePath = [event.URL path];
                                              strPackagePathFileName = [NSString stringWithFormat:@"%@",[[event.URL path] substringFromIndex:[[prefs valueForKey:@"DevFolder"] length] + 1]];
                                              //The + 8 removes the file:///
                                              strEncodePackagePathFileName = [NSString stringWithFormat:@"%@", [[event.URL absoluteString] substringFromIndex: [[prefs valueForKey:@"DevFolder"] length] + 8]];
                                              NSLog(@"%@", [[event.URL absoluteString] substringFromIndex: [[prefs valueForKey:@"DevFolder"] length] + 8]);
                                              
                                              //Our File Handler
                                              if (event.isDir){
                                                  if (event.isRenamed) {
                                                      BOOL isDir;
                                                      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
                                                      if ([strEncodePackagePathFileName rangeOfString:@"untitled"].location == NSNotFound){
                                                          if (exists){
                                                              //Do nothing to avoid creating this default folder
                                                              databuffer = [@"/" dataUsingEncoding:NSUTF8StringEncoding];
                                                              [self saveFile: strPackagePathFileName];
                                                          } else {
                                                              if ([[prefs valueForKey:@"IgnoreDeletes"]  isEqual: @"TRUE"]){
                                                                  [self deleteFile:strPackagePathFileName];
                                                              }
                                                          }
                                                      }
                                                  } else if (event.isCreated){
                                                      if ([strEncodePackagePathFileName rangeOfString:@"untitled"].location == NSNotFound){
                                                          //Do nothing to avoid creating this default folder
                                                          databuffer = [@"/" dataUsingEncoding:NSUTF8StringEncoding];
                                                          [self saveFile: strPackagePathFileName];
                                                      }
                                                  }
                                                  
                                              // Our Folder Handler
                                              } else if (event.isFile) {
                                                  
                                                  
                                                  NSString* theFileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
                                                  
                                                  if ([filePath rangeOfString:@"Spotlight"].location == NSNotFound){
                                                      if ([theFileName isEqualToString:@".DS_Store"]){
                                                          //These events occur for files which have been deleted?
                                                      } else if (event.isRenamed) {
                                                          //FSEvents registers both modifies and deletes as modifies, so we will check if file exists to decipher
                                                          if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NO]){
                                                              [self getFileContents: filePath: [event.URL absoluteString]];
                                                              [self saveFile: strEncodePackagePathFileName];
                                                          } else {
                                                              if ([[prefs valueForKey:@"IgnoreDeletes"]  isEqual: @"TRUE"]){
                                                                  [self deleteFile:strEncodePackagePathFileName];
                                                              }
                                                          }
                                                      } else if (event.isCreated || event.isModified){
                                                          [self getFileContents: filePath: [event.URL absoluteString]];
                                                          [self saveFile: strEncodePackagePathFileName];
                                                      }
                                                  }

                                                  
                                                  
                                              }
                                          }
                            onRunLoop:[NSRunLoop currentRunLoop]
                           sinceEventIdentifier:kCDEventsSinceEventNow
                           notificationLantency:1
                        ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
                                    excludeURLs:urlsexcl
                             streamCreationFlags: kCDEventsDefaultEventStreamFlags];
        
        NSLog(@"Watching folder: %@", [prefs valueForKey:@"DevFolder"]);
        [contentViewController updateLog:[NSString stringWithFormat:@"\nWatching folder: %@", [prefs valueForKey:@"DevFolder"]]];
    }
}

- (void) stopWatch{
    NSLog(@"Stopped watching folder");
    _events = nil;
}


- (NSMutableURLRequest *) buildRequest: (NSString *) params{
    NSString *strURL = @"";
    if ([[prefs valueForKey:@"Version"] isEqualToString:@"SP07"]){
        strURL = [NSString stringWithFormat:@"%@/sap/hana/xs/ide/editor/server/repo/reposervice.xsjs%@", [prefs valueForKey:@"Url"], params];
    } else {
        strURL = [NSString stringWithFormat:@"%@/sap/hana/xs/editor/server/repo/reposervice.xsjs%@", [prefs valueForKey:@"Url"], params];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: strURL]];
    
    
    NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@",
                                                      [prefs valueForKey:@"Username"],
                                                      [prefs valueForKey:@"Password"]];
    
    NSString *encodedLoginData = [[Base64 alloc] encode:[loginString dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@",
                            encodedLoginData];
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    return request;
}


- (void) getHeadToken{
    NSMutableURLRequest *request = [self buildRequest:@""];
    [request setHTTPMethod:@"HEAD"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        
        NSDictionary *dictionary = [operation.response allHeaderFields];
        strCSRFToken = [dictionary objectForKey:@"x-csrf-token"];
        
        [contentViewController updateSyncStatus];
        
        if ([_statusItemPopup.image.name isEqualToString:@"Status-Down"]){
            [self setStatus:@"Status"];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self setStatus:@"Status-Down"];
        [contentViewController updateSyncStatus];
        NSLog(@"%@", error.description);
    }];
    
    [operation start];

}

- (void) getFileContents: (NSString *) filePath: (NSString *) fileURL{
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath: filePath];
    
    if (file == nil){
        NSLog(@"Failed to open file");
    } else {
        //filesName = [[fileURL substringFromIndex:16] substringFromIndex:[[prefs valueForKey:@"DevFolder"] length] +1];
        databuffer = [file readDataToEndOfFile];
        [file closeFile];
    }
}


- (void) deleteFile: (NSString *) filename{
    if ([strCSRFToken length] > 0) {
        [self startAnimating];
        NSMutableURLRequest *request = [self buildRequest: [NSString stringWithFormat: @"?path=%@/%@", [prefs valueForKey:@"Path"], filename]];
        [request setHTTPMethod:@"DELETE"];
        [request addValue:strCSRFToken forHTTPHeaderField:@"x-csrf-token"];
        [request setHTTPBody: databuffer];
        
        NSLog(@"Deleting: %@/%@", [prefs valueForKey:@"Path"], filename);
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
        
        [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
            databuffer = nil;
            [self stopAnimating];
            [self setStatus:@"Status-OK"];
            [contentViewController updateLog:[NSString stringWithFormat:@"Deleted: %@/%@", [prefs valueForKey:@"Path"], filename ]];
            [contentViewController updateSyncStatus];
            //"saved":true,
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            databuffer = nil;
            [self stopAnimating];
            [self setStatus:@"Status-Bad"];
            NSString *errormsg = [error localizedRecoverySuggestion];
            if (errormsg == NULL){
                errormsg = [error localizedDescription];
            } else {
                errormsg = [NSString stringWithFormat:@"[%@]", errormsg];
                id jsonData = [errormsg dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *readJsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                NSDictionary *element1 = readJsonArray[0];
                errormsg = element1[@"errorMsg"];
            }
            [contentViewController updateLog:[NSString stringWithFormat: @"Error: %ld %@ (%@/%@)", operation.response.statusCode, errormsg, [prefs valueForKey:@"Path"], filename]];
            [contentViewController updateSyncStatus];
            NSLog(@"%@", error.description);
            //{"errorCode":40133,"errorMsg":"Repository: Package is not empty (contains development objects);"}
        }];
        
        [operation start];
    } else {
        [contentViewController updateLog: @"Unable to sync, server offline or not responding"];
    }
    
}



- (void) saveFile: (NSString *) filename{
    
    if ([strCSRFToken length] > 0) {
        [self startAnimating];
        NSMutableURLRequest *request = [self buildRequest: [NSString stringWithFormat: @"?path=%@/%@", [prefs valueForKey:@"Path"], filename]];
        [request setHTTPMethod:@"PUT"];
        [request addValue:strCSRFToken forHTTPHeaderField:@"x-csrf-token"];
        [request setHTTPBody: databuffer];
        
        NSLog(@"Saving: %@/%@", [prefs valueForKey:@"Path"], filename);
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
        
        [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
            databuffer = nil;
            [self stopAnimating];
            [self setStatus:@"Status-OK"];
            [contentViewController updateLog:[NSString stringWithFormat:@"Synced: %@/%@", [prefs valueForKey:@"Path"], filename ]];
            [contentViewController updateSyncStatus];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            databuffer = nil;
            [self stopAnimating];
            [self setStatus:@"Status-Bad"];
            NSString *errormsg = [error localizedRecoverySuggestion];
            if (errormsg == NULL){
                errormsg = [error localizedDescription];
            } else {
                errormsg = [NSString stringWithFormat:@"[%@]", errormsg];
                id jsonData = [errormsg dataUsingEncoding:NSUTF8StringEncoding];
                NSArray *readJsonArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                NSDictionary *element1 = readJsonArray[0];
                errormsg = element1[@"errorMsg"];
            }
            [contentViewController updateLog:[NSString stringWithFormat: @"Error: %ld %@ (%@/%@)", operation.response.statusCode, errormsg, [prefs valueForKey:@"Path"], filename]];            [contentViewController updateSyncStatus];
            NSLog(@"%@", error.description);
        }];
        
        [operation start];
     } else {
         [contentViewController updateLog: @"Unable to sync, server offline or not responding"];
     }

}

- (IBAction) showSettings:(id)sender{
    settings = [[Settings alloc]initWithWindowNibName:@"Settings"];
    [settings showWindow:self];
}

- (void) setStatus: (NSString *) imgName{
    [animTimer invalidate];
    NSImage *image = [NSImage imageNamed:imgName];
    [_statusItemPopup setImage:image];
}

- (void)startAnimating
{
    [animTimer invalidate];
    currentFrame = 0;
    animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
}

- (void)stopAnimating{
    [animTimer invalidate];
}


- (void)updateImage:(NSTimer*)timer
{    //get the image for the current frame
    currentFrame = currentFrame + 1;
    
    if (currentFrame == 10){
        currentFrame = 0;
    }
    
    NSImage* image = [NSImage imageNamed:[NSString stringWithFormat:@"Status 20%ld", (long)currentFrame]];
    [_statusItemPopup setImage:image];
}



- (void) downloadFilesFromPath: (NSString *) path{
    //Disable the file system watch to avoid doing cyclical copies
    [self stopWatch];
    if ([strCSRFToken length] > 0) {
        NSMutableURLRequest *request = [self buildRequest: [NSString stringWithFormat: @"?path=%@", path]];
        [request setHTTPMethod:@"GET"];
        [request addValue:strCSRFToken forHTTPHeaderField:@"x-csrf-token"];
        [request setHTTPBody: databuffer];
        
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            id newJSON2 = [JSON valueForKeyPath:@"children"];
            
            for (int i = 0; i < [newJSON2 count]; i++){
                
                NSString *uri = [[newJSON2 valueForKeyPath:@"uri"] objectAtIndex:i];
                NSString *rel = [[newJSON2 valueForKeyPath:@"rel"] objectAtIndex:i];
                
                if ([rel isEqualToString:@"folder"]){
                    [self createFolder:[NSString stringWithFormat:@"%@/%@", strDownloadFolder, uri]];
                    [self downloadFilesFromPath:uri];
                } else {
                    [self saveToLocalFile:uri:[NSString stringWithFormat:@"%@/%@",strDownloadFolder, uri]];
                }
            }            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSString *errormsg = [error localizedRecoverySuggestion];
            if (errormsg == NULL){
                errormsg = [error localizedDescription];
            }
            [contentViewController updateLog:[NSString stringWithFormat: @"Error: %ld %@ (%@)", response.statusCode, errormsg, [prefs valueForKey:@"Path"]]];
            NSLog(@"Download error: %ld %@", response.statusCode, [error localizedDescription]);
        }];
        [operation start];
    } else {
        [contentViewController updateLog: @"Unable to sync, server offline or not responding"];
    }
    [self startWatch];
}


- (void) createFolder: (NSString *) diskPath{
    NSFileManager *fileManager= [NSFileManager defaultManager];
    BOOL isDir;
    if(![fileManager fileExistsAtPath:diskPath isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:diskPath withIntermediateDirectories:YES attributes:nil error:NULL])
            [contentViewController updateLog:[NSString stringWithFormat:@"Error: Create folder failed %@", diskPath]];
}


- (void) saveToLocalFile: (NSString *) uri: (NSString *) diskPath {
    NSMutableURLRequest *request = [self buildRequest: [NSString stringWithFormat: @"?path=%@", uri]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [request setHTTPMethod:@"GET"];
    [request addValue:strCSRFToken forHTTPHeaderField:@"x-csrf-token"];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:diskPath append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [contentViewController updateLog:[NSString stringWithFormat:@"Downloaded: %@", diskPath]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [contentViewController updateLog:[NSString stringWithFormat:@"Download error: %@", error]];
        NSLog(@"%@", error.description);
    }];
    
    [operation start];
}





@end
