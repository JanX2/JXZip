//
//  JXZippedFileInfo.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import "JXZippedFileInfo.h"

#import "JXZip.h"

#import <libzip/zip.h>

NSString * const	JXZippedFileInfoErrorDomain			= @"de.geheimwerk.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1101


@implementation JXZippedFileInfo {
	struct zip_stat	_file_info;
}

- (JXZippedFileInfo *)initFileInfoWithArchive:(struct zip *)archive
										index:(NSUInteger)index
									 filePath:(NSString *)filePath
									  options:(JXZipOptions)options
										error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (archive == NULL)  return nil;
		
		options = (options & ZIP_FL_ENC_UTF_8);
		
		int idx; // FIXME: libzip shouldn’t use int, it should use zip_int64_t
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
				NSDictionary *errorDescription;
				if (filePath != nil) {
					errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for “%@” in zipped file: %s", @"Cannot access file info in zipped file"),
										filePath, zip_strerror(archive)];
				}
				else {
					errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for file %lu in zipped file: %s", @"Cannot access file info in zipped file"),
										(unsigned long)index, zip_strerror(archive)];
				}
				NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
											 errorDescription, NSLocalizedDescriptionKey,
											 nil];
				*error = [NSError errorWithDomain:JXZippedFileInfoErrorDomain code:kJXCouldNotAccessZippedFileInfo userInfo:errorDetail];
			}
			
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (JXZippedFileInfo *)initFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;
{
	return [self initFileInfoWithArchive:archive
								   index:0
								filePath:filePath
								 options:options
								   error:error];
}

+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;
{
	return [[[JXZippedFileInfo alloc] initFileInfoWithArchive:archive
														index:0
													 filePath:filePath
													  options:options
														error:error] autorelease];
}

- (JXZippedFileInfo *)initFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
{
	return [self initFileInfoWithArchive:archive
								   index:index
								filePath:nil
								 options:options
								   error:error];
}

+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
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
		return [NSString stringWithCString:_file_info.name encoding:NSUTF8StringEncoding];
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
