//
//  DLCImagePickerController.m
//  DLCImagePickerController
//
//  Created by Dmitri Cherniak on 8/14/12.
//  Copyright (c) 2012 Dmitri Cherniak. All rights reserved.
//

#import "DLCImagePickerController.h"
#import "GrayscaleContrastFilter.h"

@implementation DLCImagePickerController {
    NSArray *filters;
    BOOL isStatic;
    BOOL hasBlur;
    int selectedFilter;
}

@synthesize delegate,
    imageView,
    cameraToggleButton,
    photoCaptureButton,
    blurToggleButton,
    flashToggleButton,
    cancelButton,
    retakeButton,
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
    
    self.topBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"photo_bar"]];
    //button states
    [self.blurToggleButton setSelected:NO];
    [self.filtersToggleButton setSelected:NO];
    
    hasBlur = NO;
    
    //fill mode for video
    //self.imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    [self loadFilters];
    
    //we need a crop filter for the live video
    cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0f, 0.0f, 1.0f, 0.75f)];
    filter = [[GPUImageRGBFilter alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self setUpCamera];
    });
    
    
}

-(void) viewDidAppear:(BOOL)animated{
    //camera setup
    [super viewDidAppear:animated];
    
}

-(void) loadFilters {
    for(int i = 0; i < 10; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg", i + 1]] forState:UIControlStateNormal];
        button.frame = CGRectMake(10+i*(60+10), 5.0f, 60.0f, 60.0f);
        button.layer.cornerRadius = 7.0f;
        button.layer.masksToBounds = YES;
        
        UIBezierPath *bi = [UIBezierPath bezierPathWithRoundedRect:button.bounds
                                                 byRoundingCorners:UIRectCornerAllCorners
                                                       cornerRadii:CGSizeMake(7.0,7.0)];
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = button.bounds;
        maskLayer.path = bi.CGPath;
        button.layer.mask = maskLayer;
        button.layer.borderWidth = 1;
        button.layer.borderColor = [[UIColor blackColor] CGColor];
        
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
    [self setFilter:sender.tag];
    [self prepareFilter];
}


-(void) setFilter:(int) index {
    switch (index) {
        case 1:{
            filter = [[GPUImageContrastFilter alloc] init];
            [(GPUImageContrastFilter *) filter setContrast:1.75];
        } break;
        case 2: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"crossprocess.acv"];
        } break;
        case 3: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02.acv"];
        } break;
        case 4: {
            filter = [[GrayscaleContrastFilter alloc] init];
        } break;
        case 5: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17.acv"];
        } break;
        case 6: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua.acv"];
        } break;
        case 7: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"yellow-red.acv"];
        } break;
        case 8: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06.acv"];
        } break;
        case 9: {
            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"purple-green.acv"];
        } break;
        default:
            filter = [[GPUImageRGBFilter alloc] init];
            break;
    }
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
    
    //if([stillCamera cameraPosition] == AVCaptureDevicePositionFront){
    
    [stillCamera addTarget:cropFilter];
    [cropFilter addTarget:filter];
    //blur is terminal filter
    if (hasBlur) {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
    [filter prepareForImageCapture];
    
}

-(void) prepareStaticFilter {
    
    if (!staticPicture) {
        NSLog(@"Creating new static picture");
        [self.photoCaptureButton setTitle:@"Save" forState:UIControlStateNormal];
        UIImage *inputImage = [UIImage imageNamed:@"sample1.jpg"];
        staticPicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    }
    
    [staticPicture addTarget:filter];

    // blur is terminal filter
    if (hasBlur) {
        [filter addTarget:blurFilter];
        [blurFilter addTarget:self.imageView];
    //regular filter is terminal
    } else {
        [filter addTarget:self.imageView];
    }
    
    [staticPicture processImage];
    
        
}

-(void) removeAllTargets {
    [stillCamera removeAllTargets];
    [staticPicture removeAllTargets];
    [cropFilter removeAllTargets];
    
    //regular filter
    [filter removeAllTargets];
    
    //blur
    [blurFilter removeAllTargets];
}

