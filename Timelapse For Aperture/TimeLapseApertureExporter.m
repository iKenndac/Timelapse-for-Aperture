//
//  TimeLapseApertureExporter.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 08/05/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "TimeLapseApertureExporter.h"
#import "PreviewGenerator.h"

static NSString * const kTimeLapseUserDefaultsKVOContext = @"kTimeLapseUserDefaultsKVOContext";

@implementation TimeLapseApertureExporter

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. This is also your only chance to
// obtain a reference to Aperture's export manager. If you
// do not obtain a valid reference, you should return nil.
// Returning nil means that a plug-in chooses not to be accessible.
//---------------------------------------------------------

-(id)initWithAPIManager:(id <PROAPIAccessing>)anApiManager {
	
    if ((self = [super initWithNibName:@"TimeLapseApertureExporter" bundle:[NSBundle bundleForClass:[self class]]])) {
		self.apiManager	= anApiManager;
		self.exportManager = [self.apiManager apiForProtocol:@protocol(ApertureExportManager)];
        
		if (self.exportManager == nil)
			return nil;
		
		self.progressLock = [[[NSLock alloc] init] autorelease];
        
        NSDictionary *persistantDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:
                                          [[NSBundle bundleForClass:[self class]] bundleIdentifier]];
        
        self.alsoExportImages = [[persistantDomain valueForKey:kAlsoExportFramesUserDefaultsKey] boolValue]; 
        self.frameRateFieldValue = [persistantDomain valueForKey:kFrameFieldValueUserDefaultsKey]; 
        self.frameRateFieldModifier = [persistantDomain valueForKey:kFrameFieldModifierUserDefaultsKey]; 
        self.lastPath = [persistantDomain valueForKey:kLastPathUserDefaultsKey];
        
        if (self.frameRateFieldValue == nil)
            self.frameRateFieldValue = [NSNumber numberWithUnsignedInteger:10];
        
        if (self.frameRateFieldModifier == nil)
            self.frameRateFieldModifier = [NSNumber numberWithUnsignedInteger:kFrameRateFramesPerSecondModifier];
        
        if (self.lastPath == nil)
            self.lastPath = @"~/";
        
        [self addObserver:self
               forKeyPath:@"alsoExportImages"
                  options:0
                  context:kTimeLapseUserDefaultsKVOContext];
        
        [self addObserver:self
               forKeyPath:@"frameRateFieldValue"
                  options:0
                  context:kTimeLapseUserDefaultsKVOContext];
        
        [self addObserver:self
               forKeyPath:@"frameRateFieldModifier"
                  options:0
                  context:kTimeLapseUserDefaultsKVOContext];
        
        [self addObserver:self
               forKeyPath:@"lastPath"
                  options:0
                  context:kTimeLapseUserDefaultsKVOContext];
        
        [self addObserver:self
               forKeyPath:@"preview"
                  options:0
                  context:nil];
        
        self.previewGenerator = [[[PreviewGenerator alloc] initWithExporter:self] autorelease];
    }
	
	return self;
}

