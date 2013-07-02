#import "GPUImageFilter.h"

extern NSString *const kGrayscaleContrastFragmentShaderString;

/** Converts an image to grayscale (a slightly faster implementation of the saturation filter, without the ability to vary the color contribution)
 */
@interface DLCGrayscaleContrastFilter : GPUImageFilter
{
    GLint intensityUniform;
	GLint slopeUniform;
}

@property(readwrite, nonatomic) CGFloat intensity; 

@end
