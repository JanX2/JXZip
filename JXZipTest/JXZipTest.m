//
//  JXZipTest.m
//  JXZipTest
//
//  Created by Jan on 16.07.12.
//
//

#import "JXZipTest.h"

#import <JXZip/JXZip.h>

static JXZip *_zipArchive;

@implementation JXZipTest

- (void)setUp
{
	[super setUp];
	
	NSError *error = nil;
	
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	_zipArchive = [[JXZip alloc] initWithURL:[testBundle URLForResource:@"test" withExtension:@"zip"] error:&error];
	if (_zipArchive == nil) {
		NSLog(@"%@", error);
	}
}

- (void)tearDown
{
	[_zipArchive release];
	
	[super tearDown];
}


- (void)testFileCount
{
	NSUInteger fileCount = _zipArchive.fileCount;
	
	XCTAssertEqual(fileCount, 3LU, @"File count differs from the expected value. ");
}

- (void)testEnumerateFiles
{
	NSError *error = nil;
	
	NSUInteger fileCount = _zipArchive.fileCount;
	JXZippedFileInfo *zippedFileInfo = nil;
	NSString *filePath = nil;
	
	for (NSUInteger i = 0; i < fileCount; i++) {
		zippedFileInfo = [_zipArchive zippedFileInfoForIndex:i error:&error];
		
		XCTAssertNotNil(zippedFileInfo,
						@"Couldn’t access file %lu in %@. ", (unsigned long)i, _zipArchive.URL);
		
		if (zippedFileInfo == nil)  continue;
		
		filePath = zippedFileInfo.path;
		
		XCTAssertNotNil(filePath,
						@"File path for file %lu in %@ was nil. ", (unsigned long)i, _zipArchive.URL);
#if DEBUG
		puts([filePath UTF8String]);
#endif
	}
	
#if DEBUG
	puts("");
#endif
}

@end
