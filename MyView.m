#import "MyView.h"

@implementation MyView
- (id) initWithFrame: (NSRect) frame
{
	isqr=[[NSMutableDictionary dictionaryWithCapacity:10] retain];
	printf("init %s\n",[[isqr description] UTF8String]);
    return self = [super initWithFrame:frame];
}
- (BOOL) isFlipped
{
    return NO;
}
- (void) drawRect: (NSRect) rect
{
    if(pict)
    {
        NSRect	r_src,r_dst;
        NSSize	s;
        
        //source rect
        r_src.origin.x=r_src.origin.y=0;
        r_src.size=[pict size];

        //dest rect
        if(rect.size.width>rect.size.height)	s.width=s.height=rect.size.height;
        else					s.width=s.height=rect.size.width;
        r_dst.origin.x=(rect.size.width-s.width)/2.0;
        r_dst.origin.y=(rect.size.height-s.height)/2.0;
        r_dst.size=s;
        
        //draw
        [pict drawInRect:r_dst fromRect:r_src operation:NSCompositeSourceOver fraction:1.0];
		
		if(drawInfoSquare==TRUE)
		{
			NSRect  src=NSRectFromString([isqr objectForKey:@"src"]);
			NSRect  dst=NSRectFromString([isqr objectForKey:@"dst"]);
			[[isqr objectForKey:@"image"]   drawInRect:dst
											fromRect:src
											operation:NSCompositeSourceOver fraction:1.0];
		}
    }
	if(drawInfoSquare==TRUE)
	{
		NSRect  src=NSRectFromString([isqr objectForKey:@"src"]);
		NSRect  dst=NSRectFromString([isqr objectForKey:@"dst"]);
		[[isqr objectForKey:@"image"]   drawInRect:dst
										fromRect:src
										operation:NSCompositeSourceOver fraction:1.0];
	}
}
-(void)setPicture:(NSImage*)img
{
    pict = [[NSImage alloc] initWithSize:[img size]];
    [pict lockFocus];
		[img	compositeToPoint:NSZeroPoint
				operation:NSCompositeSourceOver
				fraction:1.0];
    [pict unlockFocus];
}
-(NSImage*)picture
{
    return pict;
}
- (void) savePicture
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    int		result;
    
    [savePanel setRequiredFileType:@"tif"];
    [savePanel setCanSelectHiddenExtension:YES];
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        NSString *filename=[savePanel filename];
        [[pict TIFFRepresentation] writeToFile:filename atomically:YES];
    }
}
#pragma mark -
- (void)mouseDown:(NSEvent *)event
{
	NSPoint p=[self convertPoint:[event locationInWindow] fromView:nil];
	NSRect  rview=[self bounds];
	float   R=(rview.size.width<rview.size.height)?(0.5*rview.size.width):(0.5*rview.size.height);
	float   x,y,a,b;
	NSString	*str;
	NSImage		*img;
	
	x=(p.x-(rview.origin.x+rview.size.width/2.0))/R;
	y=(p.y-(rview.origin.y+rview.size.height/2.0))/R;
	a=sqrt(x*x+y*y);
	b=atan2(y,x);
	
	str=[NSString stringWithFormat:@"alpha=%i\nbeta=%i",(int)(a*180),(int)(b*180/pi)];
	img=[[NSImage alloc] initWithSize:[str sizeWithAttributes:NULL]];
	[img lockFocus];
	NSFrameRect(NSMakeRect(0,0,[img size].width,[img size].height));
	[str drawAtPoint:NSMakePoint(0,0) withAttributes:NULL];
	[img unlockFocus];
	
	if([isqr count]>0) [isqr removeAllObjects];
	[isqr addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
			img, @"image",
			NSStringFromRect(NSMakeRect(0,0,[img size].width,[img size].height)),@"src",
			NSStringFromRect(NSMakeRect(p.x,p.y,[img size].width,[img size].height)),@"dst",
			nil]];

	drawInfoSquare=TRUE;
	[img release];
	[self setNeedsDisplay:YES];
}
- (void)mouseUp:(NSEvent *)theEvent
{
	drawInfoSquare=FALSE;
	[self setNeedsDisplay:YES];
}

@end
