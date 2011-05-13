//
//  MotionJPEGCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "VideoCompressor.h"

@interface MotionJPEGCompressor : NSObject <VideoCompressor> {
@private
    QTMovie *movie;
    NSURL *videoFileURL;
}

@property (nonatomic, readwrite, retain) QTMovie *movie;

@end
