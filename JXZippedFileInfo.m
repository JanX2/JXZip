//
//  JXZippedFileInfo.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import "JXZippedFileInfo.h"

#import "JXZip.h"

NSString * const	JXZippedFileInfoErrorDomain			= @"de.geheimwerk.Error.JXZippedFileInfo";

#define kJXCouldNotAccessZippedFileInfo 1003


@implementation JXZippedFileInfo

- (JXZippedFileInfo *)initFileInfoWithArchive:(void *)archive fileName:(NSString *)fileName error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (archive == NULL)  return nil;
		
		struct zip *za = (struct zip *)archive;

		const char *file_name = [fileName UTF8String]; // autoreleased
		if (zip_stat(za, file_name, 0, &file_info) < 0) {
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
	
	return (NSUInteger)file_info.index;
}

- (NSUInteger)size;
{
	
	return (NSUInteger)file_info.size;
}

#if 0
- (NSUInteger)compressedSize;
- (NSDate *)modificationDate;
- (uint32_t)crc;
- (uint16_t)compressionMethod;
- (uint16_t)encryptionMethod;
#endif


@end
