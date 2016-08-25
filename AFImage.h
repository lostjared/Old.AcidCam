//
//  AFImage.h
//  Camera
//
//  Created by Jared Bruni on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AFImage : NSObject {
	
	NSImage *image;
	NSBitmapImageRep *br;
	
}

- (id) initWithImage: (NSImage *)i;
- (id) initWithRep: (NSBitmapImageRep *)br;
- (void *) getBuffer;
- (int) getBytesPerPixel;
- (int) getBytesPerRow;

@end


union ColorType {
	unsigned char bytes[4];
	unsigned int color;
};


@interface AFPixel : NSObject {

	union ColorType color;
	int x,y,direction;
	
}

- (unsigned int *) pixel;
- (unsigned char *) bytes;
- (void) setCoords: (int) x Y: (int) y;
- (void) randDirection;
- (void) setColor: (unsigned int) dst_color;

@end

@interface AFBuffer : NSObject {
	NSMutableArray *buffer;
	int width, height;

}
- (void) setBuffer: (unsigned int *)buf W: (int) buf_width;
- (void) initBuffer: (int)w H: (int) h;
- (void) drawBuffer: (unsigned int *)buffer width: (int) w speed: (float)tv;
- (void) drawBufferTwice: (unsigned int*)buffer_to Width:(int) wid Height:(int) hei speed:(float)trans;


- (void) updateBuffer;
- (void) freeBuffer;

@end

