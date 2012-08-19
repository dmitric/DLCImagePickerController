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
    
    //camera setup
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
    cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.75)];
    filter = [[GPUImageRGBFilter alloc] init];

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
            filter = [[GPUImageSoftEleganceFilter alloc] init];
            break;
        case 3:
            filter = [[GPUImageAmatorkaFilter alloc] init];
            break;
        case 4:
            filter = [[GPUImageVignetteFilter alloc] init];
            [(GPUImageVignetteFilter *) filter setVignetteEnd:0.75f];
            break;
        case 5:
            filter = [[GPUImageGrayscaleFilter alloc] init];
            break;
        default:
            filter = [[GPUImageRGBFilter alloc] init];
            break;
    }
    [self prepareFilter];
}

-(void) prepareFilter {    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        isStatic = NO;
        [self prepareLiveFilter];
    } else {
        isStatic = YES;
        [self prepareStaticFilter];
    }
}

-(void) prepareLiveFilter {
    
    [stillCamera addTarget:cropFilter];
    [cropFilter addTarget:filter];
    
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
    UIImage *inputImage = [UIImage imageNamed:@"sample1.jpg"];
    
    staticPicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    
    [staticPicture addTarget:cropFilter];
    [cropFilter addTarget:filter];

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
    
    [staticPicture processImage];
    
}

-(void) removeAllTargets {
    [stillCamera removeAllTargets];
    [cropFilter removeAllTargets];
    
    //regular filter
    [filter removeAllTargets];
    
    //blur
    [blurFilter removeAllTargets];
    
    //overlay
    [overlayFilter removeAllTargets];
    [sourcePicture removeAllTargets];
    
    //static
    [staticPicture removeAllTargets];
}

-(IBAction) toggleOverlay:(UIButton *) sender {
    [overlayToggleButton setEnabled:NO];
    [stillCamera pauseCameraCapture];    
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
    [stillCamera resumeCameraCapture];
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
        blurFilter = nil;
        [self.blurToggleButton setSelected:NO];
    } else {
        GPUImageGaussianSelectiveBlurFilter* gaussSelectFilter = 
                [[GPUImageGaussianSelectiveBlurFilter alloc] init];
        [gaussSelectFilter setExcludeCircleRadius:80.0/320.0];
        [gaussSelectFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
        blurFilter = gaussSelectFilter;
        gaussSelectFilter = nil;
        hasBlur = YES;
        [self.blurToggleButton setSelected:YES];
    }
    
    [self prepareFilter];
    [self.blurToggleButton setEnabled:YES];
    
    [stillCamera resumeCameraCapture];
    
    if (isStatic) {
        [staticPicture processImage];
    }
}

-(IBAction) switchCamera {
    [self.cameraToggleButton setEnabled:NO];
    //[stillCamera rotateCamera];
    [self.cameraToggleButton setEnabled:YES];
}

-(IBAction) takePhoto:(id)sender{
    NSLog(@"Taking photo");
    [self.photoCaptureButton setEnabled:NO];
    GPUImageOutput<GPUImageInput> *processUpTo;
    
    if (hasOverlay) {
        [sourcePicture prepareForImageCapture];
        processUpTo = overlayFilter;
    } else if (hasBlur) {
        processUpTo = blurFilter;
    } else {
        processUpTo = filter;
    }
    
    [processUpTo prepareForImageCapture];
    
    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:processUpTo
                                 withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
                              processedJPEG, @"data", nil];
        [self.delegate imagePickerController:self didFinishPickingMediaWithInfo:info];
    }];
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
            [gpu setBlurSize:10.0f];
            [gpu setExcludeCirclePoint:CGPointMake(tapPoint.x/320.0f, tapPoint.y/320.0f)];
            
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            //NSLog(@"Done tap");
            [gpu setBlurSize:2.0f];
        }
        
        if (isStatic) {
            [staticPicture processImage];
        }
    }
}

-(IBAction) handlePinch:(UIPinchGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint midpoint = [sender locationInView:imageView];
        
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            //NSLog(@"Start tap");
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            [gpu setBlurSize:10.0f];
            [gpu setExcludeCirclePoint:CGPointMake(midpoint.x/320.0f, midpoint.y/320.0f)];
            CGFloat radius = MIN(sender.scale*[gpu excludeCircleRadius], 0.6f);
            [gpu setExcludeCircleRadius:radius];
            sender.scale = 1.0f;
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            [gpu setBlurSize:2.0f];
        }

        if (isStatic) {
            [staticPicture processImage];
        }
    }
}

-(IBAction)toggleFilters:(UIButton *)sender{
    sender.enabled = NO;
    [stillCamera pauseCameraCapture];
    if (sender.selected){
        CGRect imageRect = self.imageView.frame;
        imageRect.origin.y += 30;
        CGRect sliderScrollFrame = self.filterScrollView.frame;
        sliderScrollFrame.origin.y += self.filterScrollView.frame.size.height;
        
        CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
        sliderScrollFrameBackground.origin.y += self.filtersBackgroundImageView.frame.size.height-3;
        
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options: UIViewAnimationCurveLinear
                         animations:^{
                             self.imageView.frame = imageRect;
                             self.filterScrollView.frame = sliderScrollFrame;
                             self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                         } 
                         completion:^(BOOL finished){
                             [stillCamera resumeCameraCapture];
                             [sender setSelected:NO];
                             sender.enabled = YES;
                             self.filterScrollView.hidden = YES;
                             self.filtersBackgroundImageView.hidden = YES;
                         }];
    } else {
        [sender setSelected:YES];
        CGRect imageRect = self.imageView.frame;
        imageRect.origin.y -= 30;
        CGRect sliderScrollFrame = self.filterScrollView.frame;
        sliderScrollFrame.origin.y -= self.filterScrollView.frame.size.height;
        CGRect sliderScrollFrameBackground = self.filtersBackgroundImageView.frame;
        sliderScrollFrameBackground.origin.y -=
            self.filtersBackgroundImageView.frame.size.height-3;
        
        self.filterScrollView.hidden = NO;
        self.filtersBackgroundImageView.hidden = NO;
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options: UIViewAnimationCurveLinear
                         animations:^{
                             self.imageView.frame = imageRect;
                             self.filterScrollView.frame = sliderScrollFrame;
                             self.filtersBackgroundImageView.frame = sliderScrollFrameBackground;
                         } 
                         completion:^(BOOL finished){
                             [stillCamera resumeCameraCapture];
                             //NSLog(@"Done!");
                             [sender setSelected:YES];
                             sender.enabled = YES;
                         }];
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
