//
//  VideoCompressor.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/13/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "VideoCompressor.h"

@implementation VideoCompressorUtilities

+(NSURL *)fileURLWithUniqueNameForFile:(NSString *)fileName inParentDirectory:(NSURL *)parent {
    
	// This method passes back a unique file name for the passed file and path(s). 
	// So, for example, if the caller wants to put a file called "Hello.txt" in ~/Desktop
	// and that file already exists, it'll give back ~/Desktop/Hello 2.txt".
	// The method respects extensions and will keep incrementing the number until it finds a 
	// name that's unique in the given directory. 
    
	NSUInteger numericSuffix = 2;
    NSURL *potentialURL = [parent URLByAppendingPathComponent:fileName];
	BOOL fileURLAvailable = ![potentialURL checkResourceIsReachableAndReturnError:nil];
    
    while ((!fileURLAvailable)) {
        
        NSString *newName = [NSString stringWithFormat:@"%@ %d.%@", [fileName stringByDeletingPathExtension], numericSuffix, [fileName pathExtension]];
        potentialURL = [parent URLByAppendingPathComponent:newName];
        fileURLAvailable = ![potentialURL checkResourceIsReachableAndReturnError:nil];
        
        numericSuffix++;
    }
    
	return potentialURL;
}

@end
