//
//  MotionJPEGCompressor.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "MotionJPEGCompressor.h"

static uint32_t const kQuickTimeExportTimeScale = 1000000; 
// ^ Using a number as high as the one in H264Compressor.m causes QTKit to silently fail.

@implementation MotionJPEGCompressor

-(id)initWithPropertyListRepresentation:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@synthesize videoFileURL;
@synthesize movie;

-(BOOL)canBeConfigured {
    return NO;
}

-(NSString *)name {
    return @"Motion JPEG";
}

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow {
    
}

-(NSDictionary *)userDefaults {
    return nil;
}

#pragma mark -

-(void)prepareForImagesWithDestinationFolderURL:(NSURL *)destination videoName:(NSString *)name {
    
    NSURL *targetURL = [destination URLByAppendingPathComponent:name];
    
    if (![[targetURL pathExtension] isEqualToString:@"mov"])
        targetURL = [targetURL URLByAppendingPathExtension:@"mov"];
    
    self.videoFileURL = targetURL;
    
    NSString *videoFilePath = [self.videoFileURL path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoFilePath])
        [[NSFileManager defaultManager] removeItemAtURL:self.videoFileURL error:nil];
    
    self.movie = [[[QTMovie alloc] initToWritableFile:videoFilePath
                                                error:nil] autorelease];
}

-(void)appendImageToVideo:(NSImage *)anImage forOneFrameAtFPS:(double)fps {
    
    QTTime oneFrame = QTMakeTime(kQuickTimeExportTimeScale, (long)(fps * kQuickTimeExportTimeScale));
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"jpeg", QTAddImageCodecType,
                                [NSNumber numberWithLong:codecHighQuality], QTAddImageCodecQuality,
                                [NSNumber numberWithUnsignedInteger:kQuickTimeExportTimeScale], QTTrackTimeScaleAttribute, nil];
    
    [self.movie addImage:anImage forDuration:oneFrame withAttributes:attributes];
}

-(void)cleanup {
    if ([self.movie canUpdateMovieFile])
        [self.movie updateMovieFile];
    
    self.movie = nil;
}

-(void)dealloc {
    self.movie = nil;
    self.videoFileURL = nil;
    [super dealloc];
}

@end
