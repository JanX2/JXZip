//
//  JXZippedFileInfo.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.

#import "JXZippedFileInfo.h"

#import "JXZip.h"

#import <zip.h>

NSString * const	JXZippedFileInfoErrorDomain			= @"de.geheimwerk.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1101


@implementation JXZippedFileInfo {
	zip_stat_t	_file_info;
}

- (instancetype)initFileInfoWithArchive:(zip_t *)archive
								  index:(NSUInteger)index
							   filePath:(NSString *)filePath
								options:(JXZippedFileOptions)options
								  error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (archive == NULL) {
			[self release];
			return nil;
		}
		
		options = (options & ZIP_FL_ENC_UTF_8);
		
		zip_int64_t idx;
		const char *file_path = NULL;
		
		if (filePath != nil) {
			file_path = [filePath UTF8String]; // autoreleased
			idx = zip_name_locate(archive, file_path, options);
		}
		else {
			idx = (int)index;
		}
		
		if ((idx < 0) || (zip_stat_index(archive, (zip_uint64_t)idx, options, &_file_info) < 0)) {
			if (error != NULL) {
				NSString *errorDescription;
				if (filePath != nil) {
					errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for “%@” in zipped file: %s", @"Cannot access file info in zipped file"),
										filePath, zip_strerror(archive)];
				}
				else {
					errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for file %lu in zipped file: %s", @"Cannot access file info in zipped file"),
										(unsigned long)index, zip_strerror(archive)];
				}
				NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorDescription};
				*error = [NSError errorWithDomain:JXZippedFileInfoErrorDomain code:kJXCouldNotAccessZippedFileInfo userInfo:errorDetail];
			}
			
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (instancetype)initFileInfoWithArchive:(zip_t *)archive filePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
{
	if (filePath == nil)  return nil;
	else  return [self initFileInfoWithArchive:archive
										 index:0
									  filePath:filePath
									   options:options
										 error:error];
}

+ (instancetype)zippedFileInfoWithArchive:(zip_t *)archive filePath:(NSString *)filePath options:(JXZippedFileOptions)options error:(NSError **)error;
{
	return [[[JXZippedFileInfo alloc] initFileInfoWithArchive:archive
														index:0
													 filePath:filePath
													  options:options
														error:error] autorelease];
}

- (instancetype)initFileInfoWithArchive:(zip_t *)archive index:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
{
	return [self initFileInfoWithArchive:archive
								   index:index
								filePath:nil
								 options:options
								   error:error];
}

+ (instancetype)zippedFileInfoWithArchive:(zip_t *)archive index:(NSUInteger)index options:(JXZippedFileOptions)options error:(NSError **)error;
{
	return [[[JXZippedFileInfo alloc] initFileInfoWithArchive:archive
														index:index
													 filePath:nil
													  options:options
														error:error] autorelease];
}

- (void)dealloc
{
	// We don’t need to free anything here: 
	// the only non-scalar value, the name string, must not be freed (or modified), and becomes invalid when the archive itself is closed.
	
	[super dealloc];
}


- (NSString *)path;
{
	if (_file_info.valid & ZIP_STAT_NAME) {
		// FIXME: We assume the file names are UTF-8.
		return @(_file_info.name);
	}
	else {
		return nil;
	}
}

- (NSUInteger)index;
{
	if (_file_info.valid & ZIP_STAT_INDEX)  return (NSUInteger)_file_info.index;
	else  return NSNotFound;
}

- (NSUInteger)size;
{
	if (_file_info.valid & ZIP_STAT_SIZE)  return (NSUInteger)_file_info.size;
	else  return NSNotFound;
}

- (NSUInteger)compressedSize;
{
	if (_file_info.valid & ZIP_STAT_COMP_SIZE)  return (NSUInteger)_file_info.comp_size;
	else  return NSNotFound;
}

- (NSDate *)modificationDate;
{
	if (_file_info.valid & ZIP_STAT_MTIME) {
		return [NSDate dateWithTimeIntervalSince1970:_file_info.mtime];
	}
	else {
		return nil;
	}
}


- (BOOL)hasCRC;
{
	if (_file_info.valid & ZIP_STAT_CRC)  return YES;
	else  return NO;
}

- (uint32_t)CRC;
{
	return (uint32_t)_file_info.crc;
}


- (uint16_t)compressionMethod;
{
	if (_file_info.comp_method & ZIP_STAT_COMP_METHOD)  return (uint16_t)_file_info.crc;
	else  return ZIP_EM_UNKNOWN;
}

- (uint16_t)encryptionMethod;
{
	if (_file_info.encryption_method & ZIP_STAT_ENCRYPTION_METHOD)  return (uint16_t)_file_info.crc;
	else  return 0xffff; // Unknown
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

