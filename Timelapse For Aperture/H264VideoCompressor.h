//
//  VideoCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/11/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoCompressor.h"

@interface H264VideoCompressor : NSObject <VideoCompressor> {
@private
    NSURL *videoFileURL;
    AVAssetWriterInputPixelBufferAdaptor *imageInputAdaptor;
    AVAssetWriter *videoWriter;
    uint64_t currentEndLocation;
}

@property (nonatomic, readwrite, retain) AVAssetWriterInputPixelBufferAdaptor *imageInputAdaptor;
@property (nonatomic, readwrite, retain) AVAssetWriter *videoWriter;

@end
