/* AppController */

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"
#import <objc/objc-runtime.h>

@interface AppController : NSObject
{
    IBOutlet NSWindow		*window;
	IBOutlet NSWindow		*splash;
	IBOutlet NSTextView	*logField;

    // volume tab outlets
    IBOutlet NSPopUpButton	*volumePopUp;
	IBOutlet NSPopUpButton  *volumeCommandsPopUp;
    IBOutlet NSTextField	*sliceField;
    IBOutlet NSTextView		*commands;

    // talairach tab outlets
    IBOutlet NSTextView	*talairachView;
    IBOutlet NSTextField *distField;
    IBOutlet NSSlider	*distSlider;
    IBOutlet NSPopUpButton	*projectionModePopUp;
    IBOutlet NSPopUpButton	*colormapPopUp;
    IBOutlet NSColorWell	*colorWell;
	
	// geometric atlas tab outlets
	IBOutlet NSTableView	*table;
}
-(MyDocument*)getCurrentDocument;
// surface tab
- (int)getMeshVerticesNumber;
- (float*)getMeshVertices;
- (float*)getMeshVerticesColor;
- (float*)getMeshNormalisationMatrix;
// volume tab
-(IBAction)insertCommand:(id)sender;
- (void)setSliceFloatValue:(float)t;
- (NSString*)getCommandsString;
- (void)setCommandsString:(NSAttributedString*)cmd;
- (int)getVolumeType;
// geometric atlas tab
// talairach tab
- (IBAction) toggleShowColorWell:(id)sender;
- (NSAttributedString *)getTalairachViewString;
- (void)setTalairachViewString:(NSAttributedString *)aString;
- (int)getProjectionMode;
- (void)setDistanceField:(float)dist;
- (void)setDistanceSlider:(float)dist;
- (void)getColour:(float*)colour;
- (int)getColourmap;
@end

int	stdoutwrite(void *inFD, const char *buffer, int size);
