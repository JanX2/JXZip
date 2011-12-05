//
//  JXZip.m
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import "JXZip.h"

NSString * const	JXZipErrorDomain						= @"de.geheimwerk.Error.JXZip";

#define kJXCouldNotOpenZip 1001
#define kJXCouldNotSaveZip 1002


@implementation JXZip

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
