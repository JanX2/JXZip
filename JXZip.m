//
//  JXZip.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import "JXZip.h"

NSString * const	JXZipErrorDomain						= @"de.geheimwerk.Error.JXZip";

#define kJXCouldNotOpenZip				1001
#define kJXCouldNotSaveZip				1002
#define kJXCouldNotOpenZippedFile		1003
#define kJXCouldNotReadZippedFile		1004
#define kJXInvalidZippedFileInfo		1005
#define kJXCouldNotAddZippedFile		1006
#define kJXCouldNotReplaceZippedFile	1007

@interface JXZippedFileInfo (Protected)
+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(void *)archive fileName:(NSString *)fileName error:(NSError **)error;
- (JXZippedFileInfo *)initFileInfoWithArchive:(void *)archive fileName:(NSString *)fileName error:(NSError **)error;
@end

@implementation JXZip

@synthesize zipFileURL;
@synthesize za;

+ (JXZip *)zipWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [[[JXZip alloc] initWithURL:fileURL error:error] autorelease];
}

- (JXZip *)initWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (fileURL == nil)  return nil;
		
		self.zipFileURL = fileURL;
		
		// NOTE: We could rewrite this using file descriptors.
		const char * zip_file_path = [[fileURL path] UTF8String];
		int err;
		
		za = zip_open(zip_file_path, 0, &err);
		
		if (za == NULL) {
			if (error != NULL) {
				char errstr[1024];
				zip_error_to_str(errstr, sizeof(errstr), err, errno);
				NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be opened: %s", @"Cannot open zip archive"), 
												  fileURL, errstr];
				NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
							   errorDescription, NSLocalizedDescriptionKey, 
							   nil];
				*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotOpenZip userInfo:errorDetail];
			}
			
			return nil;
		}
	}
	
	return self;
}



- (void) dealloc
{
	self.zipFileURL = nil;
	
	if (za != NULL) {
		zip_unchange_all(za);
		zip_close(za);
		za = NULL;
	}

	[super dealloc];
}


- (NSUInteger)fileCount;
{
	if (za == NULL)  return NSNotFound;
	
	// The underlying library uses an int to store the count so this is safe in any case.
	return (NSUInteger)zip_get_num_entries(za, ZIP_FL_UNCHANGED);
}

#if 0
- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:za index:(NSUInteger)index error:error];
}
#endif

- (JXZippedFileInfo *)zippedFileInfoForFileName:(NSString *)fileName error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:za fileName:fileName error:error];
}

#if 0
- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForIndex:index error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo error:error];
}
#endif

- (NSData *)dataForFileName:(NSString *)fileName error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForFileName:fileName error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo error:error];
}

- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;
{
	if (zippedFileInfo == nil)  return nil;

	zip_uint64_t zipped_file_index = zippedFileInfo.index;
	zip_uint64_t zipped_file_size = zippedFileInfo.size;
	
	if ((zipped_file_index == NSNotFound) || (zipped_file_size == NSNotFound)) {
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Invalid zipped file info.", @"Invalid zipped file info")];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXInvalidZippedFileInfo userInfo:errorDetail];
		}
		
		return nil;
	}

	struct zip_file *zipped_file = zip_fopen_index(za, zipped_file_index, 0);
	if (zipped_file == NULL) {
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not open zipped file “%@” in archive “%@”: %s", @"Could not open zipped file"), 
											  zippedFileInfo.name, zipFileURL, zip_strerror(za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotOpenZippedFile userInfo:errorDetail];
		}
		
		return nil;
	}
	
	char *buf = malloc(zipped_file_size); // freed by NSData
	
	zip_int64_t n = zip_fread(zipped_file, buf, zipped_file_size);
	if (n < (zip_int64_t)zipped_file_size) {
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while reading zipped file “%@” in archive “%@”: %s", @"Error while reading zipped file"), 
											  zippedFileInfo.name, zipFileURL, zip_file_strerror(zipped_file)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotReadZippedFile userInfo:errorDetail];
		}
		
		zip_fclose(zipped_file);
		
		free(buf);
		
		return nil;
	}
	
	zip_fclose(zipped_file);
	
	return [NSData dataWithBytesNoCopy:buf length:(NSUInteger)zipped_file_size freeWhenDone:YES];
}


- (BOOL)addFileWithName:(NSString *)fileName forData:(NSData *)data error:(NSError **)error;
{
	if ((fileName == nil) || (data == nil))  return NO;
	
	const char * file_name = [fileName UTF8String];
	struct zip_source *file_zip_source = zip_source_buffer(za, [data bytes], [data length], 0);
	
	if ((file_zip_source == NULL)
		|| (zip_add(za, file_name, file_zip_source) < 0)
		) { 
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while adding zipped file “%@” in archive “%@”: %s", @"Error while adding zipped file"), 
											  fileName, zipFileURL, zip_strerror(za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotAddZippedFile userInfo:errorDetail];
		}
		
		if (file_zip_source != NULL)  zip_source_free(file_zip_source); 
		
		return NO;
	}
	
	// We don’t need to zip_source_free() here, as libzip takes care of it once we have reached this line.
	
	return YES;
}

- (BOOL)replaceFile:(JXZippedFileInfo *)zippedFileInfo withData:(NSData *)data error:(NSError **)error;
{
	if (zippedFileInfo == nil)  return NO;
	
	struct zip_source *file_zip_source = zip_source_buffer(za, [data bytes], [data length], 0);
	
	if ((file_zip_source == NULL)
		|| (zip_replace(za, zippedFileInfo.index, file_zip_source) < 0)
		) { 
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while replacing zipped file “%@” in archive “%@”: %s", @"Error while replacing zipped file"), 
											  zippedFileInfo.name, zipFileURL, zip_strerror(za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotReplaceZippedFile userInfo:errorDetail];
		}
		
		if (file_zip_source != NULL)  zip_source_free(file_zip_source); 
		
		return NO;
	}
	
	// We don’t need to zip_source_free() here, as libzip takes care of it once we have reached this line.
	
	return YES;
}


- (BOOL)saveAndReturnError:(NSError **)error;
{
	if (za == NULL)  return NO;
	
	if (zip_close(za) < 0) {
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %s", @"Cannot save zip archive"), 
											  zipFileURL, zip_strerror(za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
			*error = [NSError errorWithDomain:JXZipErrorDomain code:kJXCouldNotSaveZip userInfo:errorDetail];
		}

		return NO;
	}
	else {
		za = NULL;
		return YES;
	}
}


@end
