//
//  DLCImagePickerController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import "DLCImagePickerController.h"

@implementation DLCImagePickerController {
    NSArray *filters;
    BOOL isStatic;
    BOOL hasBlur;
    BOOL hasOverlay;
    int selectedFilter;
    UIImage *processedImage;
}

@synthesize delegate,
    imageView,
    cameraToggleButton,
    overlayToggleButton,
    photoCaptureButton,
    blurToggleButton,
    cancelButton,
    filtersToggleButton,
    filterScrollView,
    filtersBackgroundImageView,
    photoBar,
    topBar;

-(id) init {
    self = [super initWithNibName:@"DLCImagePicker" bundle:nil];
    
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wantsFullScreenLayout = YES;
    //set background color
    self.view.backgroundColor = [UIColor colorWithPatternImage:
                                 [UIImage imageNamed:@"micro_carbon"]];
    
    self.photoBar.backgroundColor = [UIColor colorWithPatternImage:
                                     [UIImage imageNamed:@"photo_bar"]];
    
    //button states
    [self.blurToggleButton setSelected:NO];
    [self.filtersToggleButton setSelected:NO];
    [self.overlayToggleButton setSelected:NO];
    
    hasBlur = NO;
    hasOverlay = NO;
    
    //fill mode for video
    self.imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    [self loadFilters];
    
    //we need a crop filter for the live video
    cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.75)];
    filter = [[GPUImageRGBFilter alloc] init];
    
    
}

-(void) viewDidAppear:(BOOL)animated{
    //camera setup
    [super viewDidAppear:animated];
    [self setUpCamera];
}

-(void) loadFilters {
    for(int i = 0; i < 10; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(10+i*(60+10), 5.0f, 60, 60);
        [button addTarget:self
                   action:@selector(filterClicked:)
         forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [button setTitle:@"*" forState:UIControlStateSelected];
        if(i == 0){
            [button setSelected:YES];
        }
		[self.filterScrollView addSubview:button];
	}
	[self.filterScrollView setContentSize:CGSizeMake(10 + 10*(60+10), 75.0)];
}


-(void) setUpCamera {
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // Has camera

        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
        
        stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        [stillCamera startCameraCapture];        
    } else {
        // No camera
        NSLog(@"No camera");
    }
    [self prepareFilter];
}

-(void) filterClicked:(UIButton *) sender {
    for(UIView *view in self.filterScrollView.subviews){
        if([view isKindOfClass:[UIButton class]]){
            [(UIButton *)view setSelected:NO];
        }
    }
    
    [sender setSelected:YES];
    [self removeAllTargets];
    
    selectedFilter = sender.tag;
    
    switch (sender.tag) {
        case 1:
            filter = [[GPUImageSepiaFilter alloc] init];
            break;
        case 2:
            filter = [[GPUImageContrastFilter alloc] init];
            [(GPUImageContrastFilter *) filter setContrast:1.75];
            break;
        case 3:
            filter = [[GPUImageToonFilter alloc] init];
            break;
        case 4:
            filter = [[GPUImageVignetteFilter alloc] init];
            [(GPUImageVignetteFilter *) filter setVignetteEnd:0.75f];
            break;
        case 5:
            filter = [[GPUImageGrayscaleFilter alloc] init];
            break;
        case 6:
            filter = [[GPUImageAmatorkaFilter alloc] init];
            break;
        default:
            filter = [[GPUImageRGBFilter alloc] init];
            break;
    }
    
    [self prepareFilter];
}

-(void) prepareFilter {    
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        isStatic = YES;
    }
    
    if (!isStatic) {
        [self prepareLiveFilter];
    } else {
        [self prepareStaticFilter];
    }
}

-(void) prepareLiveFilter {
    
    [stillCamera addTarget:cropFilter];
    [cropFilter addTarget:filter];
    [cropFilter forceProcessingAtSize:CGSizeMake(640, 640)];
    
    //blur is terminal filter
    if (hasBlur && !hasOverlay) {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    //overlay is terminal
    } else if (hasOverlay) {
        //create our mask -- could be filter dependent in future
        sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"mask"]
                                           smoothlyScaleOutput:YES];
        overlayFilter = [[GPUImageMaskFilter alloc] init];
        [sourcePicture processImage];

        if (hasBlur) {
            [filter addTarget:blurFilter];
            [blurFilter addTarget:overlayFilter];
            [sourcePicture addTarget:overlayFilter];
            [overlayFilter addTarget:self.imageView];
        } else {
            [filter addTarget:overlayFilter];
            [sourcePicture addTarget:overlayFilter];
            [overlayFilter addTarget:self.imageView];
        }
   
    //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
}