-(IBAction)toggleFlash:(UIButton *)sender{
    [self.flashToggleButton setEnabled:NO];
    [stillCamera.inputCamera lockForConfiguration:nil];
    if([stillCamera.inputCamera flashMode] == AVCaptureFlashModeOff){
        [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeAuto];
        [self.flashToggleButton setImage:[UIImage imageNamed:@"flash-auto"] forState:UIControlStateNormal];
    }else if([stillCamera.inputCamera flashMode] == AVCaptureFlashModeAuto){
        [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
        [self.flashToggleButton setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
    }else{
        [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOff];
        [self.flashToggleButton setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];
    }
    [stillCamera.inputCamera unlockForConfiguration];
    [self.flashToggleButton setEnabled:YES];
    
}

-(IBAction) toggleBlur:(UIButton*)blurButton {
    
    [self.blurToggleButton setEnabled:NO];
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
        [stillCamera capturePhotoAsImageProcessedUpToFilter:cropFilter 
                                      withCompletionHandler:^(UIImage *processed, NSError *error) {
            isStatic = YES;
            runOnMainQueueWithoutDeadlocking(^{
                @autoreleasepool {
                    [stillCamera stopCameraCapture];
                    [self removeAllTargets];
                    [self.retakeButton setHidden:NO];
                    [self.cameraToggleButton setEnabled:NO];
                    [self.flashToggleButton setEnabled:NO];
                    staticPicture = [[GPUImagePicture alloc] initWithImage:processed smoothlyScaleOutput:YES];
                    [self prepareFilter];
                    [self.photoCaptureButton setTitle:@"Done" forState:UIControlStateNormal];
                    [self.photoCaptureButton setImage:nil forState:UIControlStateNormal];
                    [self.photoCaptureButton setEnabled:YES];
                    if(![self.filtersToggleButton isSelected]){
                        [self showFilters];
                    }
                }
            });
        }];
        
    } else {
        GPUImageOutput<GPUImageInput> *processUpTo;
        if (hasBlur) {
            processUpTo = blurFilter;
        } else {
            processUpTo = filter;
        }
        
        [staticPicture processImage];
        
        UIImage *currentFilteredVideoFrame = [processUpTo imageFromCurrentlyProcessedOutput];
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:
                              UIImageJPEGRepresentation(currentFilteredVideoFrame, 1), @"data", nil];
        [self.delegate imagePickerController:self didFinishPickingMediaWithInfo:info];
    }
}

-(IBAction) retakePhoto:(UIButton *)button{
    [self.retakeButton setHidden:YES];
    staticPicture = nil;
    isStatic = NO;
    [self removeAllTargets];
    [stillCamera startCameraCapture];
    [self.cameraToggleButton setEnabled:YES];
    [self.flashToggleButton setEnabled:YES];
    [self.photoCaptureButton setImage:[UIImage imageNamed:@"camera-icon"] forState:UIControlStateNormal];
    [self.photoCaptureButton setTitle:nil forState:UIControlStateNormal];
    
    if ([self.filtersToggleButton isSelected]) {
        [self hideFilters];
    }
    
    cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0f, 0.0f, 1.0f, 0.75f)];
    [self setFilter:selectedFilter];
    [self prepareFilter];
}

-(IBAction) cancel:(id)sender{
    [self.delegate imagePickerControllerDidCancel:self];
}

-(IBAction) handlePan:(UIGestureRecognizer *) sender {
    if (hasBlur) {
        CGPoint tapPoint = [sender locationInView:imageView];
        GPUImageGaussianSelectiveBlurFilter* gpu =
            (GPUImageGaussianSelectiveBlurFilter*)blurFilter;
        
        if ([sender state] == UIGestureRecognizerStateBegan) {
            //NSLog(@"Start tap");
            if (isStatic) {
                [staticPicture processImage];
            }
        }
        
        if ([sender state] == UIGestureRecognizerStateBegan || [sender state] == UIGestureRecognizerStateChanged) {
            //NSLog(@"Moving tap");
            [gpu setBlurSize:5.0f];
            [gpu setExcludeCirclePoint:CGPointMake(tapPoint.x/320.0f, tapPoint.y/320.0f)];
        }
        
        if([sender state] == UIGestureRecognizerStateEnded){
            //NSLog(@"Done tap");
            [gpu setBlurSize:5.0f];
            
            if (isStatic) {
                [staticPicture processImage];
            }
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

            if (isStatic) {
                [staticPicture processImage];
            }
        }
    }
}

-(void) showFilters {
    [self.filtersToggleButton setSelected:YES];
    self.filtersToggleButton.enabled = NO;
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.y -= 34;
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
                         self.filtersToggleButton.enabled = YES;
                     }];
}

-(void) hideFilters {
    [self.filtersToggleButton setSelected:NO];
    CGRect imageRect = self.imageView.frame;
    imageRect.origin.y += 34;
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
                         
                         self.filtersToggleButton.enabled = YES;
                         self.filterScrollView.hidden = YES;
                         self.filtersBackgroundImageView.hidden = YES;
                     }];
}

-(IBAction) toggleFilters:(UIButton *)sender{
    sender.enabled = NO;
    if (sender.selected){
        [self hideFilters];
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [stillCamera stopCameraCapture];
    [super viewWillDisappear:animated];
}

@end
