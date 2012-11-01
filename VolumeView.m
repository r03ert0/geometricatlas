#import "VolumeView.h"
#import "AppController.h"

@implementation VolumeView
- (id) initWithFrame: (NSRect) frame
{
    // volumes are in horizontal slices
    // Axial, eyes up, L is at L, first slice superior
    // Sagital, nose to left, left first, superior up
    // Coronal, L at L, occipital first, superior up

    zoom=2;
    space=0;
    showTalairach=YES;

    fusion=0.5;
    thresh=5;
    a3D_light=1.5;
    a_light=0.4;
    f_light=20;
    
    tb.M[0]=128;tb.M[1]=128;tb.M[2]=128;
    tb.M[3]=1.0;tb.M[4]=0.0;tb.M[5]=0.0;
    tb.M[6]=0.0;tb.M[7]= -1;tb.M[8]=0.0;
    tb.M[9]=0.0;tb.M[10]= 0;tb.M[11]=-1;
    
    vol_setTransformMatrix(v0,128,128,128, 1,0,0, 0,1,0, 0,0,-1);
    vol_setTransformMatrix(v1,128,128,128, 0,1,0, 0,0,-1,1,0, 0);
    vol_setTransformMatrix(v2,128,128,128, 1,0,0, 0,0,-1,0,1, 0);

    //direct voxel to milimeters_____________________
    i2m[0]=128; i2m[1]=128; i2m[2]=128;
    i2m[3]=1;   i2m[4]=0;   i2m[5]=0;
    i2m[6]=0;   i2m[7]=1;   i2m[8]=0;	// (A)coronal: posterior to anterior
    i2m[9]=0;   i2m[10]=0;  i2m[11]=-1;	// (S)axial: inferior to superior
    //inverse____________________
    m2i[0]=i2m[0];	 m2i[1]=i2m[1];  m2i[2]=i2m[2];
    inverseMatrix(&i2m[3],&m2i[3]);

    return self = [super initWithFrame:frame];
}
- (BOOL) isFlipped
{
    return YES;
}
#pragma mark -
- (void) drawRect: (NSRect) rect
{
    NSBitmapImageRep	*bmp;
    unsigned char	*baseaddr;
    unsigned char	*a3data,*adata,*fdata;
    int			bytesPerRow;
    int			v,g;
    float		f;
    NSPoint		disp;
    NSRect		rsrc,rdst;
    NSImage		*img;
    float	*vw;
    float	S[3],A3[3],A[3],F[3],MM[3];
    int		x,y,z;
    
    if(!an3D.initialised)	return;

    switch(orient)
    {	case 0:	vw=v0; break;
        case 1:	vw=v1; break;
        case 2:	vw=v2; break;
    }
    bmp=[[[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes:NULL
                pixelsWide:256	pixelsHigh:256
                bitsPerSample:8	samplesPerPixel:3
                hasAlpha:NO	isPlanar:NO
                colorSpaceName:NSCalibratedRGBColorSpace
                bytesPerRow:0
                bitsPerPixel:0] autorelease];
    baseaddr=[bmp bitmapData];
    bytesPerRow=[bmp bytesPerRow];
    
    a3data=(unsigned char*)an3D.data;
    if(anat.data) adata=(unsigned char*)anat.data;
    if(func.data) fdata=(unsigned char*)func.data;

    z=slice*255;// slice on the screen
    for(x=0;x<256;x++) // x coordinate on the screen from L to R
    for(y=0;y<256;y++) // y coordinate on the screen from T to B
    {
        S[0]=x;S[1]=y;S[2]=z;
        vol_screenToMilimeters(S,MM,vw);
        vol_milimetersToVoxels(MM,A3,an3D.m2v);
        v=vol_getShortAt(an3D,A3);
        
        vol_milimetersToVoxels(MM,A,anat.m2v);
        g=vol_getShortAt(anat,A);
        vol_milimetersToVoxels(MM,F,func.m2v);
        f=vol_getFloatAt(func,F);

        v=a3D_light*v;
        v=v*(1-fusion)+(a_light*g)*fusion;
        f=f_light*f;

        if(fabs(f)>thresh*f_light)
        {   *(baseaddr+x*3+0+y*bytesPerRow)=(int)((f>=0)?f:0);
            *(baseaddr+x*3+1+y*bytesPerRow)=0;
            *(baseaddr+x*3+2+y*bytesPerRow)=(int)((f<0)?(-f):0);
        }
        else
        {   *(baseaddr+x*3+0+y*bytesPerRow)=(int)v;
            *(baseaddr+x*3+1+y*bytesPerRow)=(int)v;
            *(baseaddr+x*3+2+y*bytesPerRow)=(int)v;
        }
    }
    
    rsrc=NSMakeRect(0,0,255,255);
    [self displacement:&disp];
    rdst=NSMakeRect(disp.x,disp.y,255*zoom,255*zoom);

    img = [[[NSImage alloc] init] autorelease];
    [img addRepresentation:bmp];
    [img setFlipped:YES];
    [img lockFocusOnRepresentation:bmp];
    [img unlockFocus];
    [img drawInRect:rdst fromRect:rsrc operation:NSCompositeSourceOver fraction:1.0];
    
    if(showTalairach)
        [self drawTalairach];
}
-(void)displacement:(NSPoint*)di // displacement in pixels
{
    NSSize	s;
    NSPoint	ce;

    s=[self bounds].size;
    ce=NSMakePoint(s.width/2.0,s.height/2.0);
    *di=NSMakePoint(ce.x-(*di).x,ce.y-(*di).y);
    *di=NSMakePoint(ce.x-128*zoom,ce.y-128*zoom);
}
-(void)drawTalairach;
{
    NSPoint	di;
    NSAffineTransform *trans = [NSAffineTransform transform];

    [self displacement:&di];
    [trans translateXBy:di.x yBy:di.y];

    switch(orient)
    {
        case 0:
        { // use v0
            NSBezierPath *cen=[NSBezierPath alloc],
                         *res=[NSBezierPath alloc];
            NSColor	*red=[NSColor redColor];
            NSColor	*blue=[NSColor blueColor];
            
            [cen moveToPoint:NSMakePoint(tb.M[0]*zoom,0)];
            [cen lineToPoint:NSMakePoint(tb.M[0]*zoom,255*zoom)];
            [cen transformUsingAffineTransform: trans];
            [red set];
            [cen stroke];
            
            [res moveToPoint:NSMakePoint((tb.M[0]+61*tb.M[3])*zoom,0)];
            [res lineToPoint:NSMakePoint((tb.M[0]+61*tb.M[3])*zoom,255*zoom)];
            [res moveToPoint:NSMakePoint((tb.M[0]-61*tb.M[3])*zoom,0)];
            [res lineToPoint:NSMakePoint((tb.M[0]-61*tb.M[3])*zoom,255*zoom)];
            [res transformUsingAffineTransform: trans];
            [blue set];
            [res stroke];
            break;
        }
        case 1:
        { // use v1
            NSBezierPath *hdr=[NSBezierPath alloc],
                         *bdy=[NSBezierPath alloc],
                         *ac=[NSBezierPath alloc],
                         *vc=[NSBezierPath alloc];
            NSColor *red = [NSColor redColor],
                    *blue = [NSColor blueColor];
            int		R=3;
            NSRect ro;
            NSBezierPath *bro;
            NSRect re;
            NSBezierPath *bre;
            
            // header
            [hdr moveToPoint:NSMakePoint(zoom*(tb.M[1]+ 65*tb.M[7]+65*tb.M[10]),zoom*(tb.M[2]+ 65*tb.M[8]+65*tb.M[11]))];
            [hdr lineToPoint:NSMakePoint(zoom*(tb.M[1]-100*tb.M[7]+65*tb.M[10]),zoom*(tb.M[2]-100*tb.M[8]+65*tb.M[11]))];
            [hdr setLineWidth:3];
            [hdr transformUsingAffineTransform: trans];
            [red set];
            [hdr stroke];
            
            // body
            [bdy moveToPoint:NSMakePoint(zoom*(tb.M[1]-100*tb.M[7]+65*tb.M[10]),zoom*(tb.M[2]-100*tb.M[8]+65*tb.M[11]))];
            [bdy lineToPoint:NSMakePoint(zoom*(tb.M[1]-100*tb.M[7]-40*tb.M[10]),zoom*(tb.M[2]-100*tb.M[8]-40*tb.M[11]))];
            [bdy lineToPoint:NSMakePoint(zoom*(tb.M[1]+ 65*tb.M[7]-40*tb.M[10]),zoom*(tb.M[2]+ 65*tb.M[8]-40*tb.M[11]))];
            [bdy lineToPoint:NSMakePoint(zoom*(tb.M[1]+ 65*tb.M[7]+65*tb.M[10]),zoom*(tb.M[2]+ 65*tb.M[8]+65*tb.M[11]))];
            [bdy transformUsingAffineTransform: trans];
            [bdy stroke];
            
            // AC-PC line
            [ac moveToPoint:NSMakePoint(zoom*(tb.M[1]+ 65*tb.M[7]),zoom*(tb.M[2]+ 65*tb.M[8]))];
            [ac lineToPoint:NSMakePoint(zoom*(tb.M[1]-100*tb.M[7]),zoom*(tb.M[2]-100*tb.M[8]))];
            [ac transformUsingAffineTransform: trans];
            [ac stroke];
            
            // VAC line
            [vc moveToPoint:NSMakePoint(zoom*(tb.M[1]+65*tb.M[10]),zoom*(tb.M[2]+65*tb.M[11]))];
            [vc lineToPoint:NSMakePoint(zoom*(tb.M[1]-40*tb.M[10]),zoom*(tb.M[2]-40*tb.M[11]))];
            [vc transformUsingAffineTransform: trans];
            [vc stroke];
            
            // rotate
            ro=NSMakeRect(zoom*(tb.M[1]+ 65*tb.M[7]+65*tb.M[10])-R,zoom*(tb.M[2]+ 65*tb.M[8]+65*tb.M[11])-R,2*R,2*R);
            bro = [NSBezierPath bezierPathWithOvalInRect:ro];
            [bro transformUsingAffineTransform: trans];
            [blue set];
            [bro fill];
    
            // resize
            re=NSMakeRect(zoom*(tb.M[1]-100*tb.M[7]-40*tb.M[10])-R,zoom*(tb.M[2]-100*tb.M[8]-40*tb.M[11])-R,2*R,2*R);
            bre = [NSBezierPath bezierPathWithRect:re];
            [bre transformUsingAffineTransform: trans];
            [blue set];
            [bre fill];
            break;
        }
    }
}

#pragma mark -
#pragma mark [   interactive normalisation   ]
-(void)mouseDown:(NSEvent*)event
{
    NSPoint	m=[self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint	di;
    float	T[3],M[3],S[3],Tal[12],iTal[12];
    float	*vw;
    int	i;
    
    if(showTalairach)	// if talairach box is displayed, verify hits
    {
        int		where;
        
        switch(orient)
        {
            case 0:
                where=[self hitAxiTalairach:m];
                switch(where)
                {
                    case 1:	[self dragAxiTranslate:m];	break;
                    case 2:	[self dragAxiResize:m];		break;
                }
                break;
            case 1:
                where=[self hitSagTalairach:m];
                switch(where)
                {
                    case 1:	[self dragSagResize:m];	break;
                    case 2:	[self dragSagTurn:m];	break;
                    case 3:	[self dragSagHeader:m];	break;
                }
                break;
            case 2:	break;
        }
        [self configureInverseTalairachMatrix];
    }
    // transform mm clicks in talairach coordinates
    printf("_____\n");
    m.x/=zoom;m.y/=zoom;

    [self displacement:&di];
    di.x/=zoom; di.y/=zoom;	// displacement in mm
    switch(orient)
    {
        case 0:	M[0]=m.x-tb.M[0]-di.x;
                M[1]=m.y-tb.M[1]-di.y;
                M[2]=slice*255-tb.M[2];
                vw=v0;
                break;
        case 1: M[0]=slice*255-tb.M[0];
                M[1]=m.x-tb.M[1]-di.x;
                M[2]=m.y-tb.M[2]-di.y;
                vw=v1;
                break;
        case 2: vw=v2;
                break;
    }
    
    // click to milimeters
    [self displacement:&di];
    di.x/=zoom; di.y/=zoom;
    S[0]=m.x-di.x; S[1]=m.y-di.y; S[2]=slice*255;
    vol_screenToMilimeters(S,M,vw);
    
    // milimeters-based Talairach matrices
    for(i=0;i<12;i++) Tal[i]=tb.M[i];
    vol_indexToMilimeters(tb.M,Tal,i2m);
    for(i=5;i<12;i+=3) Tal[i]*=-1; //quick&dirty rotation by i2m=100 010 00(-1)
    for(i=0;i<3;i++) iTal[i]=Tal[i];
    inverseMatrix(&Tal[3],&iTal[3]);

    // clik-mm to Talairach
    vol_milimetersToTalairach(M,T,iTal);
    printf("tal:%f %f %f\n",T[0],T[1],T[2]);
}
-(int)hitAxiTalairach:(NSPoint)m // m=mouse in mm
{
    float	R=3/zoom;
    int		hit=0;
    NSPoint	di;

    m.x/=zoom;	m.y/=zoom;
    [self displacement:&di];
    di.x/=zoom; di.y/=zoom;	// displacement in mm
    
    if(fabs(di.x+tb.M[0]-m.x)<R)
        hit=1;
    else
    if(fabs(di.x+tb.M[0]+61*tb.M[3]-m.x)<R||fabs(di.x+tb.M[0]-61*tb.M[3]-m.x)<R)
    {
        hit=2;
        printf("hit\n");
    }
    
    return hit;
}
-(void)dragAxiTranslate:(NSPoint)p
{
    NSEvent	*e;
    NSPoint	di;
    [self displacement:&di];
    
    do{
        e = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        p=[self convertPoint:[e locationInWindow] fromView:nil];

        tb.M[0]=(p.x-di.x)/zoom;
        
        [self setNeedsDisplay:YES];
        if([e type]==NSLeftMouseUp)
            break;
    }while(1);

}
-(void)dragAxiResize:(NSPoint)p
{
    NSEvent	*e;
    NSPoint	di;
    [self displacement:&di];

    do{
        e = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        p=[self convertPoint:[e locationInWindow] fromView:nil];

        tb.M[3]=fabs((p.x-di.x)/zoom-tb.M[0])/61.0;
        
        [self setNeedsDisplay:YES];
        if([e type]==NSLeftMouseUp)
            break;
    }while(1);
}

-(int)hitSagTalairach:(NSPoint)m;
{
    NSRect	re,ro;
    int		R=3;
    float	A[2],B[2];
    int		hit=0;
    float	d;
    NSPoint	di;
    [self displacement:&di];

    // in resize, in rotate
    re=NSMakeRect(di.x+zoom*(tb.M[1]-100*tb.M[7]-40*tb.M[10])-R,di.y+zoom*(tb.M[2]-100*tb.M[8]-40*tb.M[11])-R,2*R,2*R);
    ro=NSMakeRect(di.x+zoom*(tb.M[1]+ 65*tb.M[7]+65*tb.M[10])-R,di.y+zoom*(tb.M[2]+ 65*tb.M[8]+65*tb.M[11])-R,2*R,2*R);
    if([self mouse:m inRect:re])
    {
        hit=1;
        printf("hit\n");
    }
    else
    if([self mouse:m inRect:ro])
        hit=2;
    else
    {
        A[0]=zoom*165*tb.M[7];
        A[1]=zoom*165*tb.M[8];
        B[0]=m.x-di.x-zoom*(tb.M[1]+65*tb.M[7]+65*tb.M[10]);
        B[1]=m.y-di.y-zoom*(tb.M[2]+65*tb.M[8]+65*tb.M[11]);
        d=A[0]*A[0]+A[1]*A[1];
        
        d=sqrt(	pow(B[0]-(A[0]*B[0]+A[1]*B[1])*A[0]/d,2)+
                        pow(B[1]-(A[0]*B[0]+A[1]*B[1])*A[1]/d,2));
        if(d<R)
            hit=3;
    }
    
    return hit;
}
-(void)dragSagResize:(NSPoint)p
{
    NSPoint	p0=p,o0,c0,a0;
    double	cd,ad,cn2,an2;
    NSEvent	*e;
    
    o0.x=tb.M[1];
    o0.y=tb.M[2];
    c0.x=tb.M[7];
    c0.y=tb.M[8];
    cn2=c0.x*c0.x+c0.y*c0.y;
    a0.x=tb.M[10];
    a0.y=tb.M[11];
    an2=a0.x*a0.x+a0.y*a0.y;

    do{
        e = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        p=[self convertPoint:[e locationInWindow] fromView:nil];

        cd=(c0.x*(p.x-p0.x)+c0.y*(p.y-p0.y))/zoom/cn2;
        tb.M[7]=c0.x*(1-cd/165.0);
        tb.M[8]=c0.y*(1-cd/165.0);

        ad=(a0.x*(p.x-p0.x)+a0.y*(p.y-p0.y))/zoom/an2;
        tb.M[10]=a0.x*(1-ad/105.0);
        tb.M[11]=a0.y*(1-ad/105.0);
        
        tb.M[1]=o0.x+c0.x*65*cd/165.0+a0.x*65*ad/105.0;
        tb.M[2]=o0.y+c0.y*65*cd/165.0+a0.y*65*ad/105.0;
        
        [self setNeedsDisplay:YES];
        if([e type]==NSLeftMouseUp)
            break;
    }while(1);
}
-(void)dragSagTurn:(NSPoint)p
{
    NSEvent	*e;
    NSPoint	o0,c0,a0;
    NSPoint	o=p;
    double	a=0;
    
    o0.x=tb.M[1];
    o0.y=tb.M[2];
    c0.x=tb.M[7];
    c0.y=tb.M[8];
    a0.x=tb.M[10];
    a0.y=tb.M[11];
    do{
        e = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        p=[self convertPoint:[e locationInWindow] fromView:nil];

        a += (o.x - p.x)/100.0/zoom;
        tb.M[7]= c0.x*cos(a)-c0.y*sin(a);
        tb.M[8]= c0.x*sin(a)+c0.y*cos(a);
        tb.M[10]=a0.x*cos(a)-a0.y*sin(a);
        tb.M[11]=a0.x*sin(a)+a0.y*cos(a);
        
        tb.M[1]=o0.x+65*(c0.x-c0.x*cos(a)+c0.y*sin(a))+65*(a0.x-a0.x*cos(a)+a0.y*sin(a));
        tb.M[2]=o0.y+65*(c0.y-c0.x*sin(a)-c0.y*cos(a))+65*(a0.y-a0.x*sin(a)-a0.y*cos(a));
        
        o.x=p.x;
                    
        [self setNeedsDisplay:YES];
        if([e type]==NSLeftMouseUp)
            break;
    }while(1);
}
-(void)dragSagHeader:(NSPoint)p
{
    NSEvent	*e;
    NSPoint	o=p;
    do{
        e = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        p=[self convertPoint:[e locationInWindow] fromView:nil];

        tb.M[1] += (p.x-o.x)/zoom;
        tb.M[2] += (p.y-o.y)/zoom;
        o=p;
                    
        [self setNeedsDisplay:YES];
        if([e type]==NSLeftMouseUp)
            break;
    }while(1);
}
#pragma mark -
-(void)setTalairachMatrix:(float*)TM
{
    int	i;
    
    for(i=0;i<12;i++)
        tb.M[i]=TM[i];
}
-(void)getTalairachMatrix:(float*)TM
{
    int	i;
    for(i=0;i<12;i++) TM[i]=tb.M[i];
}
-(void)configureInverseTalairachMatrix
{
    int	i;
    
    inverseMatrix(&tb.M[3],&tb.iM[3]);
    for(i=0;i<3;i++)
        tb.iM[i]=tb.M[i];
}
#pragma mark -
#pragma mark [   volume   ]
-(void)setAnat3DVolume:(VolumeDescription)v
{
    an3D=v;
    an3D.initialised=TRUE;
}
-(void)setAnatVolume:(VolumeDescription)v
{
    anat=v;
    anat.initialised=TRUE;
}
-(void)setFuncVolume:(VolumeDescription)v
{
    func=v;
    func.initialised=TRUE;
}
-(void)setOrientation:(int)o
{
    orient=o;
    [self setNeedsDisplay:YES];
}
-(void)setSlice:(float)s
{
    slice=s;
    [self setNeedsDisplay:YES];
}
-(void)setZoom:(float)z
{
    zoom=z;
    [self setNeedsDisplay:YES];
}
-(void)setSpace:(int)t
{
    space=t;
    [self setNeedsDisplay:YES];
}
-(void)showTalairach:(BOOL)flag
{
    showTalairach=flag;
    [self setNeedsDisplay:YES];
}

-(void)setThreshold:(float)t
{
    thresh=t;
    [self setNeedsDisplay:YES];
}
-(void)setFusion:(float)t
{
    fusion=t;
    [self setNeedsDisplay:YES];
}
-(void)setLight:(float)t vol:(int)i
{
    switch(i)
    {
        case 1:	a3D_light=t;	break;
        case 2:	a_light=t;	break;
        case 3:	f_light=t;	break;
    }
    [self setNeedsDisplay:YES];
}
-(void)setOrigin:(float*)o vol:(int)i;
{
    switch(i)
    {
        case 1:	an3D.orig[0]=o[0]; an3D.orig[1]=o[1]; an3D.orig[2]=o[2];
                vol_configureTransformationMatrices(&an3D); break;
        case 2:	anat.orig[0]=o[0]; anat.orig[1]=o[1]; anat.orig[2]=o[2];
                vol_configureTransformationMatrices(&anat); break;
        case 3:	func.orig[0]=o[0]; func.orig[1]=o[1]; func.orig[2]=o[2];
                vol_configureTransformationMatrices(&func); break;
    }
    [self setNeedsDisplay:YES];
}
-(void)setVoxelDimension:(float*)v vol:(int)i;
{
    switch(i)
    {
        case 1:	an3D.pdim[0]=v[0]; an3D.pdim[1]=v[1]; an3D.pdim[2]=v[2];
                vol_configureTransformationMatrices(&an3D); break;
        case 2:	anat.pdim[0]=v[0]; anat.pdim[1]=v[1]; anat.pdim[2]=v[2];
                vol_configureTransformationMatrices(&anat); break;
        case 3:	func.pdim[0]=v[0]; func.pdim[1]=v[1]; func.pdim[2]=v[2];
                vol_configureTransformationMatrices(&func); break;
    }
    [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark [   save func as Talairach   ]
-(void)saveActivation
{
    // works only for axial (orient==0)
    int iter;
    int	x,y,z;
    int	i,j,k;
    float f,T[3],M[3];
    unsigned char *fdata;
    char str[256];
    char *cstr;
    int	size=0;
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSString	*filename;
    int		result;

    fdata=(unsigned char*)func.data;

    for(iter=0;iter<2;iter++)
    {
        if(iter==1)	cstr=calloc(size,sizeof(char));
        size=0;

        for(x=0;x<func.dim[0];x++)
        for(y=0;y<func.dim[1];y++)
        for(z=0;z<func.dim[2];z++)
        {
            f=floatAt(fdata     +x*sizeof(float)
                                +y*func.dim[0]*sizeof(float)
                                +z*func.dim[0]*func.dim[1]*sizeof(float),
                func.littleEndian);
            if(f>thresh)
            {
                i=((x-func.orig[0])*func.pdim[0]/an3D.pdim[0]+ an3D.orig[0])*an3D.pdim[0];
                j=((an3D.dim[1]-1-(func.dim[1]-y-1-func.orig[1])*func.pdim[1]/an3D.pdim[1]-an3D.orig[1]))*an3D.pdim[1];
                k=((func.dim[2]-z-1-func.orig[2])*func.pdim[2]/an3D.pdim[2]+an3D.orig[2])*an3D.dim[2]/(an3D.dim[2]-1)*an3D.pdim[2];
                M[0]= i-tb.M[0];
                M[1]= j-tb.M[1];
                M[2]= k-tb.M[2];
                
                milimetersToTalairach(M,T,tb.iM);
                if(iter==0)	size+=sprintf(str,"%f %f %f\n",T[0],T[1],T[2]);
                else		size+=sprintf(&cstr[size],"%f %f %f\n",T[0],T[1],T[2]);
            }
        }
    }
    
    // save
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        NSString *s;
    
        filename=[savePanel filename];
        s=[[NSString alloc] initWithUTF8String:cstr];// length:size];
        [s writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

#pragma mark -
#pragma mark [   project on mesh   ]
-(void)projectFunctionalHemisphere:(int)hemisphere inVertices:(float*)txtr
// functional activity is projected by computing the distance from each
// vertex in the mesh to the voxel cube's points, edges and faces
{
    float	*verts,*M;
    float	tal[3];
    int		a,b,c,i,j,k,nverts,na;
    //                    0      1      2      3      4      5      6      7
    int		cub[8*3]={0,0,0, 1,0,0, 0,1,0, 1,1,0, 0,0,1, 1,0,1, 0,1,1, 1,1,1};
    int		edg[12*2]={ 0,1, 0,2, 0,4,
                            5,1, 5,4, 5,7,
                            3,2, 3,7, 3,1,
                            6,7, 6,4, 6,2};
    float	Tal[12],iTal[12],m[3],mf[3],v[3],am[8][3];
    int		*activ;
    float	d,d0,dist=4;
    
    // store together all active voxels
    activ=(int*)calloc(func.dim[0]*func.dim[1]*func.dim[2],3*sizeof(int));
    na=0;
    for(a=0;a<func.dim[0];a++)
    for(b=0;b<func.dim[1];b++)
    for(c=0;c<func.dim[2];c++)
    {
        v[0]=a;v[1]=b;v[2]=c;
        if(vol_getFloatAt(func,v)>=thresh)
        {
            activ[3*na+0]=a;
            activ[3*na+1]=b;
            activ[3*na+2]=c;
            na++;
        }
    }

    // milimeters-based Talairach matrices
    for(i=0;i<12;i++) Tal[i]=tb.M[i];
    vol_indexToMilimeters(tb.M,Tal,i2m);
    for(i=5;i<12;i+=3) Tal[i]*=-1; //quick&dirty rotation by i2m=100 010 00(-1)
    for(i=0;i<3;i++) iTal[i]=Tal[i];
    inverseMatrix(&Tal[3],&iTal[3]);

    // walk through the vertices of the mesh
    nverts=(int)[[NSApp delegate] getMeshVerticesNumber];
    verts=(float*)[[NSApp delegate] getMeshVertices];
    M=(float*)[[NSApp delegate] getMeshNormalisationMatrix];
    for(i=0;i<nverts;i++)
    {
        if(i%1000==0) printf("vertex:%i\n",i);

        tal_getTalairachFromPoint(tal,&verts[i*3],M);
        if(hemisphere==0)    tal[0]*=-1;	//0:Left, 1:Right
        vol_talairachToMilimeters(tal,m,Tal);

        for(j=0;j<na;j++)
        {
            for(k=0;k<8;k++)
            {
                v[0]=activ[3*j+0]+cub[k*3+0];
                v[1]=activ[3*j+1]+cub[k*3+1];
                v[2]=activ[3*j+2]+cub[k*3+2];

                vol_voxelsToMilimeters(v,mf,func.v2m);

                am[k][0]=mf[0];
                am[k][1]=mf[1];
                am[k][2]=mf[2];
            }
            for(k=0;k<12;k++)
            {
                d0=distancePointSegment(m,am[edg[k*2+0]],am[edg[k*2+1]]);
                //d0=sqrt(pow(mf[0]-m[0],2)+pow(mf[1]-m[1],2)+pow(mf[2]-m[2],2));
                if(k==0) d=d0;
                else
                if(d0<d) d=d0;
            }
            
            if(d<dist && (txtr[i]==-1 || txtr[i]<1-d/dist))
                txtr[i]=1-d/dist;
        }
    }
}
@end

/*
The `*.mat' file

This simply contains a 4x4 affine transformation matrix in a variable `M'. These files are normally generated
by the `realignment' and `coregistration' modules. What these matrixes contain is a mapping from the voxel
coordinates (x0,y0,z0) (where the first voxel is at coordinate (1,1,1)), to coordinates in millimeters
(x1,y1,z1).By default, the the new coordinate system is derived from the `origin' and `vox' fields of the image
header.

x1 = M(1,1)*x0 + M(1,2)*y0 + M(1,3)*z0 + M(1,4)
y1 = M(2,1)*x0 + M(2,2)*y0 + M(2,3)*z0 + M(2,4)
z1 = M(3,1)*x0 + M(3,2)*y0 + M(3,3)*z0 + M(3,4)

Assuming that image1 has a transformation matrix M1, and image2 has a transformation matrix M2, the mapping from
image1 to image2 is: M2\M1 (ie. from the coordinate system of image1 into millimeters, followed by a mapping from
millimeters into the space of image2).

These `.mat' files allow several realignment or coregistration steps to be combined into a single operation
(without the necessity of resampling the images several times). The `.mat' files are also used by the spatial
normalisation module.
*/