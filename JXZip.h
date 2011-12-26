//
//  JXZip.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <libzip/zip.h>
#import "JXZippedFileInfo.h"


@interface JXZip : NSObject {
	NSURL *zipFileURL;
	struct zip *za;
}

@property (nonatomic, readonly, retain) NSURL *zipFileURL;
@property (nonatomic, readonly, assign) struct zip *za;

+ (JXZip *)zipWithURL:(NSURL *)zipFileURL error:(NSError **)error;
- (JXZip *)initWithURL:(NSURL *)zipFileURL error:(NSError **)error;

- (NSUInteger)fileCount;
//- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index error:(NSError **)error;
- (JXZippedFileInfo *)zippedFileInfoForFileName:(NSString *)fileName error:(NSError **)error;
//- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSData *)dataForFileName:(NSString *)fileName error:(NSError **)error;
- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;

- (BOOL)addFileWithName:(NSString *)fileName forData:(NSData *)data error:(NSError **)error;
- (BOOL)replaceFile:(JXZippedFileInfo *)zippedFileInfo withData:(NSData *)xmlData error:(NSError **)error;

- (BOOL)saveAndReturnError:(NSError **)error;

@end