-(void) prepareStaticFilter {
    
    if (!staticPicture) {
        NSLog(@"Creating new static picture");
        [self.photoCaptureButton setTitle:@"Save" forState:UIControlStateNormal];
        UIImage *inputImage = [UIImage imageNamed:@"sample1.jpg"];
        staticPicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    }
    
    [staticPicture addTarget:filter];
    
    NSLog(@"Has blur %@, has overlay %@", hasBlur?@"YES":@"NO", hasOverlay?@"YES":@"NO");

    // blur is terminal filter
    if (hasBlur && !hasOverlay) {
        NSLog(@"Blur filter: %@", blurFilter);

        GPUImageGaussianSelectiveBlurFilter* gpu =
        (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        NSLog(@"Blur position %g %g %g %g", [gpu blurSize], [gpu excludeBlurSize], [gpu excludeCircleRadius], [gpu aspectRatio]);
        
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
        
        //overlay is terminal
    } else if (hasOverlay) {
        //create our mask -- could be filter dependent in future
        sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"mask"]
                                           smoothlyScaleOutput:YES];
        overlayFilter = [[GPUImageMaskFilter alloc] init];
        [sourcePicture processImage];
        
        if (hasBlur) {
            GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
            
            NSLog(@"Blur position %g %g %g %g", [gpu blurSize], [gpu excludeBlurSize], [gpu excludeCircleRadius], [gpu aspectRatio]);
            [filter addTarget:blurFilter];
            [blurFilter addTarget:overlayFilter];
            [sourcePicture addTarget:overlayFilter];
            [overlayFilter addTarget:self.imageView];
        } else {
            [filter addTarget:overlayFilter];
            [sourcePicture addTarget:overlayFilter];
            [overlayFilter addTarget:self.imageView];
        }
        
        //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
    if (isStatic) {
        [staticPicture processImage];
    }
}

-(void) removeAllTargets {
    [stillCamera removeAllTargets];
    [staticPicture removeAllTargets];
    [cropFilter removeAllTargets];
    
    //regular filter
    [filter removeAllTargets];
    
    //blur
    [blurFilter removeAllTargets];
    
    [sourcePicture removeAllTargets];
    
    //overlay
    [overlayFilter removeAllTargets];
}

-(IBAction) toggleOverlay:(UIButton *) sender {
    [overlayToggleButton setEnabled:NO];   
    [self removeAllTargets];
    
    if (hasOverlay) {
        sourcePicture = nil;
        overlayFilter = nil;
        hasOverlay = NO;
        [overlayToggleButton setSelected:NO];
    } else {
        hasOverlay = YES;
        [overlayToggleButton setSelected:YES];
    }
    
    [self prepareFilter];
    [overlayToggleButton setEnabled:YES];

    if (isStatic) {
        [staticPicture processImage];
    }
}

-(IBAction) toggleBlur:(UIButton*)blurButton {
    
    [self.blurToggleButton setEnabled:NO];
    
    [stillCamera pauseCameraCapture];
    [self removeAllTargets];
    
    if (hasBlur) {
        hasBlur = NO;
        [self.blurToggleButton setSelected:NO];
    } else {
        if (!blurFilter) {
            blurFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCircleRadius:80.0/320.0];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setBlurSize:5.0f];
            [(GPUImageGaussianSelectiveBlurFilter*)blurFilter setAspectRatio:1.0f];
        }
        hasBlur = YES;
        [self.blurToggleButton setSelected:YES];
    }
    
    [self prepareFilter];
    [self.blurToggleButton setEnabled:YES];
    
    if (isStatic) {
        [staticPicture processImage];
    } else {
        [stillCamera resumeCameraCapture];
    }
}

-(IBAction) switchCamera {
    [self.cameraToggleButton setEnabled:NO];
    [stillCamera rotateCamera];
    [self.cameraToggleButton setEnabled:YES];
}

