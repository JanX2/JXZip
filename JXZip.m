//
//  JXZip.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.

#import "JXZip.h"

#import "JXZippedFileInfo.h"
#import <zip.h>

#define ZIP_DISABLE_DEPRECATED	1

NSString * const	JXZipErrorDomain						= @"de.geheimwerk.Error.JXZip";

const int kJXCouldNotOpenZip			= 1001;
const int kJXCouldNotSaveZip			= 1002;
const int kJXCouldNotOpenZippedFile		= 1003;
const int kJXCouldNotReadZippedFile		= 1004;
const int kJXInvalidZippedFileInfo		= 1005;
const int kJXCouldNotAddZippedFile		= 1006;
const int kJXCouldNotReplaceZippedFile	= 1007;

NSString * errorStringForZipError(zip_error_t *zip_error) {
	const char *error_string = zip_error_strerror(zip_error);
	NSString *errorString = @(error_string);
	
	return errorString;
}

NSString * errorStringForZipErrorCode(int error_code) {
	zip_error_t zip_error;
	zip_error_init_with_code(&zip_error, error_code);
	NSString *errorString = errorStringForZipError(&zip_error);
	zip_error_fini(&zip_error);
	
	return errorString;
}

NSString * errorStringForZipArchive(zip_t *za) {
	zip_error_t *zip_error = zip_get_error(za);
	NSString *errorString = errorStringForZipError(zip_error);
	
	return errorString;
}

@interface JXZippedFileInfo (Protected)
+ (instancetype)zippedFileInfoWithArchive:(zip_t *)archive filePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
- (instancetype)initFileInfoWithArchive:(zip_t *)archive filePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;

+ (instancetype)zippedFileInfoWithArchive:(zip_t *)archive index:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
- (instancetype)initFileInfoWithArchive:(zip_t *)archive index:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
@end

@interface JXZip ()
@property (nonatomic, readwrite, retain) NSURL *URL;
@property (nonatomic, readwrite, assign) zip_t *za;
@end

@implementation JXZip {
}

+ (instancetype)zipWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [[[JXZip alloc] initWithURL:fileURL options:0 error:error] autorelease];
}

+ (instancetype)zipWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;
{
	return [[[JXZip alloc] initWithURL:fileURL options:options error:error] autorelease];
}

- (instancetype)initWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [self initWithURL:fileURL options:0 error:error];
}

- (instancetype)initWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (fileURL == nil) {
			[self release];
			return nil;
		}
		
		self.URL = fileURL;
		
		// NOTE: We could rewrite this using file descriptors.
		const char *zip_file_path = [[fileURL path] UTF8String];
		int err;
		
		_za = zip_open(zip_file_path, options, &err);
		
		if (_za == NULL) {
			if (error != NULL) {
				NSString *errorString = errorStringForZipErrorCode(err);

				NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be opened: %@ (%d)", @"Cannot open zip archive"),
												  fileURL, errorString, err];
				NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
				*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotOpenZip userInfo:errorDetail];
			}
			
			[self release];
			return nil;
		}
	}
	
	return self;
}


- (void)dealloc
{
	self.URL = nil;
	
	if (_za != NULL) {
		zip_unchange_all(_za);
		zip_close(_za);
		_za = NULL;
	}

	[super dealloc];
}


- (NSUInteger)fileCount;
{
	if (_za == NULL)  return NSNotFound;
	
	// The underlying library uses an int to store the count so this is safe in any case.
	return (NSUInteger)zip_get_num_entries(_za, ZIP_FL_UNCHANGED);
}

- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za index:index options:0 error:error];
}

- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za index:index options:options error:error];
}

- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za filePath:filePath options:0 error:error];
}

- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za filePath:filePath options:options error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
{
	return [self dataForFileAtIndex:index options:0 error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForIndex:index error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;
{
	return [self dataForFilePath:filePath options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForFilePath:filePath error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;
{
	return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo options:(JXZippedFileOptions)options error:(NSError **)error;
{
	if (zippedFileInfo == nil)  return nil;

	zip_uint64_t zipped_file_index = zippedFileInfo.index;
	zip_uint64_t zipped_file_size = zippedFileInfo.size;
	
	if ((zipped_file_index == NSNotFound) || (zipped_file_size == NSNotFound)) {
		if (error != NULL) {
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid zipped file info.", @"Invalid zipped file info")];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXInvalidZippedFileInfo userInfo:errorDetail];
		}
		
		return nil;
	}

	zip_file_t *zipped_file = zip_fopen_index(_za, zipped_file_index, (options & ZIP_FL_ENC_UTF_8));
	if (zipped_file == NULL) {
		if (error != NULL) {
			NSString *errorString = errorStringForZipArchive(_za);
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not open zipped file “%@” in archive “%@”: %@", @"Could not open zipped file"),
											  zippedFileInfo.path, self.URL, errorString];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotOpenZippedFile userInfo:errorDetail];
		}
		
		return nil;
	}
	
	char *buf = malloc(zipped_file_size); // freed by NSData
	
	zip_int64_t n = zip_fread(zipped_file, buf, zipped_file_size);
	if (n < (zip_int64_t)zipped_file_size) {
		if (error != NULL) {
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while reading zipped file “%@” in archive “%@”: %s", @"Error while reading zipped file"),
											  zippedFileInfo.path, self.URL, zip_file_strerror(zipped_file)];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotReadZippedFile userInfo:errorDetail];
		}
		
		zip_fclose(zipped_file);
		
		free(buf);
		
		return nil;
	}
	
	zip_fclose(zipped_file);
	
	return [NSData dataWithBytesNoCopy:buf length:(NSUInteger)zipped_file_size freeWhenDone:YES];
}


- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;
{
	if ((filePath == nil) || (data == nil))  return NO;
	
	// CHANGEME: Passing the index back might be helpful
	
	const char * file_path = [filePath UTF8String];
	zip_source_t *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
	zip_int64_t index;
	
	if ((file_zip_source == NULL)
		|| ((index = zip_file_add(_za, file_path, file_zip_source, (ZIP_FL_ENC_UTF_8))) < 0)
		) { 
		if (error != NULL) {
			NSString *errorString = errorStringForZipArchive(_za);
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while adding zipped file “%@” in archive “%@”: %@", @"Error while adding zipped file"),
											  filePath, self.URL, errorString];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotAddZippedFile userInfo:errorDetail];
		}
		
		if (file_zip_source != NULL)  zip_source_free(file_zip_source); 
		
		return NO;
	}
	
	return YES;
}

- (BOOL)replaceFile:(JXZippedFileInfo *)zippedFileInfo withData:(NSData *)data error:(NSError **)error;
{
	if ((zippedFileInfo == nil) || (data == nil))  return NO;
	
	zip_source_t *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
	
	if ((file_zip_source == NULL)
		|| (zip_file_replace(_za, zippedFileInfo.index, file_zip_source, 0) < 0)
		) { 
		if (error != NULL) {
			NSString *errorString = errorStringForZipArchive(_za);
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while replacing zipped file “%@” in archive “%@”: %@", @"Error while replacing zipped file"),
											  zippedFileInfo.path, self.URL, errorString];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotReplaceZippedFile userInfo:errorDetail];
		}
		
		if (file_zip_source != NULL)  zip_source_free(file_zip_source); 
		
		return NO;
	}
	
	// We don’t need to zip_source_free() here, as libzip has taken care of it once we have reached this line.
	
	return YES;
}


- (BOOL)saveAndReturnError:(NSError **)error;
{
	if (_za == NULL)  return NO;
	
	if (zip_close(_za) < 0) {
		if (error != NULL) {
			NSString *errorString = errorStringForZipArchive(_za);
			NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %@", @"Cannot save zip archive"),
											  self.URL, errorString];
			NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotSaveZip userInfo:errorDetail];
		}

		return NO;
	}
	else {
		_za = NULL;
		return YES;
	}
}


@end

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

