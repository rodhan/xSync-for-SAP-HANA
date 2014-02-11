//
//  Base64.h
//  xSync
//
//  Created by Paul Aschmann on 6/13/13.
//  Copyright (c) 2013 li-labs.com. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface Base64 : NSObject


- (NSString *)encode:(NSData *)plainText;

@end
