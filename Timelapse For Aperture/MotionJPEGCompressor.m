//
//  MotionJPEGCompressor.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
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
    return NSLocalizedStringFromTableInBundle(@"MJPEGCompressorName", @"Localizable", [NSBundle bundleForClass:[self class]], @"Motion JPEG");
}

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow {
    
}

-(NSDictionary *)userDefaults {
    return nil;
}

#pragma mark -

-(void)prepareForImagesWithDestinationFolderURL:(NSURL *)destination videoName:(NSString *)name {
    
    if (![[name pathExtension] isEqualToString:@"mov"])
        name = [name stringByAppendingPathExtension:@"mov"];
    
    self.videoFileURL = [VideoCompressorUtilities fileURLWithUniqueNameForFile:name inParentDirectory:destination];
    
    self.movie = [[[QTMovie alloc] initToWritableFile:[self.videoFileURL path]
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
