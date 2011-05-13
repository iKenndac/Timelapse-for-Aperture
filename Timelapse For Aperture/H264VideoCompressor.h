//
//  VideoCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/11/11.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoCompressor.h"

@interface H264VideoCompressor : NSWindowController <VideoCompressor> {
@private
    NSURL *videoFileURL;
    AVAssetWriterInputPixelBufferAdaptor *imageInputAdaptor;
    AVAssetWriter *videoWriter;
    uint64_t currentEndLocation;
    NSNumber *compressionBitRateMbit;
}

-(IBAction)closeSheet:(id)sender;

@property (nonatomic, readwrite, retain) AVAssetWriterInputPixelBufferAdaptor *imageInputAdaptor;
@property (nonatomic, readwrite, retain) AVAssetWriter *videoWriter;
@property (nonatomic, readwrite, copy) NSNumber *compressionBitRateMbit;

@end
