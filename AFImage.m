//
//  AFImage.m
//  Camera
//
//  Created by Jared Bruni on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AFImage.h"


@implementation AFImage

- (id) initWithImage: (NSImage *)i {
	self = [super init];
	image = [i retain];
	br = [[NSBitmapImageRep alloc] initWithData: [image TIFFRepresentation]];
	return self;
}

- (id) initWithRep: (NSBitmapImageRep *)b {
	image = nil;
	br = [b retain];
	return self;
	
}

- (void) dealloc {
	if(image != nil)
		[image release];
	[br release];
	[super dealloc];
}

- (void *) getBuffer { 
	return (void *)[br bitmapData];
}
- (int) getBytesPerPixel {
	return [br bitsPerPixel] / 8;
}
- (int) getBytesPerRow {
	return [br bytesPerRow];
}

@end


@implementation AFPixel

- (id) init {
	x = y = 0;
	self = [super init];
	color.color = 0;
	return self;
}


- (unsigned int *) pixel { return &color.color; }
- (unsigned char *) bytes { return color.bytes; }
- (int) getX { return x; }
- (int) getY { return y; }
- (void) setColor: (unsigned int) dst_color { color.color = dst_color; }
- (void) setCoords: (int) xv Y: (int) yv {
	x = xv;
	y = yv;	
}
- (void) randDirection {
	direction = rand()%8;
}

- (int) dir { return direction; }

@end


@implementation AFBuffer


- (id) init {
	self = [super init];
	buffer = nil;
	return self;
	
}

- (void) dealloc {
	[buffer release];
	[super dealloc];
}

- (void) freeBuffer {

	if(buffer != nil)
	[buffer release];
	
}

- (void) setBuffer: (unsigned int *)buf W: (int) buf_width {
	
	for(int z = 0; z < height; ++z) {
		for(int i = 0; i < width; ++i) {
			AFPixel *pixel = [buffer objectAtIndex:i+z*width];
			[pixel setColor: buf[i+z*buf_width]];
		}
		
	}
	
}

- (void) initBuffer: (int)w H: (int) h {

	buffer = [[NSMutableArray alloc] init];
	width = w;
	height = h;
	for(int y = 0; y < h; ++y) {
		for(int x = 0; x < w; ++x) {
			AFPixel *pixel = [[AFPixel alloc] init];
			[pixel setCoords: x Y: y];
			[pixel randDirection];
			[buffer addObject:pixel];
			[pixel release];
		}
	}
	
}

- (void) drawBuffer: (unsigned int *)buffer_to width: (int) w speed:(float)trans_speed {
	
	static float alpha = 0.4f;
	
	for(int z = 0; z < height-1; ++z) {
		for(int i = 0; i < width-1; ++i) {
			
			AFPixel *p = [buffer objectAtIndex: (i+z*w)];
			int cx = [p getX];
			int cy = [p getY];
			
			if(cx > width || cy > height || cx < 0 || cy < 0)
				continue;
			
			union ColorType color[2];
			color[0].color = buffer_to[i+z*w];
			color[1].color = *[p pixel];			
			color[0].bytes[0] += color[1].bytes[0] * alpha;
			color[0].bytes[1] += color[1].bytes[1] * alpha;
			color[0].bytes[2] += color[1].bytes[2] * alpha;
			color[0].bytes[3] = 255;
			buffer_to[i+z*w] =  color[0].color;
		}
	}
	
	alpha += trans_speed;
	
}
- (void) updateBuffer {

	
	for(int z = 0; z < height; ++z) {
		for(int i = 0; i < width; ++i) {
			
			AFPixel *p = [buffer objectAtIndex: i+z*width];
			switch([p dir]) {
				case 0:
					[p setCoords: [p getX]+1 Y: [p getY]];
					break;
				case 1:
					[p setCoords: [p getX] Y: [p getY]+1];
					break;
				case 2:
					[p setCoords: [p getX]+1 Y: [p getY]+1];
					break;
				case 3:
					[p setCoords: [p getX]-1 Y: [p getY]];
					break;
				case 4:
					break;
					[p setCoords: [p getX] Y: [p getY]-1];
				case 5:
					[p setCoords: [p getX]-1 Y: [p getY]-1];
					break;
				case 6:
					[p setCoords: [p getX]-1 Y: [p getY]+1];
					break;
				case 7:
					[p setCoords: [p getX]+1 Y: [p getY]-1];
					break;
				}
			
			if( [ p getX ] > width-1 || [ p getX ] <= 0 || [ p getY ] > height-1 || [ p getY ] <= 0 ) 
				[p setCoords:rand()%width Y: rand()%height];
				[p randDirection];
			
		}
		
	}
	
}


- (void) drawBufferTwice: (unsigned int*)buffer_to Width: (int)wid Height: (int) hei speed: (float) alpha_add {
	
	static int i=0,z=0;
	static float alpha = 1.0f;
	for(z = 0; z < hei; ++z) {
		
		for(i = 0; i < wid; ++i) {
			AFPixel *pix = [buffer objectAtIndex:i+z*wid];
			union ColorType ct[4];
			int cx = [pix getX];
			int cy = [pix getY];
			
			if(cx > 0 && cx < wid && cy > 0 && cy < hei) {
				ct[0].color = buffer_to[i+z*wid];
				ct[1].color = *[pix pixel];
				ct[0].bytes[0] += (alpha*ct[1].bytes[0]);
				ct[0].bytes[1] += (alpha*ct[1].bytes[1]);
				ct[0].bytes[2] += (alpha*ct[1].bytes[2]);
				ct[0].bytes[3] = 255;
				buffer_to[cx+cy*wid] = ct[0].color;
			} 			
		}
	}
	
	alpha += alpha_add;
}


@end


