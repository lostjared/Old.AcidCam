//
//  AppController.m
//  Camera
//
//  Created by Jared Bruni on 5/24/11.
//  Copyright 2011 LostSideDead. All rights reserved.
//

#import "AppController.h"
#include<time.h>
#include<OpenGL/glu.h>
#include<math.h>
#include<QuartzCore/QuartzCore.h>
#define GetPixel(xbuffer, x, y, w, color) color.color = xbuffer[x+(y*w)]; 

@implementation capView
@end

@implementation GLView
@synthesize rep_image;
@synthesize sound_object;
@synthesize render_ok;
@synthesize recording;
@synthesize entered;
@synthesize fps;

- (void) awakeFromNib {
	brep = nil;
	irep = nil;
	current_operation = 0;
	img_w = img_h = 0;
	render_ok = NO;
	image_data = 0;
	pass2_alpha = 0.0f;
	trans_var = translation_variable = 0.1f;
	src_buffer = [[AFBuffer alloc] init];
	buffer_set = NO;
	resize_buffer = YES;
	srand((unsigned int)time(0));
    bmp_img = nil;
    timage = nil;
    movie = nil;
    fps = 5;    
    filter_on = YES;
    isNeg = NO;
    counter_var = 0;
}

- (void) dealloc {
 	free(temp_buffer);
	free(orig_buffer);
    
    if(image_data != 0) free(image_data);
	[irep release];
	[brep release];
	[src_buffer release];
    if(bmp_img != nil) 
        [bmp_img release];
    
	[super dealloc];
}

- (void) setNegative: (BOOL) value {
    isNeg = value;
}

- (void) prepare {
	NSOpenGLContext *con = [self openGLContext];
	[con makeCurrentContext];
	glClearDepth(1.0f);
	glClearColor(0, 0, 0, 0);
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
}

- (void) reshape {
    entered = YES;
    if(resize_buffer == YES) {
		[src_buffer initBuffer: [self frame].size.width H: [self frame].size.height];
		resize_buffer = NO;
	}
	glViewport(0, 0, [self frame].size.width, [self frame].size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0, [self frame].size.width, 0, [self frame].size.height);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    [[self openGLContext] flushBuffer];
    entered = NO;
}


- (void) drawRect: (NSRect) r {
	glClearColor(0, 0, 0, 0);
 	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glRasterPos2f(0, [self bounds].size.height);
	GLfloat width=[self frame].size.width/width_;
	GLfloat height=[self frame].size.height/height_;
    glPixelZoom(width, -height);
    [self drawThread:self];
    entered = NO;
}

- (void) toggle_filters: (BOOL) yesno {
    filter_on = yesno;
}

- (void) drawData: (int) current_operationx {
    switch(current_operationx) {
        case 0:
            [self testBlend];
            break;
        case 1:
            [self triBlend];
            break;
        case 2:
            [self triBlendParadox];
            break;
        case 3:
            [self triBlendDouble];
            break;
        case 4:
            [self triBlendMD];
            break;
        case 5:
            [self randTriBlend];
            break;
        case 6:
            [self twoBlend];
            break;
        case 7:
            [self triBlend2];
            break;
        case 8:
            [self blend4];
            break;
        case 9:
            [self blend5];
            break;
        case 10:
            [self tryptamine];
            break;
        case 11:
            [self haze];
            break;
        case 12:
            [self blendWithImage];
            break;
        case 13:
            [self triBlendWithImage];
            break;
        case 14:
            [self doubleBlend];
            break;
        case 15:
            [self negative];
            break;
        case 16:
            [self negative_paradox];
            break;
        case 17:
            [self blank_filter];
            break;
        case 18:
            [self thought_filter];
            break;
        case 19:
            [self idea_max];
            break;
        case 20:
            [self idea_max_rev];
            break;
        case 21:
            [self strobe_effect];
            break;
        case 22:
            [self testEffect];
            break;
        case 23:
            [self LostEffect];
            break;
        case 24:
            [self thoughtMode];
            break;
        case 25:
            [self blendWithImage2];
            break;
        case 26:
            [self blendWithImage3];
            break;
            
    }
}

- (void) drawThread: (id) obj {
    if(filter_on == YES) {
        render_ok = NO;
        if(current_operation == FilterCount) {
            for(int i = 0; i < [table_row_data count]; ++i) {
                NSNumber *num= [table_row_data objectAtIndex:i];
                [self drawData: [num integerValue]];
            }
            
        } else [self drawData:current_operation];
        
        [self displayBuffer];
        render_ok = YES;
    } else {
        [self displayBuffer];
    }
}

- (id) initWithCoder: (NSCoder *)coder {
	self = [super initWithCoder: coder];
	[self prepare];
	return self;
}

- (BOOL) acceptsFirstResponder { 
	return YES; 
}

- (void) setImage: (NSBitmapImageRep *) nsi {
	if(brep != nil) {
		[brep release];
		brep = [nsi retain];
		width_ = [brep size].width;
		height_ = [brep size].height;
	} else {
		brep = [nsi retain];
		width_ = [brep size].width;
		height_ = [brep size].height;
	}
	if(temp_buffer == 0) {
		temp_buffer = malloc(width_ * height_ * 4);		
		orig_buffer = malloc(width_ * height_ * 4);
	}
	[self copyBuffer];
	[self setNeedsDisplay:YES];
}

- (void) setOperationType:(int)num {
	current_operation = num;
}


#define getPixel(buf, w, i, z, col) col.color = buf[i+z*w];
/*
 void getPixel(unsigned int *buf, int w, int i, int z, union Color *col) {
 col->color = buf[i+z*w];
 }*/

- (void) tBlend {
	static float alpha = 1.0f;
	unsigned int *buf = (unsigned int*)temp_buffer;
	for(int z = 0; z < height_; ++z) {
		for(int i = 0; i < width_; ++i) {
			union Color col;
			col.color = buf[i+z*width_];
			int r = arc4random()%3;
			col.colors[0] += alpha*col.colors[r];
			col.colors[1] += alpha*col.colors[r];
			alpha += 0.01f;
			buf[i+z*width_] = (isNeg == YES) ? -col.color : col.color;
		}
	}
}

- (void) testBlend {
	unsigned int *buf = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buf == 0) return;
	for(int z = 0; z < height_; ++z) {
		for(int i = 0; i < width_; ++i) {
			union Color col;
			size_t pos = i+z*width_;
			col.color = buf[pos];
			col.colors[0] += alpha * col.colors[0];
			col.colors[1] += alpha * col.colors[1];
			col.colors[2] += alpha * col.colors[2];
			buf[pos] = (isNeg == YES) ? -col.color : col.color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}

- (void) blend3 {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int *)temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0;
    union Color colors[5];
	static int i=0,z=0;
	for(z = 0; z < height_-4; ++z) {
		for(i = 0; i < width_-4; ++i) {
			getPixel(buffer,width_,i,z,colors[0]);
			getPixel(buffer,width_,i+1,z,colors[1]);
			getPixel(buffer,width_,i,z+1,colors[2]);
			getPixel(buffer,width_,i+1,z+1,colors[3]);
			colors[0].colors[0] = colors[1].colors[0] * alpha;
			colors[0].colors[1] = colors[1].colors[1] + colors[2].colors[1] * alpha;
			colors[0].colors[2] = colors[1].colors[2] + colors[2].colors[2] + colors[3].colors[2] * alpha;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;		
		}
	}
	alpha += translation_variable;
}

