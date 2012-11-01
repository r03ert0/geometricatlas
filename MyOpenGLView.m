#import "MyOpenGLView.h"

@implementation MyOpenGLView

// Override NSView's initWithFrame: to specify our pixel format:
- (id) initWithFrame: (NSRect) frame
{
    int	i,size=64;
    // 1. Initialize pixel format
    GLuint attribs[] = 
    {
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAWindow,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAStencilSize, 8,
            NSOpenGLPFAAccumSize, 0,
            0
    };

    NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs];
    
    self = [super initWithFrame:frame pixelFormat: [fmt autorelease]];
    if (!fmt)	NSLog(@"No OpenGL pixel format");
    [[self openGLContext] makeCurrentContext];
    
    // 2. Init GL
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_SMOOTH);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    // 3. Init default mesh
    tris  = (GLuint *) calloc( 6, sizeof(GLuint) );
    verts = (GLfloat *) calloc( 4*3, sizeof(GLfloat) );
	vertsproj = (GLfloat *) calloc( 4*3, sizeof(GLfloat) );
    vertscolour = (GLfloat *) calloc( 4*3, sizeof(GLfloat) );
    vertsparam = (GLfloat *) calloc( 4*2, sizeof(GLfloat) );
    texture = (GLubyte *) calloc( 64*64*3, sizeof(GLubyte) );

    tris[0] = 0; tris[1] = 2; tris[2] = 1;
    tris[3] = 2; tris[4] = 3; tris[5] = 1;
    ntris=2;

    verts[0] = 0.0f;  verts[1] = -2.0f; verts[2] = -2.0f;
    verts[3] = 1.0f;  verts[4] =  0.0f; verts[5] = 0.0f;
    verts[6] = -1.0f; verts[7] =  0.0f; verts[8] = 0.1f;
    verts[9] = 0.0f;  verts[10] = 2.0f; verts[11]= 0.2f;

    vertscolour[0] = 1;  vertscolour[1] = 0; vertscolour[2] = 0;
    vertscolour[3] = 1;  vertscolour[4] = 0; vertscolour[5] = 0;
    vertscolour[6] = 1;  vertscolour[7] = 0; vertscolour[8] = 1;
    vertscolour[9] = 1;  vertscolour[10] =0; vertscolour[11]= 0;
    
    vertsparam[0] = 0.0f;  	vertsparam[1] = 0.0f;
    vertsparam[2] = 1.0f;	vertsparam[3] = 0.0f;
    vertsparam[4] = 0.0f; 	vertsparam[5] = 1.0f;
    vertsparam[6] = 1.0f;	vertsparam[7] = 1.0f;
    
    for(i=0;i<size*size*3;i++)
    {	if(i<size*size*3/2)	texture[i]=255*(i%17);
        else			texture[i]=0;
    }
    glGenTextures(1,&textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0,3, size, size, 0, GL_RGB, GL_UNSIGNED_BYTE,texture);
    free(texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    [self setTextureActive:YES];
    
    // 4. Initialize the trackball.
    m_trackball = [[Trackball alloc] init];
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 1.0;
    m_rotation[2] = m_tbRot[2] = 0.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
    
    rot[0]=rot[1]=rot[2]=0;
    
    // 5. Initialize zoom
    zoom=1;
	
	// 6. Initialize projection
	proj=0;
    
    return self;
}

