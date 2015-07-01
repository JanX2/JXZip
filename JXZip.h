//
//  JXZip.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JXZippedFileInfo.h"

enum {
	JXZipCreate =						1,		// Create the archive if it does not exist.
	JXZipExclusive =					2,		// Error if archive already exists.
	JXZipStricterConsistencyChecks =	4,		// Perform additional stricter consistency checks on the archive, and error if they fail.
	JXZipTruncate =						8,		// If archive exists, ignore its current contents. In other words, handle it the same way as an empty archive.
	JXZipReadOnly =						16,		// .
};
typedef int JXZipOptions;

enum {
	JXZippedFileCaseInsensitivePathLookup =		1,		// Ignore case on path lookup
	
	JXZippedFileReadCompressedData =				4,		// Read compressed data
	JXZippedFileUseOriginalDataIgnoringChanges = 	8,		// Use original data, ignoring changes
	JXZippedFileForceRecompressionOfData =			16, 	// Force recompression of data
	JXZippedFileWantEncryptedData =				32, 	// Read encrypted data (implies JXZippedFileReadCompressedData)
	
	JXZippedFileWantUnmodifiedString =				64, 	// Get unmodified string

	JXZippedFileInCentralDirectory =				512,	// In central directory

	JXZippedFileOverwrite =						8192	// When adding a file to a ZIP archive and a file with same path exists, replace it
};
typedef int JXZippedFileOptions;


@class JXZippedFileInfo;


@interface JXZip : NSObject

@property (nonatomic, readonly, retain) NSURL *URL;
@property (nonatomic, readonly) NSUInteger fileCount;

// From NSURL.
+ (instancetype)zipWithURL:(NSURL *)fileURL error:(NSError **)error;
+ (instancetype)zipWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;

- (instancetype)initWithURL:(NSURL *)fileURL error:(NSError **)error;
- (instancetype)initWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;


// File access.
- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index error:(NSError **)error;
- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath error:(NSError **)error;
- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
- (NSData *)dataForFileAtIndex:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;
- (NSData *)dataForFilePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;
- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo options:(JXZippedFileOptions)options error:(NSError **)error;

- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;
- (BOOL)replaceFile:(JXZippedFileInfo *)zippedFileInfo withData:(NSData *)xmlData error:(NSError **)error;

- (BOOL)saveAndReturnError:(NSError **)error;

@end


FOUNDATION_EXTERN NSString * const JXZipErrorDomain;

FOUNDATION_EXTERN const int kJXCouldNotOpenZip;
FOUNDATION_EXTERN const int kJXCouldNotSaveZip;
FOUNDATION_EXTERN const int kJXCouldNotOpenZippedFile;
FOUNDATION_EXTERN const int kJXCouldNotReadZippedFile;
FOUNDATION_EXTERN const int kJXInvalidZippedFileInfo;
FOUNDATION_EXTERN const int kJXCouldNotAddZippedFile;
FOUNDATION_EXTERN const int kJXCouldNotReplaceZippedFile;
