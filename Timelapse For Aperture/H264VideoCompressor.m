//
//  VideoCompressor.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/11/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "H264VideoCompressor.h"

static uint32_t kExportTimeScale = 10000;

@interface H264VideoCompressor()

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size;
-(void)setupWithSize:(NSSize)imageSize;

@end

@implementation H264VideoCompressor

-(id)initWithPropertyListRepresentation:(NSDictionary *)plist {
    
    if (NSClassFromString(@"AVAssetWriterInput") == Nil) {
        [self release];
        return nil;
    }

    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

@synthesize imageInputAdaptor;
@synthesize videoWriter;
@synthesize videoFileURL;

-(BOOL)canBeConfigured {
    return YES;
}

-(NSString *)name {
    return @"H.264";
}

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow {
    
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
}

-(void)appendImageToVideo:(NSImage *)anImage forOneFrameOfDuration:(NSTimeInterval)frameDuration {
    
    if (self.imageInputAdaptor == nil)
        [self setupWithSize:[anImage size]];
    
    CGImageRef image = [anImage CGImageForProposedRect:NULL context:nil hints:nil];
    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image size:NSSizeToCGSize([anImage size])];
    
    while (!self.imageInputAdaptor.assetWriterInput.readyForMoreMediaData) {
        [NSThread sleepForTimeInterval:0.05];
    }
    
    CMTime frameTime = CMTimeMake(currentEndLocation, kExportTimeScale);
    
    if ([self.imageInputAdaptor appendPixelBuffer:buffer
                         withPresentationTime:frameTime])
        currentEndLocation += (uint64_t)(frameDuration * kExportTimeScale);
    
    if (buffer != NULL)
        CFRelease(buffer);
    
    buffer = NULL;
}

-(void)cleanup {
    
    //Finish the session:
    [self.imageInputAdaptor.assetWriterInput markAsFinished]; 
    
    [self.videoWriter endSessionAtSourceTime:CMTimeMake(currentEndLocation, kExportTimeScale)];
    [self.videoWriter finishWriting];
    
}

#pragma mark -

-(void)setupWithSize:(NSSize)imageSize {
    
    NSError *err = nil;
    self.videoWriter = [[[AVAssetWriter alloc] initWithURL:self.videoFileURL
                                                  fileType:AVFileTypeQuickTimeMovie
                                                     error:&err] autorelease];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithDouble:imageSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithDouble:imageSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:videoSettings];
    
    self.imageInputAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                              sourcePixelBufferAttributes:nil];
    
    if (![self.videoWriter canAddInput:videoWriterInput])
        return;
    
    videoWriterInput.expectsMediaDataInRealTime = NO;
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
}

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options, 
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace, 
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), 
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)dealloc {
    self.videoFileURL = nil;
    self.imageInputAdaptor = nil;
    self.videoWriter = nil;
    [super dealloc];
}

@end