- (void) blend4 {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	static int i=0,z=0;
    union Color colors[5];
	for(z = 0; z < height_-2; ++z) {
		for(i = 0; i < width_-2; ++i) {
			getPixel(buffer,width_,i,z,colors[0]);
			getPixel(buffer,width_,i+1,z+1,colors[1]);
			getPixel(buffer,width_,i+1,z,colors[2]);
			static int which = 0;
			for(int q = 0; q < 4; ++q) {
				colors[0].colors[q] += (colors[which].colors[q]%(i+1)) * (1-alpha);				
			}
			which ++;
			if(which >= 3) which = 0;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;			
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}

- (void) blend5 {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int *)temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0,z=0;
    union Color colors[5];
	for(z = 0; z < height_-4; ++z) {
		for(i = 0; i < width_-4; ++i) {
			getPixel(buffer,width_,i,z,colors[0]);
			int total = colors[0].colors[0]+colors[0].colors[1]+colors[0].colors[2];
			total /= 3;
			colors[0].colors[1] += (total) + colors[0].colors[1] * alpha;
			colors[0].colors[2] += (total) + colors[0].colors[0] * alpha;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;			
		}
	}
	static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}


- (void) triBlend {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*)temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
    union Color colors[5];
	static int i=0,z=0;
	for(z = 0; z < height_-2; ++z) {
		for(i = 0; i < width_-2; ++i) {
			getPixel(buffer,width_,i, z, colors[0]);
			getPixel(buffer,width_,i+1, z, colors[1]);
			getPixel(buffer,width_,i, z+1, colors[2]);
			colors[3].colors[0] = colors[0].colors[0]*alpha;
			colors[3].colors[1] = colors[0].colors[1]+colors[1].colors[1]*alpha;
			colors[3].colors[2] = colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2]*alpha;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}

- (void) triBlendParadox {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
			getPixel(buffer, width_, i+1, z, colors[1]);
			getPixel(buffer, width_, i, z+1, colors[2]);
			colors[3].colors[0] = colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0] * alpha;
			colors[3].colors[1] = colors[0].colors[1]+colors[1].colors[1] * alpha;
			colors[3].colors[2] = colors[0].colors[2] * alpha;
			colors[3].colors[3] = 0;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
    /*
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;*/
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) triBlendDouble {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
	int counter = 0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
			getPixel(buffer, width_, i+1, z, colors[1]);
			getPixel(buffer, width_, i, z+1, colors[2]);
			if(counter == 0) {
				colors[3].colors[0] = colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0] * alpha;
				colors[3].colors[1] = colors[0].colors[1]+colors[1].colors[1] * alpha;
				colors[3].colors[2] = colors[0].colors[2] * alpha;
				colors[3].colors[3] = 0;
				counter++;
			} else {
				colors[3].colors[0] = colors[0].colors[0]*alpha;
				colors[3].colors[1] = colors[0].colors[1]+colors[1].colors[1]*alpha;
				colors[3].colors[2] = colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2]*alpha;				
				counter = 0;
			}
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}


- (void) triBlendMD {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
	int counter = 0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
			getPixel(buffer, width_, i+1, z, colors[1]);
			getPixel(buffer, width_, i, z+1, colors[2]);
			if(counter == 0) {
				colors[3].colors[0] = (colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0]) * alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1]) * alpha;
				colors[3].colors[2] = (colors[0].colors[2]) * alpha;
				colors[3].colors[3] = 0;
				counter++;
			} else if(counter == 1) {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[2] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;				
				counter++;
			}
			else {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[2] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[1] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;				
				counter = 0;
			}
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}

- (void) randTriBlend {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
	int counter = 0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
			getPixel(buffer, width_, i+1, z, colors[1]);
			getPixel(buffer, width_, i+2, z, colors[2]);
			// choas
			counter = arc4random()%3;
			if(counter == 0) {
				colors[3].colors[0] = (colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0]) * alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1]) * alpha;
				colors[3].colors[2] = (colors[0].colors[2]) * alpha;
				colors[3].colors[3] = 0;
				counter++;
			} else if(counter == 1) {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[2] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;				
				counter++;
			}
			else {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[2] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[1] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;				
			}
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) triBlend2 {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
			getPixel(buffer, width_, i+1, z, colors[1]);
			getPixel(buffer, width_, i, z+1, colors[2]);
			colors[3].colors[0] = (1-alpha) * colors[1].colors[0];
			colors[3].colors[1] += ((1-alpha) * colors[1].colors[1]+colors[2].colors[1]);
			colors[3].colors[2] = ((1-alpha) * colors[2].colors[2]);
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}

// Enable second pass 25 or 50%.

- (void) twoBlend {
	if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
	int counter = 0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[arc4random()%3]);
			getPixel(buffer, width_, i+1, z, colors[arc4random()%3]);
			getPixel(buffer, width_, i, z+1, colors[arc4random()%3]);
			colors[3].colors[3] = 0;
			if(counter == 0) {
				colors[3].colors[0] = (colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0]) * alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1]) * alpha;
				colors[3].colors[2] = (colors[0].colors[2]) * alpha;
				counter = 1;
			} else if(counter == 1) {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[1] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[2] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;
				counter = 2;
			}
			else {
				colors[3].colors[0] = (colors[0].colors[0])*alpha;
				colors[3].colors[2] = (colors[0].colors[1]+colors[1].colors[1])*alpha;
				colors[3].colors[1] = (colors[0].colors[2]+colors[1].colors[2]+colors[2].colors[2])*alpha;				
				counter = 0;
			}
			colors[3].colors[0] = ((1+colors[3].colors[0]) / 4)*alpha;
			colors[3].colors[1] = ((1+colors[3].colors[1]) / 3)*alpha;
			colors[3].colors[2] = ((1+colors[3].colors[2]) / 2)*alpha;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[3].color : colors[3].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
}


#define CMX_GetFW(old_w, x, new_w) (x*old_w/ new_w)
#define CMX_GetFH(old_h, y, new_h) (y*old_h/ new_h)

