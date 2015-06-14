//
//  JXZippedFileInfo.h
//  odt-testbed
//
//  Created by Jan on 10.12.11.
//  Copyright 2012 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JXZippedFileInfo : NSObject

// FIXME: the properties currently are read only

@property (nonatomic, readonly, copy) NSString *path;				// path of the file
@property (nonatomic, readonly, assign) NSUInteger index;			// index within the archive
@property (nonatomic, readonly, assign) NSUInteger size;				// size of the file (uncompressed)
@property (nonatomic, readonly, assign) NSUInteger compressedSize;	// size of the file (compressed)
@property (nonatomic, readonly, copy) NSDate *modificationDate;	// modification date

@property (nonatomic, readonly, assign) BOOL hasCRC;
@property (nonatomic, readonly, assign) uint32_t CRC;				// crc of file data

// To get more info about the values returned from the following two methods,
// check the libzip header file for now!
@property (nonatomic, readonly, assign) uint16_t compressionMethod;	// compression method used
@property (nonatomic, readonly, assign) uint16_t encryptionMethod;	// encryption method used

@end
