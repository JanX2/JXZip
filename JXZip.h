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

enum {
	JXZipCaseInsensitivePathLookup =		1,		// Ignore case on path lookup
	
	JXZipReadCompressedData =				4,		// Read compressed data
	JXZipUseOriginalDataIgnoringChanges = 	8,		// Use original data, ignoring changes
	JXZipForceRecompressionOfData =			16, 	// Force recompression of data
	JXZipWantEncryptedData =				32, 	// Read encrypted data (implies JXZipReadCompressedData)
	
	JXZipWantUnmodifiedString =				64, 	// Get unmodified string
	
	JXZipOverwrite =						8192	// When adding a file to a ZIP archive and a file with same path exists, replace it
};
typedef int JXZipOptions;

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
- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath error:(NSError **)error;
//- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;
- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;

- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;
- (BOOL)replaceFile:(JXZippedFileInfo *)zippedFileInfo withData:(NSData *)xmlData error:(NSError **)error;

- (BOOL)saveAndReturnError:(NSError **)error;

@end
