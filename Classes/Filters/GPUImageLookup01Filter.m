//
//  GPUImageLookup01Filter.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/19/12.
//  Copyright (c) 2012 Backspaces Inc. All rights reserved.
//

#import "GPUImageLookup01Filter.h"
#import "GPUImagePicture.h"
#import "GPUImageLookupFilter.h"

@implementation GPUImageLookup01Filter

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }
    
    UIImage *image = [UIImage imageNamed:@"lookup_01.png"];
    NSAssert(image, @"To use GPUImageAmatorkaFilter you need to add lookup_amatorka.png from GPUImage/framework/Resources to your application bundle.");
    
    lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
    
    [lookupImageSource addTarget:lookupFilter atTextureLocation:1];
    [lookupImageSource processImage];
    
    self.initialFilters = [NSArray arrayWithObjects:lookupFilter, nil];
    self.terminalFilter = lookupFilter;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

@end
