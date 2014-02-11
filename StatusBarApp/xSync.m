//
//  xSync.m
//  xSync
//
//  Created by Paul Aschmann on 6/17/13.
//  Copyright (c) 2013 li-labs.com. All rights reserved.
//

#import "xSync.h"
#import "AFHTTPClient.h"
#import "AFNetworking.h"
#import "Base64.h"
#import "JSONKit.h"

@implementation xSync

- (id) init: (NSString *) tmpRepoURL: (NSString *) tmpUsername: (NSString *) tmpPassword{
    if (self = [super init]){
        strUsername = tmpUsername;
        strPassword = tmpPassword;
        strRepoURL = tmpRepoURL;
        requestOperations = [NSMutableArray array];
    }
    return self;
}

- (id) alloc{
    
}



- (void) processRequest: (NSMutableArray *) operations{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:strRepoURL]];
    @try{
        [client enqueueBatchOfHTTPRequestOperations:operations
                                      progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
                                          NSLog(@"%d proccesses completed out of %d", numberOfCompletedOperations, totalNumberOfOperations);
                                      } completionBlock:^(NSArray *operations) {
                                          
                                          for (AFHTTPRequestOperation *ro in operations) {
                                              
                                              if (ro.error) {
                                                  NSLog(@"Operation error");
                                                  
                                              }else {
                                                  NSLog(@"Operation OK: %@", [ro.responseData description]);
                                              }
                                          }
                                          
                                      }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    @finally {
        NSLog(@"finally");
    }
}

- (void) saveFile:(NSString *)strPath :(NSData *)datFileContents {
    NSMutableURLRequest *request = [self buildRequest:strPath];
    [request setHTTPMethod:@"HEAD"];
    [request setHTTPBody: datFileContents];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [requestOperations addObject:operation];
    
    
    NSMutableURLRequest *request2 = [self buildRequest:strPath];
    [request2 setHTTPMethod:@"PUT"];
    [request2 setHTTPBody: datFileContents];
    AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc]initWithRequest:request2];
    [requestOperations addObject:operation2];
    
    [self processRequest:requestOperations];
}


- (void) deleteFile: (NSString *) strPath{
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
        [contentViewController updateLog:[NSString stringWithFormat: @"Error:  %@/%@", [prefs valueForKey:@"Path"], filename ]];
        [contentViewController updateSyncStatus];
        NSLog(@"%@%", error.description);
        //{"errorCode":40133,"errorMsg":"Repository: Package is not empty (contains development objects);"}
    }];
    
    [operation start];
}




- (NSMutableURLRequest *) buildRequest: (NSString *) params{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", strRepoURL, params]]];
    NSMutableString *loginString = (NSMutableString*)[@"" stringByAppendingFormat:@"%@:%@", strUsername, strPassword];
    
    NSString *encodedLoginData = [[Base64 alloc] encode:[loginString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginData];
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    return request;
}


@end
