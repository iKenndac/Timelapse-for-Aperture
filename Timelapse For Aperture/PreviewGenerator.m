//
//  PreviewGenerator.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 10/05/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "PreviewGenerator.h"
#import "TimeLapseApertureExporter.h"
#import <QTKit/QTKit.h>

@implementation PreviewGenerator

-(id)initWithExporter:(TimeLapseApertureExporter *)anExporter {
    
    if ((self = [super init])) {
        // Initialization code here.
        self.exporter = anExporter;
        [self performSelectorInBackground:@selector(generatePreview) withObject:nil];
    }
    
    return self;
}

@synthesize exporter;
@synthesize cancelled;

-(void)generatePreview {
    
    [self retain];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Remove old preview. Done on thread to prevent locking the UI.
    
    if ([self.exporter.previewPath length] > 0)
        [[NSFileManager defaultManager] removeItemAtPath:self.exporter.previewPath error:nil];
    
    self.exporter.previewPath = nil;
    
    NSUInteger totalFrameCount = 0;
    
    @synchronized(self.exporter.exportManager) {
        totalFrameCount = [self.exporter.exportManager imageCount];
    }
    
    double fps = 0;
    double frameFieldValue = [self.exporter.frameRateFieldValue doubleValue];
    
    if ([self.exporter.frameRateFieldModifier unsignedIntegerValue] == kFrameRateFramesPerSecondModifier) {
        fps = frameFieldValue;
    } else {
        fps = 1.0 / frameFieldValue;
    }
    
    NSTimeInterval frameDuration = 1.0 / fps;
    QTTime oneFrame = QTMakeTime(1000, (long)(fps * 1000));
    
    NSUInteger previewFrameCount = (totalFrameCount * frameDuration) >= kMaximumPreviewLength ?
                                        ceil(kMaximumPreviewLength / frameDuration) : totalFrameCount;
    
    if (self.cancelled) {
        [pool drain];
        [self release];
        return;
    }
    
    NSString *newPreviewPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    QTMovie *previewMovie = [[[QTMovie alloc] initToWritableFile:newPreviewPath
                                                           error:nil] autorelease];
    
    for (NSUInteger currentFrame = 0; currentFrame < previewFrameCount; currentFrame++) {
        
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"jpeg", QTAddImageCodecType,
                                    [NSNumber numberWithLong:codecHighQuality], QTAddImageCodecQuality,
                                    [NSNumber numberWithLong:1000], QTTrackTimeScaleAttribute, nil];
        
        NSImage *frame = nil;
        @synchronized(self.exporter.exportManager) {
            frame = [self.exporter.exportManager thumbnailForImageAtIndex:(unsigned int)currentFrame
                                                                     size:kExportThumbnailSizeThumbnail];
        }
        
        [previewMovie addImage:frame
                   forDuration:oneFrame
                withAttributes:attributes];
        
        [innerPool drain];
        
        if (self.cancelled) {
            [[NSFileManager defaultManager] removeItemAtPath:newPreviewPath error:nil];
            [pool drain];
            [self release];
            return;
        }
    }
    
    if ([previewMovie canUpdateMovieFile])
        [previewMovie updateMovieFile];
    
    if (self.cancelled) {
        [[NSFileManager defaultManager] removeItemAtPath:newPreviewPath error:nil];
        [pool drain];
        [self release];
        return;
    }
    
    self.exporter.previewPath = newPreviewPath;
    [self.exporter performSelectorOnMainThread:@selector(setPreview:)
                                    withObject:previewMovie
                                 waitUntilDone:YES];
    
    [pool drain];
    [self release];
}

-(void)dealloc {
    self.exporter = nil;
    [super dealloc];
}

@end
