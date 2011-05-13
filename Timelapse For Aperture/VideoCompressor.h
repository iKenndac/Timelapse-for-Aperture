//
//  VideoCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/ or send 
//  a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//

#import <Foundation/Foundation.h>

@protocol VideoCompressor <NSObject>

-(id)initWithPropertyListRepresentation:(NSDictionary *)plist;

-(void)prepareForImagesWithDestinationFolderURL:(NSURL *)destination videoName:(NSString *)name;
-(void)appendImageToVideo:(NSImage *)anImage forOneFrameAtFPS:(double)fps;
-(void)cleanup;

@property (nonatomic, readwrite, copy) NSURL *videoFileURL;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BOOL canBeConfigured;
@property (nonatomic, readonly) NSDictionary *userDefaults;

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow;

@end

@interface VideoCompressorUtilities : NSObject {
}

+(NSURL *)fileURLWithUniqueNameForFile:(NSString *)fileName inParentDirectory:(NSURL *)parent;

@end