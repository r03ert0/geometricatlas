/* MyQuickDrawView */

#import <Cocoa/Cocoa.h>

@interface MyView : NSView
{
    NSImage	*pict;
	NSArray *pict_array;

	BOOL	drawInfoSquare;
	NSMutableDictionary *isqr;
}
-(BOOL)isFlipped;
-(void)setPicture:(NSImage*)img;
-(NSImage*)picture;
- (void) savePicture;
@end
