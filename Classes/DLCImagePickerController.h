//
//  DLCImagePickerController.h
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@class DLCImagePickerController;

@protocol DLCImagePickerDelegate <NSObject>
@optional
- (void)imagePickerController:(DLCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(DLCImagePickerController *)picker;
@end

@interface DLCImagePickerController : UIViewController {
    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageOutput<GPUImageInput> *blurFilter;
    GPUImageCropFilter *cropFilter;
    GPUImageOutput<GPUImageInput> *overlayFilter;
    GPUImagePicture *sourcePicture;
}

@property (nonatomic, weak) IBOutlet GPUImageView *imageView;
@property (nonatomic, weak) id <DLCImagePickerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIButton *photoCaptureButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, weak) IBOutlet UIButton *overlayToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *blurToggleButton;
@property (nonatomic, weak) IBOutlet UIButton *filtersToggleButton;

@property (nonatomic, weak) IBOutlet UIScrollView *filterScrollView;
@property (nonatomic, weak) IBOutlet UIImageView *filtersBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIView *photoBar;
@property (nonatomic, weak) IBOutlet UIView *topBar;

-(IBAction)takePhoto:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)toggleFilters:(UIButton *)sender;

@end
