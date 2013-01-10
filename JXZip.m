//
//  JXZip.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import "JXZip.h"

#import "JXZippedFileInfo.h"
#import <libzip Mac/zip.h>

NSString * const	JXZipErrorDomain						= @"de.geheimwerk.Error.JXZip";

const int kJXCouldNotOpenZip			= 1001;
const int kJXCouldNotSaveZip			= 1002;
const int kJXCouldNotOpenZippedFile		= 1003;
const int kJXCouldNotReadZippedFile		= 1004;
const int kJXInvalidZippedFileInfo		= 1005;
const int kJXCouldNotAddZippedFile		= 1006;
const int kJXCouldNotReplaceZippedFile	= 1007;

@interface JXZippedFileInfo (Protected)
+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;
- (JXZippedFileInfo *)initFileInfoWithArchive:(struct zip *)archive filePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;

+ (JXZippedFileInfo *)zippedFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
- (JXZippedFileInfo *)initFileInfoWithArchive:(struct zip *)archive index:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
@end

@interface JXZip ()
@property (nonatomic, readwrite, retain) NSURL *URL;
@property (nonatomic, readwrite, assign) struct zip *za;
@end

@implementation JXZip {
	NSURL *_URL;
	struct zip *_za;
}

@synthesize URL = _URL;
@synthesize za = _za;

+ (JXZip *)zipWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [[[JXZip alloc] initWithURL:fileURL options:0 error:error] autorelease];
}

+ (JXZip *)zipWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;
{
	return [[[JXZip alloc] initWithURL:fileURL options:options error:error] autorelease];
}

- (JXZip *)initWithURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [self initWithURL:fileURL options:0 error:error];
}

- (JXZip *)initWithURL:(NSURL *)fileURL options:(JXZipOptions)options error:(NSError **)error;
{
	self = [super init];
	
	if (self) {
		if (fileURL == nil) {
			[self release];
			return nil;
		}
		
		self.URL = fileURL;
		
		// NOTE: We could rewrite this using file descriptors.
		const char * zip_file_path = [[fileURL path] UTF8String];
		int err;
		
		_za = zip_open(zip_file_path, (options & ZIP_FL_ENC_UTF_8), &err);
		
		if (_za == NULL) {
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
			
			[self release];
			return nil;
		}
	}
	
	return self;
}



- (void) dealloc
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

- (JXZippedFileInfo *)zippedFileInfoForIndex:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za index:index options:options error:error];
}

- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za filePath:filePath options:0 error:error];
}

- (JXZippedFileInfo *)zippedFileInfoForFilePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;
{
	return [JXZippedFileInfo zippedFileInfoWithArchive:_za filePath:filePath options:options error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index error:(NSError **)error;
{
	return [self dataForFileAtIndex:index options:0 error:error];
}

- (NSData *)dataForFileAtIndex:(NSUInteger)index options:(JXZipOptions)options error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForIndex:index error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath error:(NSError **)error;
{
	return [self dataForFilePath:filePath options:0 error:error];
}

- (NSData *)dataForFilePath:(NSString *)filePath options:(JXZipOptions)options error:(NSError **)error;
{
	JXZippedFileInfo *zippedFileInfo = [self zippedFileInfoForFilePath:filePath error:error];
	if (zippedFileInfo == nil)  return nil;
	else  return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo error:(NSError **)error;
{
	return [self dataForZippedFileInfo:zippedFileInfo options:0 error:error];
}

- (NSData *)dataForZippedFileInfo:(JXZippedFileInfo *)zippedFileInfo options:(JXZipOptions)options error:(NSError **)error;
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

	struct zip_file *zipped_file = zip_fopen_index(_za, zipped_file_index, (options & ZIP_FL_ENC_UTF_8));
	if (zipped_file == NULL) {
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Could not open zipped file “%@” in archive “%@”: %s", @"Could not open zipped file"), 
											  zippedFileInfo.path, self.URL, zip_strerror(_za)];
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
											  zippedFileInfo.path, self.URL, zip_file_strerror(zipped_file)];
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


- (BOOL)addFileWithPath:(NSString *)filePath forData:(NSData *)data error:(NSError **)error;
{
	if ((filePath == nil) || (data == nil))  return NO;
	
	// CHANGEME: Passing the index back might be helpful
	
	const char * file_path = [filePath UTF8String];
	struct zip_source *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
	zip_int64_t index;
	
	if ((file_zip_source == NULL)
		|| ((index = zip_file_add(_za, file_path, file_zip_source, (ZIP_FL_ENC_UTF_8))) < 0)
		) { 
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while adding zipped file “%@” in archive “%@”: %s", @"Error while adding zipped file"), 
											  filePath, self.URL, zip_strerror(_za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
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
	
	struct zip_source *file_zip_source = zip_source_buffer(_za, [data bytes], [data length], 0);
	
	if ((file_zip_source == NULL)
		|| (zip_file_replace(_za, zippedFileInfo.index, file_zip_source, 0) < 0)
		) { 
		if (error != NULL) {
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error while replacing zipped file “%@” in archive “%@”: %s", @"Error while replacing zipped file"), 
											  zippedFileInfo.path, self.URL, zip_strerror(_za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
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
			NSDictionary *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"The zip archive “%@” could not be saved: %s", @"Cannot save zip archive"), 
											  self.URL, zip_strerror(_za)];
			NSDictionary *errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
										 errorDescription, NSLocalizedDescriptionKey, 
										 nil];
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