-(void)awakeFromNib {
    @synchronized(exportManager) {
        [[self.movieNameField cell] setPlaceholderString:[[self.exportManager propertiesWithoutThumbnailForImageAtIndex:0] valueForKey:kExportKeyProjectName]];
    }
    [self.movieNameField setStringValue:[[[self movieNameField] cell] placeholderString]];

    [previewContainer setContentView:self.generatingPreviewView];

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kTimeLapseUserDefaultsKVOContext) {
        
        if ([keyPath isEqualToString:@"frameRateFieldValue"] || [keyPath isEqualToString:@"frameRateFieldModifier"]) {
            self.previewGenerator.cancelled = YES;
            self.preview = nil;
            self.previewGenerator = self.previewGenerator = [[[PreviewGenerator alloc] initWithExporter:self] autorelease];
        }
        
        NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:self.alsoExportImages], kAlsoExportFramesUserDefaultsKey,
                                  self.frameRateFieldValue, kFrameFieldValueUserDefaultsKey,
                                  self.frameRateFieldModifier, kFrameFieldModifierUserDefaultsKey, 
                                  self.lastPath, kLastPathUserDefaultsKey,
                                  nil];
        
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults
                                                           forName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
    } else if ([keyPath isEqualToString:@"preview"]) {
        self.previewGenerator = nil;
        [self.previewContainer setContentView:self.preview == nil ? self.generatingPreviewView : self.previewView];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize firstView;
@synthesize lastView;
@synthesize movieNameField;
@synthesize generatingPreviewView;
@synthesize previewView;
@synthesize previewContainer;
@synthesize apiManager;
@synthesize exportManager;
@synthesize progressLock;
@synthesize alsoExportImages;
@synthesize frameRateFieldValue;
@synthesize frameRateFieldModifier;
@synthesize movie;
@synthesize preview;
@synthesize lastPath;
@synthesize previewPath;
@synthesize previewGenerator;

+(NSSet *)keyPathsForValuesAffectingEstimatedMovieLength {
    return [NSSet setWithObjects:@"frameRateFieldValue", @"frameRateFieldModifier", nil];
}

-(NSTimeInterval)estimatedMovieLength {
    
    double frameFieldValue = [self.frameRateFieldValue doubleValue];
    
    @synchronized(exportManager) {
        if ([self.frameRateFieldModifier unsignedIntegerValue] == kFrameRateFramesPerSecondModifier) {
            return ((double)[self.exportManager imageCount]) / frameFieldValue;
        } else {
            return ((double)[self.exportManager imageCount]) * frameFieldValue;
        }
    }
}

#pragma mark -
// UI Methods
#pragma mark UI Methods

-(NSView *)settingsView {
	return self.view;
}

-(void)willBeActivated {
	// Nothing needed here
}

-(void)willBeDeactivated {
	// Nothing needed here
}

#pragma mark
// Aperture UI Controls
#pragma mark Aperture UI Controls

-(BOOL)allowsOnlyPlugInPresets {
	return NO;	
}

-(BOOL)allowsMasterExport {
	return NO;	
}

-(BOOL)allowsVersionExport {
	return YES;	
}

-(BOOL)wantsFileNamingControls {
	return NO;	
}

-(void)exportManagerExportTypeDidChange {
	// No masters so it should never get this call.
}

#pragma mark -
// Save Path Methods
#pragma mark Save/Path Methods

-(BOOL)wantsDestinationPathPrompt {
	return YES;
}

-(NSString *)destinationPath {
	return nil;
}

-(NSString *)defaultDirectory {
    return [self.lastPath stringByExpandingTildeInPath];
}

#pragma mark -
// Export Process Methods
#pragma mark Export Process Methods

-(void)exportManagerShouldBeginExport {
	// Resizer doesn't need to perform any initialization here.
	// As an improvement, it could check to make sure the user entered at least one size
    @synchronized(exportManager) {
        [self.exportManager shouldBeginExport];
    }
}

-(void)exportManagerWillBeginExportToPath:(NSString *)path {
	// Save our export base path to use later.
	self.lastPath = path;
    
    // Make the movie
    NSString *movieFileName = nil;
    
    @synchronized(exportManager) {
        movieFileName = [[self.movieNameField stringValue] length] > 0 ? [self.movieNameField stringValue] :
        [[self.exportManager propertiesWithoutThumbnailForImageAtIndex:0] valueForKey:kExportKeyProjectName];
    }
    
    if (![[movieFileName pathExtension] isEqualToString:@"mov"])
        movieFileName = [movieFileName stringByAppendingPathExtension:@"mov"];
    
    NSString *movieFilePath = [self.lastPath stringByAppendingPathComponent:movieFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:movieFilePath])
        [[NSFileManager defaultManager] removeItemAtPath:movieFilePath error:nil];
    
    self.movie = [[[QTMovie alloc] initToWritableFile:movieFilePath
                                                error:nil] autorelease];
    
	// Update the progress structure to say Beginning Export... with an indeterminate progress bar.
	[self lockProgress];
	exportProgress.totalValue = [self.exportManager imageCount];
	exportProgress.indeterminateProgress = YES;
	exportProgress.message = [@"Beginning Export..." retain];
	[self unlockProgress];
}