- (void) blendWithImage {
	static float alpha = 1.0f;
	unsigned int *buffer = (unsigned int *)temp_buffer;
	static unsigned int which = 0;
	for(int z = 0; z < height_-1; ++z) {
		for(int i = 0; i < width_-1; ++i) {
			int pos_x = CMX_GetFW(img_w, i, width_);
			int pos_y = CMX_GetFH(img_h, z, height_);
			if(pos_x < 0 || pos_x > img_w-1 || pos_y < 0 || pos_y > img_h-1) continue;
			union Color colors[3];
			unsigned int *buffer_data = (unsigned int*)image_data;
			switch(which) {
				case 0:
					colors[0].color = buffer_data[pos_x+pos_y*img_w];
					colors[1].color = buffer[i+z*width_];
					break;
				case 1:
					colors[1].color = buffer_data[pos_x+pos_y*img_w];
					colors[0].color = buffer[i+z*width_];
					break;
			}
			colors[0].colors[0] += colors[1].colors[0] * alpha;
			colors[0].colors[1] += colors[1].colors[1] * alpha;
			colors[0].colors[2] += colors[1].colors[2] * alpha;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
		}
	}
	if(which >= 2) which = 0;
	static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) doubleBlend {
	static float alpha = 1.0f;
	unsigned int *buffer = (unsigned int *)temp_buffer;
	for(int z = 0; z < height_-1; ++z) {
		for(int i = 0; i < width_-1; ++i) {
			int pos_x = CMX_GetFW(img_w, i, width_);
			int pos_y = CMX_GetFH(img_h, z, height_);
			if(pos_x < 0 || pos_x > img_w-1 || pos_y < 0 || pos_y > img_h-1) continue;
			union Color colors[6];
			unsigned int *buffer_data = (unsigned int*)image_data;
			GetPixel(buffer, i, z, width_, colors[1]);
            colors[0].color = buffer_data[pos_x+pos_y*img_w];
            colors[0].colors[0] += 1-alpha*colors[1].colors[0];
            colors[0].colors[1] = 1-alpha*colors[1].colors[1];
            colors[0].colors[2] -= 1-alpha*colors[1].colors[2];            
            buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
		}
	}
	static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) triBlendWithImage {
	unsigned int *buffer = (unsigned int *)temp_buffer;
    unsigned int *buffer_data = (unsigned int*)image_data;
    if(buffer == 0 || buffer_data == 0) return;
    [self blendWithImage];
    [self triBlend];
}

- (void) haze {
    if(temp_buffer == 0) return;
	unsigned int *buffer = (unsigned int*) temp_buffer;
	if(buffer == 0) return;
	static float alpha = 1.0f;
	static int i=0, z=0;
    union Color colors[5];
	for(z=2; z < height_-2; ++z) {
		for(i=2; i < width_-2; ++i) {
			getPixel(buffer, width_, i,z, colors[0]);
            colors[0].colors[0] += (1-alpha)*colors[0].colors[1];
            colors[0].colors[1] += (1-alpha)*colors[0].colors[2];
            colors[0].colors[2] += (1-alpha)*colors[0].colors[0];
            buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
		}
	}
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	alpha += trans_var;
} 

- (void) negative_paradox {
    
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    
        
        for(int z = 0; z < height_-2; ++z) {
            for(int i = 0; i < width_-3; ++i) {
                union Color colorz[6];
                if(z > (height_-2)) continue;
                size_t pos = i+z*width_;
                getPixel(buffer,width_, i, z, colorz[0]);
                getPixel(buffer,width_, i+1,z, colorz[1]);
                getPixel(buffer,width_, i+2,z, colorz[2]);
                getPixel(buffer,width_, i+3,z,colorz[3]);
                colorz[0].colors[0] += colorz[1].colors[0]*alpha + (colorz[1].colors[0]*alpha);
                colorz[0].colors[1] += colorz[2].colors[1]*alpha + (colorz[2].colors[1]*alpha);
                colorz[0].colors[2] += colorz[0].colors[2]*alpha + (colorz[0].colors[2]*alpha);
                buffer[pos] = (isNeg == YES) ? -colorz[0].color: colorz[0].color;
            }
        }
    
    if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	
	alpha += trans_var;
    
    
    /*
    
    dispatch_queue_t qt = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_sync(qt, ^{
        for(int cnt=0; cnt < 3; ++cnt) {
            dispatch_async(qt, ^{
                procFunc(0,((height_)/3)*cnt, buffer, alpha);
                counter_var ++;
            });
        }
        while(counter_var < 2) {}
        [self displayBuffer];
        counter_var = 0;
    });
     
     */
}

- (void) negative {
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    
    
	for(int z = 0; z < height_-2; ++z) {
		for(int i = 0; i < width_-3; ++i) {
            union Color colorz[6];
            if(z > (height_-2)) continue;
			size_t pos = i+z*width_;
            getPixel(buffer,width_, i, z, colorz[0]);
            getPixel(buffer,width_, i+1,z, colorz[1]);
            getPixel(buffer,width_, i+2,z, colorz[2]);
            getPixel(buffer,width_, i+3,z,colorz[3]);
			colorz[0].colors[0] += colorz[2].colors[2]*alpha + (colorz[1].colors[0]*alpha);
			colorz[0].colors[1] += colorz[1].colors[1]*alpha + (colorz[2].colors[1]*alpha);
			colorz[0].colors[2] += colorz[0].colors[0]*alpha + (colorz[0].colors[2]*alpha);
			buffer[pos] = (isNeg == YES) ? -colorz[0].color: colorz[0].color;
		}
	}
	
    if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > 15)
		trans_var = -translation_variable;
	
    alpha += trans_var;
    /*
     
    dispatch_queue_t qt = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    dispatch_sync(qt, ^{
        for(int cnt=0; cnt < 3; ++cnt) {
            dispatch_async(qt, ^{
                procFunc(0,((height_)/3)*cnt, buffer, alpha);
                counter_var ++;
            });
        }
        while(counter_var < 2) {}
        [self displayBuffer];
        counter_var = 0;
    }); */
    
}

- (void) blank_filter { 
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-3; ++i) {
            union Color colorz[4];
            getPixel(buffer,width_,i, z, colorz[0]);
            int total = colorz[0].colors[0] +colorz[0].colors[1]+colorz[0].colors[2];
            total += total*alpha;
            total = total%255;
            colorz[0].colors[0] = (unsigned char)total;
            colorz[0].colors[1] = (unsigned char)-total;
            buffer[i+z*width_] = (isNeg == YES) ? -colorz[0].color: colorz[0].color;
        }
    }
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;    
}

