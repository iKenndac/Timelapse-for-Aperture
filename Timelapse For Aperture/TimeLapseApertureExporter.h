//
//  TimeLapseApertureExporter.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 08/05/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApertureExportManager.h"
#import "ApertureExportPlugIn.h"
#import "VideoCompressor.h"
#import <QTKit/QTKit.h>

@class PreviewGenerator;

static NSString * const kAlsoExportFramesUserDefaultsKey = @"AlsoExportFrames";
static NSString * const kFrameFieldValueUserDefaultsKey = @"FrameFieldValue";
static NSString * const kFrameFieldModifierUserDefaultsKey = @"FrameModifierValue";
static NSString * const kLastPathUserDefaultsKey = @"LastPath";

static NSInteger const kFrameRateFramesPerSecondModifier = 0;
static NSInteger const kFrameRateSecondsPerFrameModifier = 1;

static NSTimeInterval const kMaximumPreviewLength = 5.0;

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
    NSView *generatingPreviewView;
    NSView *previewView;
    NSBox *previewContainer;
    
    // Prefs
    
    BOOL alsoExportImages;
    NSNumber *frameRateFieldValue;
    NSNumber *frameRateFieldModifier;
    NSString *lastPath;
    
    // --
    
    QTMovie *preview;
    NSString *previewPath;
    PreviewGenerator *previewGenerator;
    id <VideoCompressor> videoCompressor;
    
    // -- 
    
    NSArray *availableCompressors;
}

@property (assign) IBOutlet NSView *firstView;
@property (assign) IBOutlet NSView *lastView;
@property (assign) IBOutlet NSTextField *movieNameField;
@property (assign) IBOutlet NSView *generatingPreviewView;
@property (assign) IBOutlet NSView *previewView;
@property (assign) IBOutlet NSBox *previewContainer;

@property (nonatomic, readwrite, retain) id <PROAPIAccessing> apiManager;
@property (nonatomic, readwrite, retain) NSObject <ApertureExportManager, PROAPIObject> *exportManager;

@property (nonatomic, readwrite, retain) NSLock *progressLock;
@property (nonatomic, readonly) NSTimeInterval estimatedMovieLength;

// -- Prefs

@property (nonatomic, readwrite) BOOL alsoExportImages;
@property (readwrite, copy) NSNumber *frameRateFieldValue;
@property (readwrite, copy) NSNumber *frameRateFieldModifier;
@property (nonatomic, readwrite, copy) NSString *lastPath;

// --

@property (nonatomic, readwrite, retain) QTMovie *preview;
@property (readwrite, copy) NSString *previewPath;
@property (readwrite, retain) PreviewGenerator *previewGenerator;
@property (readwrite, retain) id <VideoCompressor> videoCompressor;

// --

@property (nonatomic, readonly, retain) NSArray *availableCompressors;

-(void)lockProgress;
-(void)unlockProgress;

-(IBAction)configureCodec:(id)sender;


@end
