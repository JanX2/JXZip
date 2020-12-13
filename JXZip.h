//
//  JXZip.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.

#import <Cocoa/Cocoa.h>

#import <JXZip/JXZippedFileInfo.h>

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

/*
 Copyright (C) 2011-20 Jan Weiß
 
 All rights reserved: https://opensource.org/licenses/BSD-3-Clause
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 3. Neither the name of the copyright holder nor the names of its
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