#pragma mark -
- (void) drawRect: (NSRect) rect
{
	float	aspectRatio;
    
    [self update];

    // init projection
        glViewport(0, 0, (GLsizei) rect.size.width, (GLsizei) rect.size.height);
        glClearColor(1,1,1, 1);
        glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT+GL_STENCIL_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        aspectRatio = (float)rect.size.width/(float)rect.size.height;
        glFrustum(-aspectRatio, aspectRatio, -1.0, 1.0, 5.0, 100.0);

    // prepare drawing
        glMatrixMode (GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt (0,0,-10*zoom, 0,0,0, 0,1,0); // eye,center,updir
        glRotatef(m_tbRot[0],m_tbRot[1], m_tbRot[2], m_tbRot[3]);
        glRotatef(m_rotation[0],m_rotation[1],m_rotation[2],m_rotation[3]);
        glRotatef(rot[0],1,0,0);
        glRotatef(rot[1],0,1,0);
        glRotatef(rot[2],0,0,1);

    // draw
        glEnableClientState( GL_VERTEX_ARRAY);
		if(proj==0)
			glVertexPointer( 3, GL_FLOAT, 0, verts );
		else
		{
			[self projection];
			glVertexPointer( 3, GL_FLOAT, 0, vertsproj );
		}
        if(vertscolour)
        {	glEnableClientState( GL_COLOR_ARRAY );
                glColorPointer( 3, GL_FLOAT, 0, vertscolour );
        }
        if(hasTexture && vertsparam)
        {	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
                glTexCoordPointer( 2, GL_FLOAT, 0, vertsparam );
        }
        glDrawElements( GL_TRIANGLES, ntris*3, GL_UNSIGNED_INT, tris );

    [[self openGLContext] flushBuffer];
}
#pragma mark -
- (void) setVertices: (float *) vert number:(int)n
{
    verts=(GLfloat*)vert;
	nverts=n;
	
	free(vertsproj);
	vertsproj = (GLfloat *) calloc( n*3, sizeof(GLfloat) );
}
- (void) setTriangles: (int *) trian number:(int)n
{
    tris=(GLuint*)trian;
    ntris=n;
}

- (void) setVerticesColour: (float *) vertcolour
{
    vertscolour=(GLfloat*)vertcolour;
}
- (void) setParam: (float *)param
{
    vertsparam=(GLfloat*)param;
}
- (void) setTexture: (char *)image size:(NSSize)s
{
    texture=(GLubyte*)image;
    textureSize=s;

    glGenTextures(1,&textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0,3, textureSize.width,textureSize.height, 0, GL_RGB, GL_UNSIGNED_BYTE,texture);
}
- (void) setTextureActive:(BOOL)isActive
{
    hasTexture=isActive;
    if(isActive)	glEnable(GL_TEXTURE_2D);
    else		glDisable(GL_TEXTURE_2D);
    [self setNeedsDisplay:YES];
}
#pragma mark -
- (void)setStandardRotation:(int)view
{
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 0.0;
    m_rotation[2] = m_tbRot[2] = 1.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
    
    rot[0]=rot[1]=rot[2]=0;
    
    switch(view)
    {
        case 1:m_rotation[0]=270;	m_rotation[1]=1;m_rotation[2]=0; break; //sup
        case 4:m_rotation[0]= 90;	break; //frn
        case 5:m_rotation[0]=  0;	break; //tmp
        case 6:m_rotation[0]=270;	break; //occ
        case 7:m_rotation[0]=180;	break; //med
        case 9:m_rotation[0]= 90;	m_rotation[1]=1;m_rotation[2]=0; break; //cau
    }
    [self setNeedsDisplay:YES];
}
- (void) setRotationX: (float) angle
{
    rot[0]=angle;
    [self setNeedsDisplay:YES];
}
- (void) setRotationY: (float) angle
{
    rot[1]=angle;
    [self setNeedsDisplay:YES];
}
- (void) setRotationZ: (float) angle
{
    rot[2]=angle;
    [self setNeedsDisplay:YES];
}

- (void)rotateBy:(float *)r
{
    m_tbRot[0] = r[0];
    m_tbRot[1] = r[1];
    m_tbRot[2] = r[2];
    m_tbRot[3] = r[3];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [m_trackball
        start:[theEvent locationInWindow]
        sender:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Accumulate the trackball rotation
    // into the current rotation.
    [m_trackball
        add:m_tbRot toRotation:m_rotation];

    m_tbRot[0]=0;
    m_tbRot[1]=1;
    m_tbRot[2]=0;
    m_tbRot[3]=0;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [self lockFocus];
    [m_trackball
        rollTo:[theEvent locationInWindow]
        sender:self];
    [self unlockFocus];
    [self setNeedsDisplay:YES];
}
#pragma mark -
- (void)getRotationMatrix:(float *)mat
{
	glGetFloatv(GL_MODELVIEW_MATRIX,mat);
}
- (void) setProjection:(int)p
{
	proj=p;
	[self setNeedsDisplay:YES];
}
void invMat(float *a,float *b);
void invMat(float *a,float *b)
// The inverse of the matrix a stored in matrix b
// Input: matrix a[9]
// Output: matrix b[9]
{
    float	det;
    
    det=a[0]*(a[4]*a[8]-a[5]*a[7])
            +a[1]*(a[5]*a[6]-a[3]*a[8])
            +a[2]*(a[3]*a[7]-a[4]*a[6]);
            
    if(det==0)
            b=a;
    else
    {
        b[0]=(a[4]*a[8]-a[5]*a[7])/det;
        b[1]=(a[2]*a[7]-a[1]*a[8])/det;
        b[2]=(a[1]*a[5]-a[2]*a[4])/det;
        
        b[3]=(a[5]*a[6]-a[3]*a[8])/det;
        b[4]=(a[0]*a[8]-a[2]*a[6])/det;
        b[5]=(a[2]*a[3]-a[0]*a[5])/det;
        
        b[6]=(a[3]*a[7]-a[4]*a[6])/det;
        b[7]=(a[1]*a[6]-a[0]*a[7])/det;
        b[8]=(a[0]*a[4]-a[1]*a[3])/det;
    }
}

void dynstereographic(float *mat, float *src, float *dst);
void dynstereographic(float *mat, float *src, float *dst)
{
    float	xp[3],sp[3];
    float	x,y,z,n;
    float	h,v,delta;
        
    n=sqrt(src[0]*src[0]+src[1]*src[1]+src[2]*src[2]);
    xp[0] =src[0]/n; xp[1] =src[1]/n; xp[2] =src[2]/n;

    x = acos(xp[0]*mat[0]+xp[1]*mat[1]+xp[2]*mat[2]);
    y = acos(xp[0]*mat[3]+xp[1]*mat[4]+xp[2]*mat[5]);
    z = acos(xp[0]*mat[6]+xp[1]*mat[7]+xp[2]*mat[8]);

    if(z*z<0.000001)	delta=1;
    else		delta = cos(y)/sin(z);
    if(delta<-1) delta=-1;
    if(delta>1) delta=1;

    h = z*sin(acos(delta));
    v = z*delta;
    if(x>pi/2.0)
	{	sp[0]=-h; sp[1]=v; sp[2]=n;}
    else
	{   sp[0]=h; sp[1]=v; sp[2]=n;}
    
	dst[0]=mat[0]*sp[0]+mat[3]*sp[1]+mat[6]*sp[2];
	dst[1]=mat[1]*sp[0]+mat[4]*sp[1]+mat[7]*sp[2];
	dst[2]=mat[2]*sp[0]+mat[5]*sp[1]+mat[8]*sp[2];
}
void dynsinusoidal(float *mat, float *src, float *dst);
void dynsinusoidal(float *mat, float *src, float *dst)
{
    float	xp[3],sp[3];
    float	x,y,z,a,n;
    float	h,v;
    
    n=sqrt(src[0]*src[0]+src[1]*src[1]+src[2]*src[2]);
    xp[0] =src[0]/n; xp[1] =src[1]/n; xp[2] =src[2]/n;

    x = xp[0]*mat[0]+xp[1]*mat[1]+xp[2]*mat[2];
    y = xp[0]*mat[3]+xp[1]*mat[4]+xp[2]*mat[5];
    z = xp[0]*mat[6]+xp[1]*mat[7]+xp[2]*mat[8];

    y = acos(y);
    a = atan2(x,z);

    h = sin(y)*a;
    v = pi/2-y;
    
    sp[0]=h; sp[1]=v; sp[2]=n;
	
	dst[0]=mat[0]*sp[0]+mat[3]*sp[1]+mat[6]*sp[2];
	dst[1]=mat[1]*sp[0]+mat[4]*sp[1]+mat[7]*sp[2];
	dst[2]=mat[2]*sp[0]+mat[5]*sp[1]+mat[8]*sp[2];
}
void dynmercator(float *mat, float *src, float *dst);
void dynmercator(float *mat, float *src, float *dst)
{
    float	xp[3],sp[3];
    float	x,y,z,a,n;
    float	h,v;
    
    n=sqrt(src[0]*src[0]+src[1]*src[1]+src[2]*src[2]);
    xp[0] =src[0]/n; xp[1] =src[1]/n; xp[2] =src[2]/n;

    x = xp[0]*mat[0]+xp[1]*mat[1]+xp[2]*mat[2];
    y = xp[0]*mat[3]+xp[1]*mat[4]+xp[2]*mat[5];
    z = xp[0]*mat[6]+xp[1]*mat[7]+xp[2]*mat[8];

    y = acos(y);
    a = atan2(x,z);

    h = a;
    v = pi/2-y;
    
    sp[0]=h; sp[1]=v; sp[2]=n;
	
	dst[0]=mat[0]*sp[0]+mat[3]*sp[1]+mat[6]*sp[2];
	dst[1]=mat[1]*sp[0]+mat[4]*sp[1]+mat[7]*sp[2];
	dst[2]=mat[2]*sp[0]+mat[5]*sp[1]+mat[8]*sp[2];
}
-(void) projection
{
	float   mat[16],rmat[9],imat[9];
	float   vec[9];
	int		i;
	
	[self getRotationMatrix:mat];
	rmat[0]=mat[0]; rmat[1]=mat[1]; rmat[2]=mat[2];
	rmat[3]=mat[4]; rmat[4]=mat[5]; rmat[5]=mat[6];
	rmat[6]=mat[8]; rmat[7]=mat[9]; rmat[8]=mat[10];
	invMat(rmat,imat);
	for(i=0;i<9;i++) vec[i]=imat[i];
	
	switch(proj)
	{
		case 1: // stereographic
			for(i=0;i<nverts;i++) dynstereographic(vec,&verts[3*i],&vertsproj[3*i]);
			break;
		case 2: // sinusoidal
			for(i=0;i<nverts;i++) dynsinusoidal(vec,&verts[3*i],&vertsproj[3*i]);
			break;
		case 3: // mercator
			for(i=0;i<nverts;i++) dynmercator(vec,&verts[3*i],&vertsproj[3*i]);
			break;
	}
}

#pragma mark -
- (void)setZoom:(float)z
{
    zoom = pow(2,-z);
    [self setNeedsDisplay:YES];
}

#pragma mark -
- (void) savePicture
{
    NSRect	frame=[self bounds];
    NSBitmapImageRep *bmp=[[[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes:NULL
                                pixelsWide:frame.size.width
                                pixelsHigh:frame.size.height
                                bitsPerSample:8
                                samplesPerPixel:4
                                hasAlpha:YES
                                isPlanar:NO
                                colorSpaceName:NSCalibratedRGBColorSpace
                                bytesPerRow:0
                                bitsPerPixel:0] autorelease];
    NSImage *img;
    unsigned char *baseaddr=[bmp bitmapData];
    NSSavePanel *savePanel;
    int		result;
    
    [self getPixels:baseaddr width:frame.size.width height:frame.size.height rowbyte:[bmp bytesPerRow]];
    
    img = [[[NSImage alloc] init] autorelease];
    [img addRepresentation:bmp];
    [img setFlipped:YES];
    [img lockFocusOnRepresentation:bmp];
    [img unlockFocus];
    
    savePanel = [NSSavePanel savePanel];
    
    [savePanel setRequiredFileType:@"tif"];
    [savePanel setCanSelectHiddenExtension:YES];
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        NSString *filename=[savePanel filename];
        [[img TIFFRepresentation] writeToFile:filename atomically:YES];
    }
}
- (void) savePicture:(NSString *)filename
{
    NSRect	frame=[self bounds];
    NSBitmapImageRep *bmp=[[[NSBitmapImageRep alloc]
                                initWithBitmapDataPlanes:NULL
                                pixelsWide:frame.size.width
                                pixelsHigh:frame.size.height
                                bitsPerSample:8
                                samplesPerPixel:4
                                hasAlpha:YES
                                isPlanar:NO
                                colorSpaceName:NSCalibratedRGBColorSpace
                                bytesPerRow:0
                                bitsPerPixel:0] autorelease];
    unsigned char *baseaddr=[bmp bitmapData];
    NSImage *img;

    [self getPixels:baseaddr width:frame.size.width height:frame.size.height rowbyte:[bmp bytesPerRow]];
    
    img = [[[NSImage alloc] init] autorelease];
    [img addRepresentation:bmp];
    [img setFlipped:YES];
    [img lockFocusOnRepresentation:bmp];
    [img unlockFocus];
    
    [[img TIFFRepresentation] writeToFile:filename atomically:YES];
}

-(void) getPixels:(char*)baseaddr width:(long)w height:(long)h rowbyte:(long)rb
{
    glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,baseaddr);
}

@end