- (void) thought_filter { 
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-3; ++i) {
            union Color colorz[4];
            getPixel(buffer,width_,i, z, colorz[0]);
            int total_r = colorz[0].colors[0] +colorz[0].colors[1]+colorz[0].colors[2];
            total_r /= 3;
            total_r *= alpha;
            getPixel(buffer,width_,i+1,z,colorz[1]);
            int total_g = colorz[1].colors[0]+colorz[1].colors[1]+colorz[1].colors[2];
            total_g /= 3;
            total_g *= alpha;
            colorz[0].colors[0] = (unsigned char)total_r;
            colorz[0].colors[1] = (unsigned char)total_g;
            colorz[0].colors[2] = (unsigned char)total_r+total_g*alpha;
            buffer[i+z*width_] = (isNeg == YES) ? -colorz[0].color: colorz[0].color;
        }
    }
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) four_twenty {
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-3; ++i) {
            union Color colors[5];
            getPixel(buffer,width_,i, z, colors[0]);
            getPixel(buffer,width_,i+1,z,colors[2]);
            getPixel(buffer,width_,i+1,z+1,colors[2]);
            getPixel(buffer,width_,i,z+1,colors[3]);
            
            colors[4].colors[0] += (colors[0].colors[0]+colors[1].colors[0]+colors[2].colors[0]+colors[3].colors[0])+1;
            colors[4].colors[1] += (colors[0].colors[1]+colors[1].colors[1]+colors[2].colors[1]+colors[3].colors[1]+1);
            colors[4].colors[2] = 0xFF;
            //colors[4].colors[2] += (colors[0].colors[2]+colors[1].colors[1]+colors[2].colors[2]+colors[2].colors[2])+1;
            
            if(colors[4].colors[0] > 0) colors[4].colors[0] /= 4;
            if(colors[4].colors[1] > 0) colors[4].colors[1] /= 4;
            if(colors[4].colors[2] > 0) colors[4].colors[2] /= 4;
            
            colors[4].colors[(rand()%3)+1] *= alpha;
            colors[4].colors[1] *= alpha;
            colors[4].colors[2] *= alpha;
            
            buffer[i+z*width_] = (isNeg == YES) ? -colors[4].color: colors[4].color;
        }
    }
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
    
}

- (void) testEffect {
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    static unsigned int color_turn = 0;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-4; ++i) {
            union Color colors[5];
            getPixel(buffer,width_,i, z, colors[4]);
            getPixel(buffer,width_,i+1,z,colors[0]);
            colors[4].colors[0] += (color_turn == 0) ? alpha*colors[0].colors[0] : -(alpha*colors[0].colors[2]);
            colors[4].colors[1] += (color_turn == 1) ? alpha*colors[0].colors[1] : -(alpha*colors[0].colors[1]);
            colors[4].colors[2] += (color_turn == 0) ? alpha*colors[0].colors[2] : -(alpha*colors[0].colors[0]);
            colors[4].colors[3] = 0xFF;
            buffer[i+z*width_] = (isNeg == YES) ? -colors[4].color: colors[4].color;
        }
    }
    color_turn = !color_turn;
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) LostEffect {
    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    static unsigned int color_turn = 0;
    static unsigned int color_offset = 0;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-4; ++i) {
            union Color colors[5];
            getPixel(buffer,width_,i, z, colors[4]);
            getPixel(buffer,width_,i+1,z,colors[0]);
            colors[4].colors[0] = (color_turn == 1) ? alpha*colors[0].colors[0] : -(alpha*colors[0].colors[2]);
            colors[4].colors[1] = (color_turn == 0) ? alpha*colors[0].colors[1] : -(alpha*colors[0].colors[1]);
            colors[4].colors[2] = (color_turn == 1) ? alpha*colors[0].colors[2] : -(alpha*colors[0].colors[0]);
            colors[4].colors[color_offset] = 0xFF;
            buffer[i+z*width_] = (isNeg == YES) ? -colors[4].color: colors[4].color;
        }
    }
    color_turn = !color_turn;
    if(++color_offset > 3) color_offset = 0;
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}


- (void) thoughtMode {

    unsigned int *buffer = (unsigned int *)temp_buffer;
	static float alpha = 1.0f;
	if(buffer == 0) return;
    static int mode = 0;
    static int sw = 1, tr = 1;
    for(int z = 2; z < height_-2; ++z) {
        for(int i = 2; i < width_-4; ++i) {
            union Color colors[2];
            getPixel(buffer, width_,i,z,colors[0]);
            if(sw == 1) colors[0].colors[0] += colors[0].colors[mode]*alpha;
            if(tr == 0) colors[0].colors[mode] -= colors[0].colors[rand()%2]*alpha;
            colors[0].colors[mode] += colors[0].colors[mode]*alpha;
            mode++;
            if(mode >= 3) mode = 0;
            buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color: colors[0].color;
        }
    }
    sw = !sw;
    tr = !tr;
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
}

- (void) blendWithImage2 {
    static float alpha = 1.0f;
	unsigned int *buffer = (unsigned int *)temp_buffer;
    static int yesNo = 0, state = 0, add_value = 0;
	static unsigned int which = 0;
	for(int z = 0; z < height_-1; ++z) {
		for(int i = 0; i < width_-1; ++i) {
			int pos_x = CMX_GetFW(img_w, i, width_);
			int pos_y = CMX_GetFH(img_h, z, height_);
			if(pos_x < 0 || pos_x > img_w-1 || pos_y < 0 || pos_y > img_h-1) continue;
			union Color colors[3];
            if(pos_x > 0) pos_x--;
			unsigned int *buffer_data = (unsigned int*)image_data;
            colors[0].color = buffer_data[pos_x+pos_y*img_w];
            colors[1].color = buffer[i+z*width_];
            colors[0].colors[0] += colors[1].colors[0] * alpha;
			colors[0].colors[1] += colors[1].colors[1] * alpha;
			colors[0].colors[2] += colors[1].colors[2] * alpha;
            if(yesNo == 0) colors[0].colors[state] = add_value;
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
		}
	}
	if(which >= 2) which = 0;
    yesNo = !yesNo;
    ++state;
    if(state >= 3) state = 0;
    
    ++add_value;
    if(add_value > 100) add_value = 0;
    
	static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
    
}
// try out some random stuff
- (void) blendWithImage3 {
    static float alpha = 1.0f;
	unsigned int *buffer = (unsigned int *)temp_buffer;
    static int yesNo = 0, state = 0, add_value = 0, swap_val = 0;
	static unsigned int which = 0;
	for(int z = 0; z < height_-1; ++z) {
		for(int i = 0; i < width_-1; ++i) {
			int pos_x = CMX_GetFW(img_w, i, width_);
			int pos_y = CMX_GetFH(img_h, z, height_);
			if(pos_x < 0 || pos_x > img_w-1 || pos_y < 0 || pos_y > img_h-1) continue;
			union Color colors[6];
            if(pos_x > 0) pos_x--;
			unsigned int *buffer_data = (unsigned int*)image_data;
            colors[0].color = buffer_data[pos_x+pos_y*img_w];
            colors[1].color = buffer[i+z*width_];
            colors[2].color = buffer_data[(pos_x+1)+(pos_y*img_w)];
            colors[3].color = buffer[(i+1)+(z*width_)];
            colors[0].colors[0] += colors[1].colors[0] * alpha;
			colors[0].colors[1] -= colors[2].colors[1] * alpha;
			colors[0].colors[2] += colors[3].colors[2] * alpha;
            if(yesNo == 0) colors[0].colors[state] = add_value;
            if(swap_val == 0) {
                colors[5].color = colors[0].color;
                colors[0].colors[0] = colors[5].colors[2];
                colors[0].colors[1] = colors[5].colors[1];
                colors[0].colors[2] = colors[5].colors[0];
            }
			buffer[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
		}
	}
	if(which >= 2) which = 0;
    yesNo = !yesNo;
    ++state;
    if(state >= 3) state = 0;
    swap_val = !swap_val;
    
    ++add_value;
    if(add_value > 100) add_value = 0;
    
	static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
    
}

- (void) enable_pass2: (float) q {
	pass2_alpha = q;
}

- (void) proc {
	if(irep != nil) 
		[irep release];
	img_w = [rep_image size].width;
	img_h = [rep_image size].height;
	NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithData: [rep_image TIFFRepresentation]];
	irep = image;
	if(image == nil) return;
	if(image_data != 0) {
		free(image_data);
	}
	image_data = (unsigned char*)(malloc(img_w*img_h*4));
	int bpp = [irep bitsPerPixel]/8;
	if(image_data == 0) return;
	unsigned int *ptr = (unsigned int *)image_data;
	unsigned char *temp_pos = (unsigned char *)[irep bitmapData];
	if(temp_pos == 0) {
		NSRunAlertPanel(@"Error", @"Image could not be loaded", @"Ok", nil, nil);
		return;
	}
	for(int z = 0; z < img_h-4; ++z) {
		for(int i = 0; i < img_w-4; ++i) {
			union Color col;
			unsigned char *colorAt = (unsigned char*)temp_pos;
			colorAt += z*[irep bytesPerRow]+(i*bpp);
			col.colors[0] = colorAt[0];
			col.colors[1] = colorAt[1];
			col.colors[2] = colorAt[2];
			ptr[i] = col.color;
		}
		ptr += img_w;
	}
	render_ok = YES;
}

