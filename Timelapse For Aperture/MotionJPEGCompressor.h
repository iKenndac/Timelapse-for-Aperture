//
//  MotionJPEGCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "VideoCompressor.h"

@interface MotionJPEGCompressor : NSObject <VideoCompressor> {
@private
    QTMovie *movie;
}

@property (nonatomic, readwrite, retain) QTMovie *movie;

@end
