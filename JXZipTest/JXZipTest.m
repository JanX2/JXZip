//
//  JXZipTest.m
//  JXZipTest
//
//  Created by Jan on 16.07.12.
//
//

#import "JXZipTest.h"

#import <JXZip/JXZip.h>

static JXZip *zipArchive;

@implementation JXZipTest

- (void)setUp
{
	[super setUp];
	
	NSError *error = nil;
	
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	zipArchive = [[JXZip alloc] initWithURL:[testBundle URLForResource:@"test" withExtension:@"zip"] error:&error];
	if (zipArchive == nil) {
		NSLog(@"%@", error);
	}
}

- (void)tearDown
{
	[zipArchive release];
	
	[super tearDown];
}


- (void)testFileCount
{
	NSUInteger fileCount = zipArchive.fileCount;
	
	STAssertEquals(fileCount, 3LU, @"File count differs from the expected value. ");
}

- (void)testEnumerateFiles
{
	NSError *error = nil;
	
	NSUInteger fileCount = zipArchive.fileCount;
	JXZippedFileInfo *zippedFileInfo = nil;
	NSString *filePath = nil;
	
	for (NSUInteger i = 0; i < fileCount; i++) {
		zippedFileInfo = [zipArchive zippedFileInfoForIndex:i error:&error];
		
		STAssertNotNil(zippedFileInfo,
					   [NSString stringWithFormat:@"Couldn’t access file %lu in %@. ", (unsigned long)i, zipArchive.URL]);
		
		if (zippedFileInfo == nil)  continue;
		
		filePath = zippedFileInfo.path;
		
		STAssertNotNil(filePath,
					   [NSString stringWithFormat:@"File path for file %lu in %@ was nil. ", (unsigned long)i, zipArchive.URL]);
#if DEBUG
		puts([filePath UTF8String]);
#endif
	}
	
#if DEBUG
	puts("");
#endif
}

@end