- (void) pass2_blend {
	if(brep == nil) return;
    union Color col[3];
	unsigned int *temp = (unsigned int *)orig_buffer;
	unsigned int *data = (unsigned int *)temp_buffer;
	for(int z = 0; z < [brep size].height; ++z) {
		for(int i = 0; i < [brep size].width; ++i) {
			col[0].color = temp[i];
			col[1].color = data[i];
			col[2].colors[0] = col[0].colors[0]+col[1].colors[0] * pass2_alpha;
			col[2].colors[1] = col[0].colors[1]+col[1].colors[1] * pass2_alpha;
			col[2].colors[2] = col[0].colors[2]+col[1].colors[2] * pass2_alpha;
			data[i] = col[2].color;
		}
		temp += [brep bytesPerRow]/4;
		data += [brep bytesPerRow]/4;
	}
}

#define PI 3.14

- (void) tryptamine {
    if(brep == nil) return;
    union Color colors[6];
    unsigned int *temp = (unsigned int*)temp_buffer;
    static float alpha=1.0f;
    static int total_count = 0;
    for(int z = 0; z < [brep size].height-2; ++z) {
        for(int i = 0; i < [brep size].width-2; ++i) {
			getPixel(temp, width_, i,z, colors[0]);
            colors[0].colors[0] += total_count;
            colors[0].colors[1] += -total_count;
            colors[0].colors[2] += -total_count;
            temp[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
        }
    }
    alpha += trans_var;
    total_count++;
}

- (void) idea_max {
    union Color colors[6];
    unsigned int *temp = (unsigned int*)temp_buffer;
    static float alpha=0.0f;
    for(int z = 0; z < [brep size].height-2; ++z) {
        for(int i = 0; i < [brep size].width-2; ++i) {
			getPixel(temp, width_, i,z, colors[0]);
            getPixel(temp, width_, i+1, z, colors[1]);
            getPixel(temp, width_, i+2, z, colors[2]);
            colors[0].colors[0] += (unsigned char)colors[1].colors[0]*(alpha);
            colors[0].colors[1] += (unsigned char)colors[2].colors[1]*(-alpha);
            colors[0].colors[2] += (unsigned char)colors[0].colors[2]*(alpha);
            temp[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
        }
    }

    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;    
   
}

- (void) idea_max_rev {

    union Color colors[6];
    unsigned int *temp = (unsigned int*)temp_buffer;
    static float alpha=0.0f;
    static bool passT = true;
    
    for(int z = 0; z < [brep size].height-2; ++z) {
        for(int i = 0; i < [brep size].width-2; ++i) {
			getPixel(temp, width_, i,z, colors[0]);
            getPixel(temp, width_, i+1, z, colors[1]);
            getPixel(temp, width_, i+2, z, colors[2]);
            if(passT == true) {
                colors[0].colors[0] += (unsigned char)colors[1].colors[0]*(-alpha);
                colors[0].colors[1] += (unsigned char)colors[2].colors[1]*(alpha);
                colors[0].colors[2] += (unsigned char)colors[0].colors[2]*(-alpha);
            } else {
                colors[0].colors[0] += (unsigned char)colors[1].colors[0]*(alpha);
                colors[0].colors[1] += (unsigned char)colors[2].colors[1]*(-alpha);
                colors[0].colors[2] += (unsigned char)colors[0].colors[2]*(alpha);
            }
            
            temp[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
        }
        
       
    }
    
     if(passT == true) { passT = false; } else { passT = true; }

    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
    
}


// testing
- (void) strobe_effect {
    
    union Color colors[6];
    unsigned int *temp = (unsigned int*)temp_buffer;
    static float alpha=0.0f;
    static unsigned int passIndex = 0;
    
    for(int z = 0; z < [brep size].height-2; ++z) {
        for(int i = 0; i < [brep size].width-2; ++i) {
			
            getPixel(temp, width_, i,z, colors[0]);
            switch(passIndex) {
                case 0:
                    colors[0].colors[0] += colors[0].colors[0]*(-alpha);
                    colors[0].colors[1] += colors[0].colors[1]*alpha;
                    colors[0].colors[2] += colors[0].colors[2]*alpha;
                    break;
                case 1:
                    colors[0].colors[0] += colors[0].colors[0]*alpha;
                    colors[0].colors[1] += colors[0].colors[1]*(-alpha);
                    colors[0].colors[2] += colors[0].colors[2]*alpha;
                    break;
                case 2:
                    colors[0].colors[0] += colors[0].colors[0]*alpha;
                    colors[0].colors[1] += colors[0].colors[1]*alpha;
                    colors[0].colors[2] += colors[0].colors[2]*(-alpha);
                    break;
                case 3:
                {
                    getPixel(temp, width_, i+1, z, colors[1]);
                    getPixel(temp, width_, i+2, z, colors[2]);
                    colors[0].colors[0] += colors[1].colors[0]*alpha;
                    colors[0].colors[1] += colors[2].colors[1]*alpha;
                    colors[0].colors[2] += colors[0].colors[2]*(-alpha);
                }
                    break;
            }
            
            
            temp[i+z*width_] = (isNeg == YES) ? -colors[0].color : colors[0].color;
        }
        
    }
    
    ++passIndex;
    if(passIndex > 3) passIndex = 0;
    
    
    static float max = 4.0f;
	if(alpha < 0)
		trans_var = translation_variable;
	else if(alpha > max) {
		trans_var = -translation_variable;
		max += 3.0f;
		if(max > 23) max = 4.0f;
	}
	alpha += trans_var;
    
}

void copyRepBuffer(void *temp_buffer, NSBitmapImageRep *brep) {
	unsigned char *src = (unsigned char *)[brep bitmapData];
	unsigned char *dst = (unsigned char *)temp_buffer;
	int bpp = [brep bitsPerPixel] / 8;
	for(int h = 0; h < [brep size].height; ++h) 
	{
		for(int w = 0; w < [brep size].width; ++w) {
			unsigned char *pos = (unsigned char *)src;
			pos += (w*bpp)+h*[brep bytesPerRow];
			unsigned char *dst_pos = (unsigned char *)dst;
			int bytesPerRow = [brep size].width*4;
			dst_pos += bytesPerRow*h+(w*4);
			dst_pos[0] = pos[0];
			dst_pos[1] = pos[1];
			dst_pos[2] = pos[2];
			dst_pos[3] = 255;
		}
	}
    
}

- (void) copyBuffer {
	copyRepBuffer(temp_buffer, brep);
	if(pass2_alpha != 0) {
        memcpy(orig_buffer, temp_buffer, [brep size].width*[brep size].height*4);
        
        //copyRepBuffer(orig_buffer, brep);
        
    }
}


- (void) setMovie:(QTMovie *)m {
    movie = m;
}
unsigned char **t = 0;
unsigned char *b;

- (void) displayBuffer {
    if(pass2_alpha != 0)
        [self pass2_blend];
    if(temp_buffer != 0) {
        glDrawPixels(width_, height_, GL_RGBA, GL_UNSIGNED_BYTE,temp_buffer);
        [[self openGLContext] flushBuffer];
    }
    if(saveMe == YES) {
        [self saveImage: saveFile];
        saveMe = NO;
        [saveFile release];
    } else if(recording == YES) {
        NSDictionary *attributesForImage = [NSDictionary dictionaryWithObjectsAndKeys:@"tiff", QTAddImageCodecType,nil];
        NSBitmapImageRep *bmp = [self bmpImage];
        NSImage *img = [[NSImage alloc] initWithCGImage:[bmp CGImage] size:NSMakeSize(width_, height_)];
        if(img == nil) {
            NSLog(@"Image is NIL\n");
        }           
        [movie addImage:img forDuration:QTMakeTime(1, fps) withAttributes:attributesForImage];
        [img release];
        //[bmp release];
        
        free(t);
        free(b);
    }
}

- (void) saveImageSynced: (NSString *)str {
	saveMe = YES;
	saveFile = [str retain];
}

- (NSBitmapImageRep *)bmpImage {
    unsigned char *buffer = (unsigned char*) calloc (1,  width_ * height_ * 4 );
	unsigned int counter = 0;
	unsigned char *ptr = buffer;
	unsigned char *pix = (unsigned char*)temp_buffer;
	while(counter < (width_*height_)) {
		unsigned int *ptr_val = (unsigned int *) pix;
		unsigned char *arr = (unsigned char *)ptr_val;
		ptr[0] = 255;
		ptr[1] = arr[0];
		ptr[2] = arr[1];
		ptr[3] = arr[2];
		pix += 4;
		ptr += 4;
		counter++;
	}
    unsigned char **temp = (unsigned char **) malloc (sizeof (unsigned char *) * height_);
	for(int i = 0; i < height_; ++i) {
		temp[i] = (unsigned char *)&buffer[i*width_*4];
	}
	NSBitmapImageRep *img = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: (unsigned char**)temp pixelsWide: width_ pixelsHigh: height_ bitsPerSample: 8 samplesPerPixel: 4 hasAlpha:YES isPlanar:NO colorSpaceName: NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat bytesPerRow:width_*4 bitsPerPixel:32];
    t = temp;
    b = buffer;
    return [img autorelease];  
}

- (void) saveImage: (NSString *)file {
	unsigned char *buffer = (unsigned char*) calloc (1,  width_ * height_ * 4 );
	unsigned int counter = 0;
	unsigned char *ptr = buffer;
	unsigned char *pix = (unsigned char*)temp_buffer;
	while(counter < (width_*height_)) {
		unsigned int *ptr_val = (unsigned int *) pix;
		unsigned char *arr = (unsigned char *)ptr_val;
		ptr[0] = 255;
		ptr[1] = arr[0];
		ptr[2] = arr[1];
		ptr[3] = arr[2];
		pix += 4;
		ptr += 4;
		counter++;
	}
	unsigned char **temp = (unsigned char **) malloc (sizeof (unsigned char *) * height_);
	for(int i = 0; i < height_; ++i) {
		temp[i] = (unsigned char *)&buffer[i*width_*4];
	}
	
	NSBitmapImageRep *img = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: (unsigned char**)temp pixelsWide: width_ pixelsHigh: height_ bitsPerSample: 8 samplesPerPixel: 4 hasAlpha:YES isPlanar:NO colorSpaceName: NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat bytesPerRow:width_*4 bitsPerPixel:32];
    
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    NSData *imageData = [img representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:file atomically:YES];
	[img release];
	free(temp);
	free(buffer);
}

- (void*) tmpBuffer {
    return temp_buffer;
}


- (void) setTranslationVariable: (float) var {
	translation_variable = var;
	if(trans_var > 0) trans_var = translation_variable;
	else trans_var = -translation_variable;
}


- (void) startProgram {
    render_ok = NO;
}

- (void) exitProgram {
    render_ok = YES;
}



- (CIImage *) translatedImage {
    if(timage != nil) return timage;
    return nil;
}



@end

@implementation AppController

@synthesize file_name;

- (void) awakeFromNib {
	[self startInputSession];
	pathChoosen = NO;
	passEnabled = NO;
	sound_object = nil;
    rec_on = NO;
    session = nil;
    camera = nil;
    [tbl_view setDelegate:self];
    [tbl_view setDataSource: self];
    table_data = [[NSMutableArray alloc] init ];
    table_row_data = [[NSMutableArray alloc] init];
    
    for(int i = 0; szFilters[i] != 0; ++i) {
        
        NSString *s = [NSString stringWithUTF8String:szFilters[i]];
        [tbl_effects addItemWithObjectValue:s];
    }
    
    [tbl_effects selectItemAtIndex:0];
    frames_counted = 0;
    img_counter = YES;
}

- (id) init {
	self = [super init];
	return self;
}

- (void) dealloc {
	[session stopRunning];
	[camera release];
    [file_name release];
    [captureMovieFileOutput release];
	if(sound_object != nil) [sound_object release];
    [input release];
    [table_data release];
    [table_row_data release];
	[super dealloc];
    
}

- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image {
    if([gl_view entered] == NO) {
        [gl_view setEntered: YES];
        NSBitmapImageRep * rep = [[NSBitmapImageRep alloc] initWithCIImage:image];
        [gl_view setImage: rep];
        [rep release];
        ++frames_counted;
        NSString *str;
        if(img_counter == YES) {
            if(rec_on == NO)
                str = [NSString stringWithFormat: @"%d Frames Processed. ", frames_counted];
            else
                str = [NSString stringWithFormat: @"%d/%d Total Frames / Frames per second, %.2f Seconds.", frames_counted, (unsigned int)[gl_view fps], (float)frames_counted/[gl_view fps]];
        } else str = @"Proccessing this may take a while depending on file size . . .";
        [num_frames setStringValue:str];
    }
    return image;
}

- (IBAction) startInputSession {
	[self enableNormalSession];
}

- (void) enableNormalSession {
    NSError *err = nil;
    session = [QTCaptureSession new];
 	camera = [QTCaptureDevice defaultInputDeviceWithMediaType: QTMediaTypeVideo];
	if([camera open:&err] == NO) {
        if(err != nil)
            [NSAlert alertWithError:err];
		NSRunAlertPanel(@"Webcam not accessible", @"Is your webcam plugged in? Program will now exit!..", @"Ok", nil, nil);
		exit(0);		
	}
    input = [[QTCaptureDeviceInput alloc] initWithDevice: camera];
	[session addInput: input error:&err];
    if(err != nil) {
        [NSAlert alertWithError:err];
        exit(0);
    }
	[view setCaptureSession: session];
	[session startRunning];
    rec_on = NO;
}

- (void) enableCaptureSession {
    NSError *err;
    NSString *ffname =@"/tmp/tmpv.mov"; // uses the same file name so only one item is stored in tmp. Before it was random file name.

    
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    if([panel runModal] == NSFileHandlingPanelOKButton) {
        NSString *ext;
        if([chk_box integerValue] == 0) ext = [ NSString stringWithFormat: @"%@", @"m4v"];
        else
            ext = [NSString stringWithFormat: @"%@", @"mov"];
        
        file_name = [[NSString alloc] initWithFormat:@"%@.%@", [panel filename], ext];
        
    } else { file_name = @"test.m4v"; return; }
    
    movie = [[QTMovie alloc] initToWritableFile:ffname error:&err];
    [movie setAttribute: [NSNumber numberWithBool: YES] forKey:QTMovieEditableAttribute];
    //    [movie setAttribute: [NSValue valueWithSize: NSMakeSize(720, 480)] forKey:QTMovieFrameImageSize];
    
    if(movie == nil) {
        NSLog(@"%@", [err localizedDescription]);
    }
    [gl_view setMovie:movie];
    [gl_view setRecording: YES];
    frames_counted = 0;
}

- (void) setDeviceType: (id) sender {
    if(rec_on == NO) {
        NSError *err;
        NSArray *arr = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeVideo];
        int index = [device_combo indexOfSelectedItem];
        if(index >= 0) {
            [camera release];
            [session release];
            [input release];
            camera = [arr objectAtIndex: index];
            session = [QTCaptureSession new];
            if([camera open:&err] == NO) {
                if(err != nil)
                    [NSAlert alertWithError:err];
                NSRunAlertPanel(@"Webcam not accessible", @"Is your webcam plugged in? Program will now exit!..", @"Ok", nil, nil);
                exit(0);		
            }
            input = [[QTCaptureDeviceInput alloc] initWithDevice: camera];
            [session addInput: input error:&err];
            if(err != nil) {
                [NSAlert alertWithError:err];
                exit(0);
            }
            [view setCaptureSession: session];
            [session startRunning];
            rec_on = NO;
            [device_window orderOut:self];
            
        }
    } else {
        [device_window orderOut:self];
        NSRunAlertPanel(@"Please stop recording before switching devices...",@"stop recording first..", @"Ok", nil, nil);
    }
}

