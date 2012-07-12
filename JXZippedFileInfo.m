//
//  JXZippedFileInfo.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import "JXZippedFileInfo.h"

#import "JXZip.h"

#import <libzip/zip.h>

NSString * const	JXZippedFileInfoErrorDomain			= @"de.geheimwerk.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1101


@implementation JXZippedFileInfo {
	struct zip_stat	file_info;
}

- (JXZippedFileInfo *)initFileInfoWithArchive:(void *)archive filePath:(NSString *)filePath error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (archive == NULL)  return nil;
		
		struct zip *za = (struct zip *)archive;

		// CHANGEME: Add support for options/flags
		const char *file_path = [filePath UTF8String]; // autoreleased
		if (zip_stat(za, file_path, (ZIP_FL_ENC_UTF_8), &file_info) < 0) {
			if (error != NULL) {
				NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for “%@” in zipped file: %s", @"Cannot access file info in zipped file"), 
												  filePath, zip_strerror(za)];
				NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
											 errorDescription, NSLocalizedDescriptionKey, 
											 nil];
				*error = [NSError errorWithDomain:JXZippedFileInfoErrorDomain code:kJXCouldNotAccessZippedFileInfo userInfo:errorDetail];
			}
			
			return nil;
		}
	}
	
	return self;
}

+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(void *)archive filePath:(NSString *)filePath error:(NSError **)error;
{
	return [[[JXZippedFileInfo alloc] initFileInfoWithArchive:archive filePath:filePath error:error] autorelease];
}

- (void)dealloc
{
	// We don’t need to free anything here: 
	// the only non-scalar value, the name string, must not be freed (or modified), and becomes invalid when the archive itself is closed.
	
	[super dealloc];
}


- (NSString *)path;
{
	if (file_info.valid & ZIP_STAT_NAME) {
		// CHANGEME: We assume the file names are UTF-8.
		return [NSString stringWithCString:file_info.name encoding:NSUTF8StringEncoding];
	}
	else {
		return nil;
	}
}

- (NSUInteger)index;
{
	if (file_info.valid & ZIP_STAT_INDEX)  return (NSUInteger)file_info.index;
	else  return NSNotFound;
}

- (NSUInteger)size;
{
	if (file_info.valid & ZIP_STAT_SIZE)  return (NSUInteger)file_info.size;
	else  return NSNotFound;
}

- (NSUInteger)compressedSize;
{
	if (file_info.valid & ZIP_STAT_COMP_SIZE)  return (NSUInteger)file_info.comp_size;
	else  return NSNotFound;
}

- (NSDate *)modificationDate;
{
	if (file_info.valid & ZIP_STAT_MTIME) {
		return [NSDate dateWithTimeIntervalSince1970:file_info.mtime];
	}
	else {
		return nil;
	}
}

- (uint32_t)crc;
{
	if (file_info.valid & ZIP_STAT_CRC)  return (uint32_t)file_info.crc;
	else  return NSNotFound;
}

#if 0
- (uint16_t)compressionMethod;
- (uint16_t)encryptionMethod;
#endif


@end
