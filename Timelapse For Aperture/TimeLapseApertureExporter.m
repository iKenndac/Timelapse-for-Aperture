//
//  TimeLapseApertureExporter.m
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 08/05/2011.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//

#import "TimeLapseApertureExporter.h"
#import "PreviewGenerator.h"
#import "MotionJPEGCompressor.h"
#import <objc/runtime.h>

@interface TimeLapseApertureExporter ()

@property (nonatomic, readwrite, retain) NSArray *availableCompressors;

@end

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
        
        
        // Init compressors!
        
        NSMutableArray *videoCompressors = [NSMutableArray array];
        
        int numClasses;
        Class *classes = NULL;
        numClasses = objc_getClassList(NULL, 0);
        
        if (numClasses > 0) {
            classes = malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            
            for (int currentClassIndex = 0; currentClassIndex < numClasses; currentClassIndex++) {
                
                Class currentClass = classes[currentClassIndex];
                
                if (class_conformsToProtocol(currentClass, @protocol(VideoCompressor))) {
                    
                    NSString *className = NSStringFromClass(currentClass);
                    
                    id compressor = [[currentClass alloc] initWithPropertyListRepresentation:[persistantDomain valueForKey:className]];
                    if (compressor != nil) {
                        [videoCompressors addObject:compressor];
                        [compressor release];
                    }
                }
            }
            
            free(classes);
        }
        
        [videoCompressors sortUsingComparator:(NSComparator)^(id obj1, id obj2){
            return [((id <VideoCompressor>)obj1).name caseInsensitiveCompare:((id <VideoCompressor>)obj2).name];
        }];
         
        self.availableCompressors = [NSArray arrayWithArray:videoCompressors];
        self.videoCompressor = [self.availableCompressors objectAtIndex:0];
        
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
        
        [self addObserver:self
               forKeyPath:@"videoCompressor.userDefaults"
                  options:0
                  context:kTimeLapseUserDefaultsKVOContext];
        
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
        
        NSDictionary *persistantDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:
                                          [[NSBundle bundleForClass:[self class]] bundleIdentifier]];
        
        NSMutableDictionary *mutableDomain = [[persistantDomain mutableCopy] autorelease];
        if (mutableDomain == nil)
            mutableDomain = [NSMutableDictionary dictionary];
        
        [mutableDomain setValue:[NSNumber numberWithBool:self.alsoExportImages] forKey:kAlsoExportFramesUserDefaultsKey];
        [mutableDomain setValue:self.frameRateFieldValue forKey:kFrameFieldValueUserDefaultsKey];
        [mutableDomain setValue:self.frameRateFieldModifier forKey:kFrameFieldModifierUserDefaultsKey];
        [mutableDomain setValue:self.lastPath forKey:kLastPathUserDefaultsKey];
        
        if (self.videoCompressor != nil) {
            [mutableDomain setValue:self.videoCompressor.userDefaults forKey:NSStringFromClass([self.videoCompressor class])];
        }
        
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:mutableDomain
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
@synthesize preview;
@synthesize lastPath;
@synthesize previewPath;
@synthesize previewGenerator;
@synthesize videoCompressor;
@synthesize availableCompressors;

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

-(IBAction)configureCodec:(id)sender {
    [self.videoCompressor showConfigurationInParentWindow:[self.exportManager window]];
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
    NSString *movieName = nil;
    
    @synchronized(exportManager) {
        movieName = [[self.movieNameField stringValue] length] > 0 ? [self.movieNameField stringValue] :
        [[self.exportManager propertiesWithoutThumbnailForImageAtIndex:0] valueForKey:kExportKeyProjectName];
    }
    
    [self.videoCompressor prepareForImagesWithDestinationFolderURL:[NSURL fileURLWithPath:path]
                                                         videoName:movieName];
    
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
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self.videoCompressor appendImageToVideo:[[[NSImage alloc] initWithData:imageData] autorelease]
                            forOneFrameAtFPS:fps];
    
    [pool drain];
    
	// Tell Aperture to write the file out if needed.
	return self.alsoExportImages;
}

-(void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index {
	
}

-(void)exportManagerDidFinishExport {
    
    [self.videoCompressor cleanup];
    self.videoCompressor = nil;
    
    @synchronized(exportManager) {
        [self.exportManager shouldFinishExport];
    }
}

-(void)exportManagerShouldCancelExport {
    
    [self.videoCompressor cleanup];
    [[NSFileManager defaultManager] removeItemAtURL:self.videoCompressor.videoFileURL
                                              error:nil];
    self.videoCompressor = nil;
    
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

-(void)dealloc {
    
    [self removeObserver:self forKeyPath:@"alsoExportImages"];
    [self removeObserver:self forKeyPath:@"frameRateFieldValue"];
    [self removeObserver:self forKeyPath:@"frameRateFieldModifier"];
    [self removeObserver:self forKeyPath:@"lastPath"];
    [self removeObserver:self forKeyPath:@"preview"];
    [self removeObserver:self forKeyPath:@"videoCompressor.userDefaults"];
    
    self.previewGenerator.cancelled = YES;
    self.previewGenerator = nil;
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([self.previewPath length] > 0)
        [[NSFileManager defaultManager] removeItemAtPath:self.previewPath error:nil];
    
    self.previewPath = nil;
    self.preview = nil;
    self.lastPath = nil;
    self.frameRateFieldValue = nil;
    self.frameRateFieldModifier = nil;
    [self.videoCompressor cleanup];
    self.videoCompressor = nil;
    self.apiManager = nil;
    self.exportManager = nil;
    self.progressLock = nil;
    
    [super dealloc];
}

@end