- (IBAction) showDeviceSelect: (id) sender {
    static BOOL combo_loaded = NO;
    if(combo_loaded == NO) {
        NSArray *arr = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeVideo];
        if([arr count] == 1) {
            NSRunAlertPanel(@"Only one device found", @"device check", @"Ok", nil, nil);
        }    
        for(id o in arr) {
            [device_combo addItemWithObjectValue:[o localizedDisplayName]];
        }
        combo_loaded = YES;
    }
    [device_combo setEditable: NO];
    [device_window orderFront:self];
}

- (IBAction) rec: (id) sender {
    if(rec_on == NO) {
        rec_on = YES;
        img_counter = YES;
        [self enableCaptureSession];
        if([file_name isEqualTo: @"test.m4v"]) { rec_on = NO; return; }
        [gl_view setRecording:YES];
        [recordButton setTitle:@"Stop"];
        frames_counted = 0;
    }
    else if(rec_on == YES) {
        rec_on = NO;
        frames_counted = 0;
        [progress setHidden:NO];
        [recordButton setTitle:@"Saving..."];
        [progress startAnimation:self];
        [recordButton setEnabled: NO];
        NSNumber *num;
        if([chk_box integerValue] == 0)  
            num = [NSNumber numberWithLong:'M4V '];
        else
            num = [NSNumber numberWithLong:kQTFileTypeMovie];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], QTMovieExport,num, QTMovieExportType, nil];
        dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        void (^writeVideoFile)() = ^() {
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [gl_view toggle_filters: NO];
                img_counter = NO;
            });
            
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [gl_view setRecording:NO]; 
                [movie writeToFile:file_name withAttributes:attrs];
            });
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [movie release];
                NSString *temp = [NSString stringWithFormat:@"Wrote Video to file: %@", file_name];
                [progress stopAnimation:self];
                [progress setHidden:YES];
                NSRunAlertPanel(@"File Saved", temp, @"Ok", nil, nil);
                [recordButton setEnabled:YES];
                [recordButton setTitle:@"Record"];
                [gl_view toggle_filters: YES];
                img_counter = YES;
                [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/tmpv.mov" error:nil];
                frames_counted = 0;
            });
        };
        dispatch_async(q, writeVideoFile);
    }
}

