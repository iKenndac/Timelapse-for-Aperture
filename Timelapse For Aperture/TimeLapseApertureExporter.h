//
//  TimeLapseApertureExporter.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 08/05/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "ApertureExportManager.h"
#import "ApertureExportPlugIn.h"

static NSString * const kAlsoExportFramesUserDefaultsKey = @"AlsoExportFrames";
static NSString * const kFrameFieldValueUserDefaultsKey = @"FrameFieldValue";
static NSString * const kFrameFieldModifierUserDefaultsKey = @"FrameModifierValue";
static NSString * const kLastPathUserDefaultsKey = @"LastPath";

static NSInteger const kFrameRateFramesPerSecondModifier = 0;
static NSInteger const kFrameRateSecondsPerFrameModifier = 1;

@interface TimeLapseApertureExporter : NSViewController <ApertureExportPlugIn> {
@private
    
    id <PROAPIAccessing> apiManager;
    NSObject <ApertureExportManager, PROAPIObject> *exportManager;
    // The structure used to pass all progress information back to Aperture
	ApertureExportProgress exportProgress;
    
    NSLock *progressLock;
    
    NSView *firstView;
    NSView *lastView;
    NSTextField *movieNameField;
    
    // Prefs
    
    BOOL alsoExportImages;
    NSNumber *frameRateFieldValue;
    NSNumber *frameRateFieldModifier;
    NSString *lastPath;
    
    // --
    
    QTMovie *movie;
    
}

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;
@property (assign) IBOutlet NSTextField *movieNameField;

@property (nonatomic, readwrite, retain) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, retain) NSObject <ApertureExportManager, PROAPIObject> *exportManager;

@property (nonatomic, readwrite, retain) NSLock *progressLock;
@property (nonatomic, readonly) NSTimeInterval estimatedMovieLength;

// -- Prefs

@property (nonatomic, readwrite) BOOL alsoExportImages;
@property (nonatomic, readwrite, copy) NSNumber *frameRateFieldValue;
@property (nonatomic, readwrite, copy) NSNumber *frameRateFieldModifier;
@property (nonatomic, readwrite, copy) NSString *lastPath;

// --

@property (nonatomic, readwrite, retain) QTMovie *movie;

-(void)lockProgress;
-(void)unlockProgress;

-(IBAction)configureCodec:(id)sender;


@end
