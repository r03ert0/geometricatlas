#import "AppController.h"

NSTextView *globaltv;

@implementation AppController
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	globaltv=logField;
	//stdout->_write = stdoutwrite;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[splash close];
    [window makeKeyAndOrderFront:nil];
}
-(MyDocument*)getCurrentDocument
{
    NSDocumentController *dc;
    MyDocument *doc;

    dc = [NSDocumentController sharedDocumentController];
    doc = (MyDocument*)[dc currentDocument];

    return doc;
}
#pragma mark -
#pragma mark [   surface tab   ]
// surface tab
- (int)getMeshVerticesNumber
{
    MyDocument *doc=[self getCurrentDocument];
    return (int)[doc getMeshVerticesNumber];
}
- (float*)getMeshVertices
{
    MyDocument *doc=[self getCurrentDocument];
    return (float*)[doc getMeshVertices];
}
- (float*)getMeshVerticesColor
{
    MyDocument *doc=[self getCurrentDocument];
    return (float*)[doc getMeshVerticesColor];
}
- (float*)getMeshNormalisationMatrix
{
    MyDocument *doc=[self getCurrentDocument];
    return (float*)[doc getMeshNormalisationMatrix];
}
#pragma mark -
#pragma mark [  volume tab  ]
-(IBAction)insertCommand:(id)sender
{
	if([volumeCommandsPopUp indexOfSelectedItem]>1)
		[commands insertText:[volumeCommandsPopUp titleOfSelectedItem]];
}
- (void)setSliceFloatValue:(float)t
{
    [sliceField setFloatValue:t];
}
- (NSString*)getCommandsString;
{
    return [commands string];
}
- (void)setCommandsString:(NSAttributedString*)cmd
{
    [[commands textStorage] setAttributedString:cmd];
}
- (int)getVolumeType
{
    return [volumePopUp selectedTag];
}
#pragma mark -
#pragma mark [  talairach tab  ]
- (IBAction) toggleShowColorWell:(id)sender
{
    int index=[colormapPopUp indexOfSelectedItem];
    
    if(index>7) [colorWell setHidden:NO];
    else	[colorWell setHidden:YES];
}
- (NSAttributedString *)getTalairachViewString
{
    return (NSAttributedString *)[talairachView textStorage];
}
- (int)getProjectionMode
{
    return [projectionModePopUp indexOfSelectedItem];
}
- (void)setTalairachViewString:(NSAttributedString *)aString
{
    [[talairachView textStorage] setAttributedString:aString];
    [talairachView setNeedsDisplay:YES];
}
- (void)setDistanceField:(float)dist
{
    [distField setFloatValue:dist];
}
- (void)setDistanceSlider:(float)dist
{
    [distSlider setFloatValue:dist];
}
-(int)getColourmap
{
    return [colormapPopUp indexOfSelectedItem];
}
- (void)getColour:(float*)c
{
    NSColor *color=[colorWell color];
    float alpha;
    [color getRed:&c[0] green:&c[1] blue:&c[2] alpha:&alpha];
}
#pragma mark -
#pragma mark [  geometric atlas tab  ]
#pragma mark -
- (int)numberOfRowsInTableView:(NSTableView *)tv
{
	MyDocument *doc=[self getCurrentDocument];
    return [doc img_array_count];
}
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{
	MyDocument *doc=[self getCurrentDocument];
	id  obj;
	
	//row=[doc img_array_count]-row-1;
	if ([[tc identifier] isEqualToString:@"Visible"])
	{
		obj=[doc img_array_visibilityAtIndex:row];
	}
	else
		obj=[doc img_array_keyAtIndex:row];
	return obj;
}
- (void)tableView:(NSTableView *)tv setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tc row:(int)row
{
	MyDocument *doc=[self getCurrentDocument];
	[doc img_array_setVisibilityAtIndex:row to:[(NSNumber*)anObject boolValue]];
	[table reloadData];	
    return;
}
@end
int	stdoutwrite(void *inFD, const char *buffer, int size)
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init]	;
	NSString	*tmp = [NSString stringWithUTF8String:buffer];// length:size]	;	// choose the best encoding for your app
	NSAttributedString *atmp=[[NSAttributedString alloc] initWithString:tmp];
	
	[[globaltv textStorage] appendAttributedString:atmp];
	//objc_msgSend(self, SEL @selector(dothething:),atmp);
			// do what you need with the tmp string here
		// like appending it to a NSTextView
		// you may like to scan for a char(12) == CLEARSCREEN
		// and others "special" characters...

	[pool release];
	[atmp release];
	return size;
}