- (IBAction) stopRec: (id) sender {
    
}


- (IBAction) saveTheImage: (id) sender {
    if(pathChoosen == NO) {
        void (^saveTheImage)() = ^() {
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSOpenPanel *panel = [NSOpenPanel openPanel];
                    [panel setAllowsMultipleSelection: NO];
                    [panel setCanChooseFiles: NO];
                    [panel setCanChooseDirectories: YES];
                    if([panel runModal] == NSFileHandlingPanelOKButton) {
                        NSArray *ar = [panel URLs];
                        NSString *output_p = [[[ar objectAtIndex: 0] path ]retain];
                        [output_path setStringValue: output_p];
                        [output_p release];
                        pathChoosen = YES;
                        [self saveTheImage: self];
                    } else return;
                
                });
            });
		};
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), saveTheImage);
    }
    else {
        static int index = 0;
        ++index;
        NSString *custom_str = [save_prefix stringValue];
        if([custom_str length] == 0) custom_str = @"ac_image";
        NSString *str = [NSString stringWithFormat:@"%@/%@_%d.jpg", [output_path stringValue],custom_str,index];
        [gl_view saveImageSynced:str];
        NSString *num = [NSString stringWithFormat:@"%d", index];
        [num_images setStringValue: num];

    }
}

- (IBAction) changeFilter: (id) sender {
	NSInteger num = [filterType indexOfSelectedItem];
    if((num >=  12 && num <= 14)||(num >= 25 && num <= 26))
		[filter_options orderFront:self];
    else if(num == FilterCount) [table_window orderFront:self];
	[gl_view setOperationType:num];
}

