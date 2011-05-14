//
//  VideoCompressor.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/11/11.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//

#import "H264VideoCompressor.h"

static uint32_t const kExportTimeScale = 1000000000;
static NSString * const kCompressionBitRateMbitUserDefaultsKey = @"MegaBits";

@interface H264VideoCompressor()

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size;
-(void)setupWithSize:(NSSize)imageSize;

@end

@implementation H264VideoCompressor

-(id)initWithPropertyListRepresentation:(NSDictionary *)plist {
    
    if (NSClassFromString(@"AVAssetWriterInput") == nil) {
        [self release];
        return nil;
    }

    if ((self = [super initWithWindowNibName:@"H264VideoCompressor"])) {
        // Initialization code here.
        
        if ([plist valueForKey:kCompressionBitRateMbitUserDefaultsKey]) {
            self.compressionBitRateMbit = [plist valueForKey:kCompressionBitRateMbitUserDefaultsKey];
        } else {
            self.compressionBitRateMbit = [NSNumber numberWithInteger:2.0];
        }
    }
    
    return self;
}

@synthesize imageInputAdaptor;
@synthesize videoWriter;
@synthesize videoFileURL;
@synthesize compressionBitRateMbit;

-(BOOL)canBeConfigured {
    return YES;
}

-(NSString *)name {
    return NSLocalizedStringFromTableInBundle(@"H264CompressorName", @"Localizable", [NSBundle bundleForClass:[self class]], @"H.264");
}

+(NSSet *)keyPathsForValuesAffectingUserDefaults {
    return [NSSet setWithObject:@"compressionBitRateMbit"];
}

-(NSDictionary *)userDefaults {
    return [NSDictionary dictionaryWithObject:self.compressionBitRateMbit
                                       forKey:kCompressionBitRateMbitUserDefaultsKey];
}

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow {
    [NSApp beginSheet:self.window
       modalForWindow:parentWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

-(IBAction)closeSheet:(id)sender {
    [NSApp endSheet:self.window];
    [self.window orderOut:sender];
}

#pragma mark -

-(void)prepareForImagesWithDestinationFolderURL:(NSURL *)destination videoName:(NSString *)name {
    
    if (![[name pathExtension] isEqualToString:@"mp4"])
        name = [name stringByAppendingPathExtension:@"mp4"];
    
    self.videoFileURL = [VideoCompressorUtilities fileURLWithUniqueNameForFile:name inParentDirectory:destination];
}

-(void)appendImageToVideo:(NSImage *)anImage forOneFrameAtFPS:(double)fps {
    
    if (self.imageInputAdaptor == nil)
        [self setupWithSize:[anImage size]];
    
    CGImageRef image = [anImage CGImageForProposedRect:NULL context:nil hints:nil];
    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image size:NSSizeToCGSize([anImage size])];
    
    while (!self.imageInputAdaptor.assetWriterInput.readyForMoreMediaData) {
        [NSThread sleepForTimeInterval:0.05];
    }
    
    NSTimeInterval frameDuration = 1.0 / fps;
    
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
                                                  fileType:AVFileTypeMPEG4
                                                     error:&err] autorelease];
    
    NSNumber *compressionRateBits = [NSNumber numberWithDouble:[self.compressionBitRateMbit doubleValue] * 1024 * 1024];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSDictionary dictionaryWithObject:compressionRateBits forKey:AVVideoAverageBitRateKey], AVVideoCompressionPropertiesKey,
                                   AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                                   [NSNumber numberWithDouble:imageSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithDouble:imageSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:videoSettings];
    
    self.imageInputAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                              sourcePixelBufferAttributes:nil];
    
    if (![self.videoWriter canAddInput:videoWriterInput])
        return;
    
    [self.videoWriter addInput:videoWriterInput];
    
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
