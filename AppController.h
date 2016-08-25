//
//  AppController.h
//  Camera
//
//  Created by Jared Bruni on 5/24/11.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#include "AFImage.h"

union Color {
	unsigned char colors[4];
	unsigned int color;
};

@interface capView : QTCaptureView {
	
	
}

@end

size_t height_,width_;
NSMutableArray *table_data;
NSMutableArray *table_row_data;
const char *szFilters[] = {"Self AlphaBlend", "TriBlend", "TriBlend Paradox", "TriBlend double", "TriBlend MD", "rand()%TriBlend", "Two Blend", "TriBlend 2", "Intense Blend", "Blend #5",
    "Tryp", "Haze", "Blend with Image", "Red/Blue TriBlend with image", "Double Blend", "Negative", "Negative Paradox", "Blank", "Thought","Idea MAX","Idea MAX Rev","Strobe Effect","TestEffect", "LostEffect", "ThoughtMode", "Blend with Image #2","Blend with Image #3",0};

static const unsigned int FilterCount = 27;

@interface GLView : NSOpenGLView {

	NSTimer *program_timer;
	uint32_t *raw_bytes;
    NSBitmapImageRep *brep;
	NSBitmapImageRep *irep;
	void *temp_buffer, *orig_buffer;
	int current_operation;
	BOOL saveMe;
	NSString *saveFile;
	NSImage *rep_image;
	int img_w, img_h;
	BOOL render_ok;
	unsigned char *image_data;
	float pass2_alpha;
	float translation_variable, trans_var;
	AFBuffer *src_buffer;
	BOOL buffer_set;
	BOOL resize_buffer;
	NSSound *sound_object;
    NSBitmapImageRep *bmp_img;
    CIImage *timage;
    BOOL recording;
    QTMovie *movie;
    BOOL entered;
    NSInteger fps;
    BOOL filter_on;
    BOOL isNeg;
    int counter_var;
    
}
- (void) setMovie:(QTMovie *)m;
- (void) tBlend;
- (void) setImage: (NSBitmapImageRep *) nsi;
- (void) saveImage: (NSString *)file;
- (void) testBlend;
- (void) triBlend;
- (void) triBlendParadox;
- (void) triBlendDouble;
- (void) triBlendMD;
- (void) randTriBlend;
- (void) twoBlend;
- (void) triBlend2; 
- (void) blend3;
- (void) blend4;
- (void) blend5;
- (void) blendWithImage;
- (void) triBlendWithImage;
- (void) doubleBlend;
- (void) haze;
- (void) negative;
- (void) negative_paradox;
- (void) blank_filter;
- (void) thought_filter;
- (void) four_twenty;
- (void) copyBuffer;
- (void) displayBuffer;
- (void) setOperationType: (int) type;
- (void) saveImageSynced: (NSString *)str;
- (void) proc;
- (void) pass2_blend;
- (void) enable_pass2: (float ) q;
- (void) tryptamine;
- (void) idea_max;
- (void) testEffect;
- (void) LostEffect;
- (void) idea_max_rev;
- (void) strobe_effect;
- (void) thoughtMode;
- (void) blendWithImage2;
- (void) blendWithImage3;
- (void) setTranslationVariable: (float) var;
- (void) drawThread: (id) obj;
- (void) startProgram;
- (void) exitProgram;
- (void) setNegative: (BOOL) value;
- (NSBitmapImageRep *)bmpImage;
- (CIImage *) translatedImage;
- (void*) tmpBuffer;
- (void) toggle_filters: (BOOL) yesno;
- (void) drawData: (int) index;

@property (readwrite,retain) NSImage *rep_image;
@property (readwrite,retain) NSSound *sound_object;
@property (readwrite,assign) BOOL render_ok;
@property (readwrite,assign) BOOL recording;
@property (readwrite,assign) NSInteger fps;
@property (readwrite, assign) BOOL entered;

@end

@interface AppController : NSObject<NSTableViewDelegate, NSTableViewDataSource> {

	QTCaptureSession *session;
	QTCaptureDevice  *camera;
    QTCaptureMovieFileOutput *captureMovieFileOutput;
    QTCaptureInput *input;
	IBOutlet capView *view;
	IBOutlet GLView *gl_view;
	IBOutlet NSTextField *output_path, *num_images, *num_frames;
	IBOutlet NSButton *save_image;
	BOOL pathChoosen;
	IBOutlet NSPopUpButton *filterType;
	IBOutlet NSWindow *filter_options, *camera_window;
	IBOutlet NSComboBox *combo;
	IBOutlet NSButton *makeCurrentButton;
	IBOutlet NSMenuItem *ed_second, *ed_25, *ed_50, *ed_75;
	IBOutlet NSWindow *options_window;
	IBOutlet NSButton *options_second;
	IBOutlet NSPopUpButton *options_select, *speed_select;
	IBOutlet NSTextField *save_prefix;
    IBOutlet NSButton *recordButton;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextField *frames_p;
    IBOutlet NSWindow *win1;
    IBOutlet NSButton *chk_box;
    IBOutlet NSComboBox *device_combo;
    IBOutlet NSWindow *device_window;
    IBOutlet NSButton *negate_value_chk;
    IBOutlet NSTableView *tbl_view;
    IBOutlet NSButton *tbl_add, *tbl_rmv, *tbl_apply;
    IBOutlet NSComboBox *tbl_effects;
    IBOutlet NSWindow *table_window;
	BOOL passEnabled;
	NSSound *sound_object;
    BOOL rec_on;
    QTMovie *movie;
    NSString *file_name;
    IBOutlet NSMenuItem *menu_off;
    unsigned int frames_counted;
    BOOL img_counter;
	
}
- (IBAction) shareWithAuthor: (id) sender;
- (IBAction) hideCapture: (id) sender;
- (IBAction) startInputSession;
- (IBAction) saveTheImage: (id) sender;
- (IBAction) changeFilter: (id) sender;
- (IBAction) hideDialog: (id) sender;
- (IBAction) addImageTo: (id) sender;
- (IBAction) rmvImageFrom: (id) sender;
- (void) makeImageCurrent: (NSString *)image;	
- (IBAction) makeCurrent: (id) sender;
- (IBAction) showImageSelector:(id) sender;
- (IBAction) enablePass: (id) sender;
- (IBAction) enable25: (id) sender;
- (IBAction) enable50: (id) sender;
- (IBAction) enable75: (id) sender;
- (IBAction) dismissOk: (id) sender;
- (IBAction) openOptions: (id) sender;
- (IBAction) rec: (id) sender;
- (IBAction) stopRec: (id) sender;
- (void) enableCaptureSession;
- (void) enableNormalSession;
- (IBAction) disableFilter: (id) sender;
- (IBAction) setDeviceType: (id) sender;
- (IBAction) showDeviceSelect: (id) sender;
- (IBAction) negateValue: (id) sender;
- (IBAction) table_add: (id) sender;
- (IBAction) table_rmv: (id) sender;
- (IBAction) table_apply: (id) sender;
- (IBAction) showCustom: (id) sender;
- (IBAction) aboutWithImage: (id) sender;
- (IBAction) aboutEffects: (id) sender;
@property (readwrite, retain) NSString *file_name;

@end

