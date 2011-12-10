//
//  JXZippedFileInfo.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import "JXZippedFileInfo.h"

#import "JXZip.h"

struct zip_file_info_t {
	struct zip_stat	stats;
};

NSString * const	JXZippedFileInfoErrorDomain			= @"de.geheimwerk.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1003


@implementation JXZippedFileInfo

- (JXZippedFileInfo *)initFileInfoWithArchive:(void *)archive fileName:(NSString *)fileName error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (archive == NULL)  return nil;
		
		struct zip *za = (struct zip *)archive;

		zip_file_info_ptr = malloc(sizeof(struct zip_file_info_t));

		const char *content_file_name = [fileName UTF8String]; // autoreleased
		if (zip_stat(za, content_file_name, 0, &(zip_file_info_ptr->stats)) < 0) {
			if (error != NULL) {
				NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not access file info for “%@” in zipped file: %s", @"Cannot access file info in zipped file"), 
												  fileName, zip_strerror(za)];
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

+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(void *)archive fileName:(NSString *)fileName error:(NSError **)error;
{
	return [[[JXZippedFileInfo alloc] initFileInfoWithArchive:archive fileName:fileName error:error] autorelease];
}

- (void)dealloc
{
	if (zip_file_info_ptr != NULL)  free(zip_file_info_ptr);
	
	[super dealloc];
}


#if 0
- (NSString *)name;
{
	
	return ;
}

#endif
- (NSUInteger)index;
{
	
	return (NSUInteger)zip_file_info_ptr->stats.index;
}

- (NSUInteger)size;
{
	
	return (NSUInteger)zip_file_info_ptr->stats.size;
}

#if 0
- (NSUInteger)compressedSize;
- (NSDate *)modificationDate;
- (uint32_t)crc;
- (uint16_t)compressionMethod;
- (uint16_t)encryptionMethod;
#endif


@end
