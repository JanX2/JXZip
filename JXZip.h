//
//  JXZip.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <libzip/zip.h>


@interface JXZip : NSObject {
	NSURL *zipFileURL;
	struct zip *za;
}

@property (nonatomic, retain) NSURL *zipFileURL;
+ (JXZip *)zipWithURL:(NSURL *)zipFileURL error:(NSError **)error;
- (JXZip *)initWithURL:(NSURL *)zipFileURL error:(NSError **)error;

- (NSUInteger)fileCount;
- (BOOL)saveAndReturnError:(NSError **)error;

@end