-(BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index {
	// Resizer always exports all of the selected images.
	return YES;
}

-(void)exportManagerWillExportImageAtIndex:(unsigned)index {
	// Nothing to confirm here.
}

-(BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index {
    // Update the progress
	[self lockProgress];
	[exportProgress.message release];
	exportProgress.message = [@"Exporting..." retain];
	exportProgress.currentValue = index + 1;
	[self unlockProgress];
    
    double fps = 0;
    double frameFieldValue = [self.frameRateFieldValue doubleValue];
    
    if ([self.frameRateFieldModifier unsignedIntegerValue] == kFrameRateFramesPerSecondModifier) {
        fps = frameFieldValue;
    } else {
        fps = 1.0 / frameFieldValue;
    }
    
    /* TODO
     
     Make sure we tell QT if we're not adding JPG files.
     
     */
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    QTTime oneFrame = QTMakeTime(1000, (long)(fps * 1000));
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"jpeg", QTAddImageCodecType,
                                [NSNumber numberWithLong:codecHighQuality], QTAddImageCodecQuality,
                                [NSNumber numberWithLong:1000], QTTrackTimeScaleAttribute, nil];
    
    [self.movie addImage:[[[NSImage alloc] initWithData:imageData] autorelease] 
             forDuration:oneFrame
          withAttributes:attributes];
	
    [pool drain];
    
	// Tell Aperture to write the file out if needed.
	return self.alsoExportImages;
}

-(void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index {
	
}

-(void)exportManagerDidFinishExport {
    
    if ([self.movie canUpdateMovieFile])
        [self.movie updateMovieFile];
    
    self.movie = nil;
    
    @synchronized(exportManager) {
        [self.exportManager shouldFinishExport];
    }
}

-(void)exportManagerShouldCancelExport {
    
    if ([self.movie canUpdateMovieFile])
        [self.movie updateMovieFile];
    
    [[NSFileManager defaultManager] removeItemAtPath:[[self.lastPath stringByAppendingPathComponent:[self.movieNameField stringValue]] 
                                                      stringByAppendingPathExtension:@"mov"] 
                                               error:nil];
    
    self.movie = nil;
    
    @synchronized(exportManager) {
        [self.exportManager shouldCancelExport];
    }
}

#pragma mark -
// Progress Methods
#pragma mark Progress Methods

-(ApertureExportProgress *)progress {
	return &exportProgress;
}

-(void)lockProgress {
	[self.progressLock lock];
}

-(void)unlockProgress {
	[self.progressLock unlock];
}

- (IBAction)configureCodec:(id)sender {
}

-(void)dealloc {
    
    [self removeObserver:self forKeyPath:@"alsoExportImages"];
    [self removeObserver:self forKeyPath:@"frameRateFieldValue"];
    [self removeObserver:self forKeyPath:@"frameRateFieldModifier"];
    [self removeObserver:self forKeyPath:@"lastPath"];
    [self removeObserver:self forKeyPath:@"preview"];
    
    self.previewGenerator.cancelled = YES;
    self.previewGenerator = nil;
    
    if ([self.previewPath length] > 0)
        [[NSFileManager defaultManager] removeItemAtPath:self.previewPath error:nil];
    
    self.previewPath = nil;
    self.preview = nil;
    self.lastPath = nil;
    self.frameRateFieldValue = nil;
    self.frameRateFieldModifier = nil;
    self.movie = nil;
    self.apiManager = nil;
    self.exportManager = nil;
    self.progressLock = nil;
    
    [super dealloc];
}

@end
