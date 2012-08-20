#import "GrayscaleContrastFilter.h"

@implementation GrayscaleContrastFilter

NSString *const kGrayscaleContrastFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 uniform lowp float intensity;
 
 const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     float luminance = dot(texture2D(inputImageTexture, textureCoordinate).rgb, W);

     lowp vec4 desat = vec4(vec3(luminance), 1.0);
     
     // scale pixel value away from 0.5 by a factor of intensity
     lowp vec4 outputColor = vec4(
                                  (desat.r < 0.5 ? (0.5 - intensity * (0.5 - desat.r)) : (0.5 + intensity * (desat.r - 0.5))),
                                  (desat.g < 0.5 ? (0.5 - intensity * (0.5 - desat.g)) : (0.5 + intensity * (desat.g - 0.5))),
                                  (desat.b < 0.5 ? (0.5 - intensity * (0.5 - desat.b)) : (0.5 + intensity * (desat.b - 0.5))),
                                  1.0
                                  );
     
     gl_FragColor = outputColor;
 }
 );

#pragma mark -
#pragma mark Initialization and teardown

@synthesize intensity = _intensity;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGrayscaleContrastFragmentShaderString]))
    {
		return nil;
    }
    
    intensityUniform = [filterProgram uniformIndex:@"intensity"];
	
    self.intensity = 1.5;
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setIntensity:(CGFloat)newValue;
{
    _intensity = newValue;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
}

@end