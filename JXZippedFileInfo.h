//
//  JXZippedFileInfo.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2011 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JXZippedFileInfo : NSObject {
	 struct zip_file_info_t	*zip_file_info_ptr;
}

#if 0
- (NSString *)name;				// name of the file
#endif
- (NSUInteger)index;			// index within the archive
- (NSUInteger)size;				// size of the file (uncompressed)
#if 0
- (NSUInteger)compressedSize;	// size of the file (compressed)
- (NSDate *)modificationDate;	// modification date
- (uint32_t)crc;				// crc of file data
- (uint16_t)compressionMethod;	// compression method used
- (uint16_t)encryptionMethod;	// encryption method used
#endif

@end
