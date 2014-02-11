//
//  xSync.h
//  xSync
//
//  Created by Paul Aschmann on 6/17/13.
//  Copyright (c) 2013 li-labs.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base64.h"

@interface xSync : NSObject{
    NSString *strCSRFToken;
    NSString *strUsername;
    NSString *strPassword;
    NSData *databuffer;
    NSString *strRepoURL;
    NSMutableArray *requestOperations;
}

- (id) init: (NSString *) strRepoURL: (NSString *) tmpUsername: (NSString *) tmpPassword;
- (void) saveFile: (NSString *) strPath: (NSData *) datFileContents;
- (id) alloc;

@end
