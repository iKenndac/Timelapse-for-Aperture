//
//  PreviewGenerator.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 10/05/2011.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
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
