#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#import <Cocoa/Cocoa.h>
#import "Trackball.h"

@interface MyOpenGLView : NSOpenGLView
{
	int		ntris;
	int		nverts;
        
	GLuint		*tris;
	GLfloat		*verts;
	GLfloat		*vertscolour;
	GLfloat		*vertsparam;
	
	GLubyte		*texture;
	NSSize		textureSize;
	GLuint		textureId;
	BOOL		hasTexture;
	
	int			proj;
	GLfloat		*vertsproj;
	
	Trackball	*m_trackball;
	float		m_rotation[4];	// The main rotation
	float		m_tbRot[4];	// The trackball rotation
	float		rot[3];
	
	float		zoom;		// Zoom = exp(zoom)
}
- (void) setVertices: (float *) vert number:(int)n;
- (void) setTriangles: (int *) trian number:(int)n;
- (void) setVerticesColour: (float *) vertcolour;
- (void) setParam: (float *)param;
- (void) setTexture: (char *)image size: (NSSize)s;
- (void) setTextureActive: (BOOL)isActive;

- (void) setStandardRotation:(int)view;
- (void) setRotationX: (float) angle;
- (void) setRotationY: (float) angle;
- (void) setRotationZ: (float) angle;

- (void)rotateBy:(float *)r;		// trackball method

- (void)getRotationMatrix:(float *)mat;
- (void) setProjection:(int)p;
- (void) projection;

- (void)setZoom:(float)z;

- (void) savePicture;
- (void) savePicture:(NSString *)filename;
- (void) getPixels:(char*)baseaddr width:(long)w height:(long)h rowbyte:(long)rb;

@end