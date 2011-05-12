//
//  VideoCompressor.h
//  Timelapse For Aperture
//
//  Created by Daniel Kennett on 5/12/11.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol VideoCompressor <NSObject>

-(id)initWithPropertyListRepresentation:(NSDictionary *)plist;

-(void)prepareForImagesWithDestinationFolderURL:(NSURL *)destination videoName:(NSString *)name;
-(void)appendImageToVideo:(NSImage *)anImage forOneFrameOfDuration:(NSTimeInterval)frameDuration;
-(void)cleanup;

@property (nonatomic, readwrite, copy) NSURL *videoFileURL;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BOOL canBeConfigured;

-(void)showConfigurationInParentWindow:(NSWindow *)parentWindow;

@end