-(IBAction) takePhoto:(id)sender{
    [self.photoCaptureButton setEnabled:NO];
    
    if (!isStatic) {
        [cropFilter prepareForImageCapture];
        [stillCamera capturePhotoAsImageProcessedUpToFilter:cropFilter
                                      withCompletionHandler:^(UIImage *processed, NSError *error) {
            
            isStatic = YES;
            runOnMainQueueWithoutDeadlocking(^{
                [stillCamera stopCameraCapture];
                [self removeAllTargets];
                [self.cameraToggleButton setHidden:YES];
                staticPicture = [[GPUImagePicture alloc] initWithImage:processed smoothlyScaleOutput:YES];
                [self prepareFilter];
                [self.photoCaptureButton setTitle:@"Save" forState:UIControlStateNormal];
                [self.photoCaptureButton setEnabled:YES];
                if(![self.filtersToggleButton isSelected]){
                    [self showFilters];
                }
            });
        }];
        
    } else {
        GPUImageOutput<GPUImageInput> *processUpTo;
        if (hasOverlay) {
            [sourcePicture processImage];
            processUpTo = overlayFilter;
        } else if (hasBlur) {
            processUpTo = blurFilter;
        } else {
            processUpTo = filter;
        }
        //[processUpTo forceProcessingAtSize:CGSizeMake(640.0f, 640.0f)];
        [staticPicture processImage];
        
        UIImage *currentFilteredVideoFrame = [processUpTo imageFromCurrentlyProcessedOutput];
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
                              UIImageJPEGRepresentation(currentFilteredVideoFrame, 1), @"data", nil];
        [self.delegate imagePickerController:self didFinishPickingMediaWithInfo:info];
    }
}

-(IBAction) cancel:(id)sender{
    NSLog(@"Cancel");
    [self.delegate imagePickerControllerDidCancel:self];
}

-(IBAction) handlePan:(UIGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint tapPoint = [sender locationInView:imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            //NSLog(@"Start tap");
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            //NSLog(@"Moving tap");
            [gpu setBlurSize:5.0f];
            [gpu setExcludeCirclePoint:CGPointMake(tapPoint.x/320.0f, tapPoint.y/320.0f)];
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            //NSLog(@"Done tap");
            [gpu setBlurSize:5.0f];
            
            // only render blur at end of gesture
            [self prepareFilter];
        }
    }
}

-(IBAction) handlePinch:(UIPinchGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint midpoint = [sender locationInView:imageView];
        NSLog(@"pinching");
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            //NSLog(@"Start tap");
            if (isStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            [gpu setBlurSize:10.0f];
            [gpu setExcludeCirclePoint:CGPointMake(midpoint.x/320.0f, midpoint.y/320.0f)];
            CGFloat radius = MIN(sender.scale*[gpu excludeCircleRadius], 0.6f);
            [gpu setExcludeCircleRadius:radius];
            sender.scale = 1.0f;
        }
        
        if ([sender state] == UIGestureRecognizerStateEnded) {
            [gpu setBlurSize:5.0f];

            // only render blur at end of gesture
            [self prepareFilter];
        }
    }
}

-(void) showFilters {
    self.filtersToggleButton.enabled = NO;
    [self.filtersToggleButton setSelected:YES];
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.y -= 30;
    CGRect sliderScrollFrame = self.filterScrollView.frame;
    sliderScrollFrame.origin.y -= self.filterScrollView.frame.size.height;
    CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
    sliderScrollFrameBackground.origin.y -=
    self.filtersBackgroundImageView.frame.size.height-3;
    
    self.filterScrollView.hidden = NO;
    self.filtersBackgroundImageView.hidden = NO;
    [UIView animateWithDuration:0.10
                          delay:0.05
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         self.imageView.frame = imageRect;
                         self.filterScrollView.frame = sliderScrollFrame;
                         self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                     } 
                     completion:^(BOOL finished){
                         [self.filtersToggleButton setSelected:YES];
                         self.filtersToggleButton.enabled = YES;
                     }];
}

-(IBAction) toggleFilters:(UIButton *)sender{
    sender.enabled = NO;
    if (sender.selected){
        CGRect imageRect = self.imageView.frame;
        imageRect.origin.y += 30;
        CGRect sliderScrollFrame = self.filterScrollView.frame;
        sliderScrollFrame.origin.y += self.filterScrollView.frame.size.height;
        
        CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
        sliderScrollFrameBackground.origin.y += self.filtersBackgroundImageView.frame.size.height-3;
        
        [UIView animateWithDuration:0.10
                              delay:0.05
                            options: UIViewAnimationCurveEaseOut
                         animations:^{
                             self.imageView.frame = imageRect;
                             self.filterScrollView.frame = sliderScrollFrame;
                             self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                         } 
                         completion:^(BOOL finished){
                             [sender setSelected:NO];
                             sender.enabled = YES;
                             self.filterScrollView.hidden = YES;
                             self.filtersBackgroundImageView.hidden = YES;
                         }];
    } else {
        [self showFilters];
    }
    
}

-(void) dealloc {
    [self removeAllTargets];
    stillCamera = nil;
    cropFilter = nil;
    filter = nil;
    blurFilter = nil;
    staticPicture = nil;
    sourcePicture = nil;
    overlayFilter = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [stillCamera stopCameraCapture];
    [super viewWillDisappear:animated];
}

@end