- (IBAction) hideDialog: (id) sender {
	[filter_options orderOut:self];
}

- (IBAction) addImageTo: (id) sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection: YES];
	[panel setCanChooseFiles: YES];
	[panel setCanChooseDirectories: NO];
	if([panel runModal]) {
		NSArray *ar = [panel URLs];
		for(NSURL *s in ar) {
			NSString *path = [s path];
			[combo addItemWithObjectValue: path];
		}
	}
}

- (IBAction) rmvImageFrom: (id) sender {
	NSInteger index = [combo indexOfSelectedItem];
	if(index >= 0)
		[combo removeItemAtIndex:index];
}

- (IBAction) makeCurrent: (id) sender {
	NSInteger code = [combo indexOfSelectedItem];
	if(code >= 0) {
        NSArray *ar_path = [combo objectValues];
		NSString *path = [ar_path objectAtIndex:code];
		NSImage *image = [[NSImage alloc] initByReferencingFile:path];
		if(image != nil) {
			[gl_view setRep_image:image];
			[image release];
			[gl_view proc];
		} 		
	} else NSRunAlertPanel(@"Problem Selecting Image", @"Error you must add a image, then select it in the combo box and press Make Current", @"Ok", nil, nil);
}

- (void) makeImageCurrent: (NSString *)image {
	NSImage *imagef = [[NSImage alloc] initByReferencingFile:image];
	if(imagef != nil) {
		[gl_view setRep_image:imagef];
		[imagef release];
		[gl_view proc];
	}
}

- (IBAction) showImageSelector:(id) sender {
	[filter_options orderFront: self];
}

- (IBAction) negateValue: (id) sender {
    
    if([negate_value_chk integerValue] == 0) {
        [gl_view  setNegative: NO];
    }
    else {
        [gl_view setNegative: YES];
    }
    
}

- (IBAction) enablePass: (id) sender {
	[ed_second setEnabled: YES];
	if(passEnabled == NO) {
		[ed_25 setEnabled: YES];
		[ed_50 setEnabled: YES];
		[ed_75 setEnabled: YES];
		passEnabled = YES;
		// setup pass
	}
	else {
		passEnabled = NO;
		[ed_25 setEnabled: NO];
		[ed_50 setEnabled: NO];
		[ed_75 setEnabled: NO];
	}
}

- (IBAction) enable25: (id) sender {
    
}
- (IBAction) enable50: (id) sender {
    
}
- (IBAction) enable75: (id) sender {
    
}

- (IBAction) openOptions: (id) sender {
	[options_window orderFront: self];
}

- (IBAction) dismissOk: (id) sender {
	if([options_second integerValue]) {
		NSInteger dir = [options_select indexOfSelectedItem];
		float values[] = { 0.25f, 0.50f, 0.75f, 0 };
		[gl_view enable_pass2: values[dir]];
	} else {
		[gl_view enable_pass2: 0.0f];
		
	}
    if([frames_p integerValue] <= 0) {
        NSRunAlertPanel(@"Invalid frame count\n", @"Error", @"Ok", nil, nil);
        return;
    }
	int index = 0;
	index = [speed_select indexOfSelectedItem];
	float values[] = { 0.001, 0.1, 0.3, 0.5, 1.0, 0 };
	[gl_view setTranslationVariable: values[index]];
	[options_window orderOut:self];
    [gl_view setFps: [frames_p integerValue]];
}

- (IBAction) hideCapture: (id) sender {
    
}

- (IBAction) disableFilter: (id) sender {
    if([menu_off state] == 0) {
        [menu_off setState: 1];
        [gl_view toggle_filters: NO];
    }
    else {
        [menu_off setState: 0];
        [gl_view toggle_filters: YES];
    }
}
- (IBAction) table_add: (id) sender {
    NSInteger value_index = [tbl_effects indexOfSelectedItem];
    if(value_index >= 0) {
        [table_data addObject: [NSString stringWithUTF8String: szFilters[value_index]]];
        NSNumber *num = [NSNumber numberWithInt:value_index];
        [table_row_data addObject: num ];
        [tbl_view reloadData];
    }
}
- (IBAction) table_rmv: (id) sender {
    int value_index = [tbl_view selectedRow];
    if(value_index >= 0) {
        [table_data removeObjectAtIndex:value_index];
        [table_row_data removeObjectAtIndex:value_index];
        [tbl_view reloadData];
    }
    
}
- (IBAction) table_apply: (id) sender {
    [table_window orderOut:self];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSString *str =  [[aTableColumn headerCell] stringValue];
    if( [str isEqualTo:@"Effect"] )     
    return [table_data objectAtIndex:rowIndex];
    else {
        NSNumber *number = [table_row_data objectAtIndex:rowIndex];
        NSString *str = [NSString stringWithFormat: @"%d", (int)[number integerValue]];
        return str;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [table_data count];
}

- (IBAction) showCustom: (id) sender {
    [table_window orderFront:self];
}

- (IBAction) aboutWithImage: (id) sender {
   NSRunAlertPanel(@"About Image Effects", NSLocalizedString(@"AboutInfo", @""), @"Ok", nil, nil);
}
- (IBAction) aboutEffects: (id) sender {
    NSRunAlertPanel(@"About the Effects", NSLocalizedString(@"AboutEffects", @"about the effects"), @"Ok", nil, nil);
}

- (IBAction) shareWithAuthor: (id) sender{
    NSRunAlertPanel(@"(C) 2012 LostSideDead Software\n Application written by Jared Bruni.", @"Be sure to share with us what you think @ http://lostsidedead.com/blog/?index=97", @"Ok", nil, nil);
}

@end

