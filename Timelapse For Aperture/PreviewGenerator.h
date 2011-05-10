//
//  PreviewGenerator.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 10/05/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TimeLapseApertureExporter;

@interface PreviewGenerator : NSObject {
@private
    __weak TimeLapseApertureExporter *exporter;
    BOOL cancelled;
}

-(id)initWithExporter:(TimeLapseApertureExporter *)anExporter;

@property (nonatomic, assign, readwrite) __weak TimeLapseApertureExporter *exporter;
@property (readwrite) BOOL cancelled;

@end
