//
//  MyDocument.m
//  Geometric Atlas Cocoa
//
//  Created by roberto on Sat Sep 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"
#import "AppController.h"
@implementation MyDocument

- (id)init
{
    [super init];
    if (self)
    {
        int	i;
        float	m[]=
        {   0.7,	0.700,			-0.1,			// origin
            -0.027,	0,				0,				// sagital: medial to lateral
            0,		0.0248628072,	0.0070160865,	// coronal: posterior to frontal
            0,		-0.0070160865,	0.0248628072};	// axial: inferior to superior
            
        path_mesh_original= @"/original.3dmf";
        path_mesh_smoothed= @"/smooth.3dmf";
        path_mesh_spherical=@"/spherical.3dmf";
        
        path_vf1_depth=	    @"/sulcal_depth.vf1";
        path_vf1_curvature= @"/curvature.vf1";
        
        path_vf3_gm=	    @"/geometric_model.vf3";
        path_img_gm=	    @"/gm.tif";
        path_img_gmsulci=   [[NSString alloc] initWithString:@"/gm_sulc.tif"];
        path_img_gmbrodman= [[NSString alloc] initWithString:@"/gm_brodman.tif"];
    
        for(i=0;i<12;i++) MatrixTalairachToMeshSpace[i]=m[i];
        
        DistanceTalairach=10;
        RadiusStereographic=512;
        vertscolour=NULL;
        
        selectedMesh=0;
        selectedVerticesData=0;
        
        initColourmaps();
    }
    return self;
}
- (void) awakeFromNib
{
}
- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [self awakeGA];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
    return YES;
}

#pragma mark -
#pragma mark [  general mesh handling  ]
//-----------------------------------------------------
//-----------------------------------------------------
- (IBAction) openMesh: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*filename;
    int		result;
    
    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        filename=[[openPanel filenames] objectAtIndex:0];
        [self openMesh:mesh fromFile:filename];
        [self setMesh:mesh];       
    }
}
- (void) openMesh:(MeshRec*)m fromFile:(NSString*)filename
{
    char	*data;
	NSString *str=[NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    
    data=(char*)[str UTF8String];
	
    
    msh_parse3DMFText(m,data);
}
- (IBAction) saveMesh: (id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSString	*filename;
    int		result;
    
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        char	*data;
        NSString *s;
    
        filename=[savePanel filename];
        msh_pack3DMF(mesh,&data);
        s=[[NSString alloc] initWithUTF8String:data];
        [s writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[s release];
    }
}
-(void) setMesh:(MeshRec*)m
{
    mesh=m;
    [openGLView setVertices:(float *)msh_getPointsPtr(m) number:(*m).np];
    [openGLView setTriangles:(int *)msh_getTrianglesPtr(m) number:(*m).nt];
    [openGLView setNeedsDisplay:YES];
}
- (IBAction) meshAction: (id) sender
{
    int tag=[sender indexOfSelectedItem];
    printf("mesh action %d\n",tag);
    
    switch(tag)
    {
        case 0:	//smooth
            if(mesh)
            {
                int	i;
                for(i=0;i<1;i++)
                em_smooth(mesh);
                [openGLView setVertices:(float *)msh_getPointsPtr(mesh) number:(*mesh).np];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 1: //inflate
            if(mesh)
            {
                em_inflate(mesh);
                [openGLView setVertices:(float *)msh_getPointsPtr(mesh)  number:(*mesh).np];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 2: //scale
            if(mesh)
            {
                em_scale(mesh);
                [openGLView setVertices:(float *)msh_getPointsPtr(mesh)  number:(*mesh).np];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 3: //simplify
            break;
        case 4: //pickpoint
            break;
    }
}
#pragma mark -
//-----------------------------------------------------
//-----------------------------------------------------
- (IBAction) openVerticesData: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*filename;
    int		result;
    
    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        filename=[[openPanel filenames] objectAtIndex:0];
        [self openVerticesData:&vf1_back fromFile:filename];
        [self setVerticesData];
    }
}
- (void) openVerticesData:(float**)vdat fromFile:(NSString*) filename
{
    char	*data;
    int		size;
	NSData	*str=[NSData dataWithContentsOfFile:filename];
    NSString	*ext=[filename pathExtension];
    int		dim=1;
    
    data=(char*)[str bytes];
    size=[str length];
    if([ext isEqualToString:@"vf1"])	dim=1;
    else
    if([ext isEqualToString:@"vf2"])	dim=2;
    else
    if([ext isEqualToString:@"vf3"])	dim=3;
    
    msh_parseVerticesDataBin(vdat,dim,(*mesh).np,data,size);
}
- (IBAction) saveVerticesData: (id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSString	*filename;
    int		result;
    
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        char	*data;
        int	length;
        NSData	*d;

        filename=[savePanel filename];
        length=msh_packVerticesData(vf1_back,1,(*mesh).np,&data);
        d=[[NSData alloc] initWithBytesNoCopy:data length:length];
        [d writeToFile:filename atomically:YES];
		[d release];
    }
}
-(void) setVerticesData
{
    int		i;
    float	c[3];
    int		colourmap_back=0, colourmap_front;
    AppController	*ac=(AppController*)[NSApp delegate];
    
    switch(selectedVerticesData)
    {
        case 0:colourmap_back=0;break;	// continuous grayscale
        case 1:colourmap_back=2;break;	// continuous red/green
    }
    colourmap_front=[ac getColourmap];

    // transform 1D vertsdata to 3D vertscolour = colourmap(vertsdata)
    if(vertscolour==NULL)
        vertscolour=(float*)calloc(3*mesh_original.np,sizeof(float));
    for(i=0;i<mesh_original.np;i++)
    {
        if(vf1_front!=NULL && vf1_front[i]>=0)
        {
            colourFromColourmap(vf1_front[i], c, colourmap_front);
            vertscolour[3*i+0]=c[0];
            vertscolour[3*i+1]=c[1];
            vertscolour[3*i+2]=c[2];
        }
        else
        {
            colourFromColourmap(vf1_back[i], c, colourmap_back);
            vertscolour[3*i+0]=c[0];
            vertscolour[3*i+1]=c[1];
            vertscolour[3*i+2]=c[2];
        }
    }
    [openGLView setVerticesColour:vertscolour];
    [openGLView setNeedsDisplay:YES];
}
- (IBAction) verticesDataAction: (id) sender
{
    int tag=[sender indexOfSelectedItem];
    printf("texture action %d\n",tag);
    
    switch(tag)
    {
        case 0:	//sulcal depth
            if(mesh)
            {
                em_textureDepth(mesh, vf1_back);
                [self setVerticesData];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 1: //mean curvature
            if(mesh)
            {
                em_textureMeanCurvature(mesh, vf1_back);
                [self setVerticesData];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 2: //integrated mean curvature
            if(mesh)
            {
                em_textureIntegratedMeanCurvature(mesh, vf1_back,50); // fixed to 50 iterations
                [self setVerticesData];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 3: //Area
			if(mesh)
			{
				[self projectAreaOnGeometricModel:mesh];
			}
            break;
        case 4: //laplace coordinates
            if(mesh)
            {
                em_textureCoordinatesFE(mesh);
                [openGLView setVerticesColour:(float *)msh_getTexturePtr(mesh)];
                [openGLView setNeedsDisplay:YES];
            }
            break;
        case 5: //noise
            break;
        case 6: //reaction-diffusion
            break;
        case 7: //distortion
            if(mesh)
            {
                em_textureDistortion(mesh, &mesh_original, vf1_back);
                [self setVerticesData];
                [openGLView setNeedsDisplay:YES];
            }
            break;
    }
}
#pragma mark -
-(void) setTextureActive:(BOOL)hasTxtr
{
    [openGLView setTextureActive:hasTxtr];
}
#pragma mark -
- (IBAction) setStandardRotation: (id) sender
{
    int view=[sender selectedTag];
    [openGLView setStandardRotation:view];
}
- (IBAction) setRotationX: (id) sender
{
    float	ang=[sender doubleValue];
    
    [openGLView setRotationX:ang];
}
- (IBAction) setRotationY: (id) sender
{
    float	ang=[sender doubleValue];
    
    [openGLView setRotationY:ang];
}
- (IBAction) setRotationZ: (id) sender
{
    float	ang=[sender doubleValue];
    
    [openGLView setRotationZ:ang];
}
#pragma mark -
- (IBAction) setZoom: (id) sender
{
    [openGLView setZoom:[sender floatValue]];
}
#pragma mark -
#pragma mark [  surface tab  ]
//--------------------------------------------------------------------------------
// Geometric Atlas methods (must create an object that inherits from editmesh...)
//--------------------------------------------------------------------------------
- (IBAction) changeMesh: (id) sender
{
    selectedMesh=[sender indexOfSelectedItem];
    
    switch(selectedMesh)
    {
        case 0:[self setMesh:&mesh_original];	break;
        case 1:[self setMesh:&mesh_smoothed];	break;
        case 2:[self setMesh:&mesh_spherical];	break;
    }
}
- (IBAction) changeProjection: (id) sender
{
    int selectedProjection=[sender indexOfSelectedItem];
    [openGLView setProjection:selectedProjection];
}
- (IBAction) changeVerticesData: (id) sender
{
    selectedVerticesData=[sender indexOfSelectedItem];
    
    switch(selectedVerticesData)
    {
        case 0:vf1_back=vf1_sulcalDepth;	break;
        case 1:vf1_back=vf1_curvature;		break;
    }
    [self setVerticesData];
}
- (IBAction)changeGMTexture: (id) sender
{
    int	selectedTexture=[sender indexOfSelectedItem];

    switch(selectedTexture)
    {
        case 0:[self setTextureActive:NO];		break;
        case 1:
		{
			NSString	*str=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:path_img_gm];
			if(bmp_gm)
				[bmp_gm release];
			bmp_gm=[[NSBitmapImageRep imageRepWithContentsOfFile:str] retain];
			[self setGMPicture];
			[self initGMTexture:bmp_gm];
			[self setTextureActive:YES];
			break;
		}
        case 2:
		{
			NSString	*str=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:path_img_gmbrodman];
			if(bmp_gm)
				[bmp_gm release];
			bmp_gm=[[NSBitmapImageRep imageRepWithContentsOfFile:str] retain];
			[self setGMPicture];
			[self initGMTexture:bmp_gm];
			[self setTextureActive:YES];
			break;
		}
        case 3:
		{
			NSString	*str=[[[NSBundle mainBundle] resourcePath] stringByAppendingString:path_img_gmsulci];
			if(bmp_gm)
				[bmp_gm release];
			bmp_gm=[[NSBitmapImageRep imageRepWithContentsOfFile:str] retain];
			[self setGMPicture];
			[self initGMTexture:bmp_gm];
			[self setTextureActive:YES];
			break;
		}
    }
}
-(void) awakeGA
{
    appPath=[[NSBundle mainBundle] resourcePath];
	
	img_array=[NSMutableArray new];

    printf("loading\n");
    
	// open all meshes and vertices data,
    // awake with the original model and sulcal depth vertices data
    printf("\tmesh original\n");
    [self openMesh:&mesh_original fromFile:[appPath stringByAppendingString:path_mesh_original]];

    printf("\tmesh smoothed\n");  
    [self openMesh:&mesh_smoothed fromFile:[appPath stringByAppendingString:path_mesh_smoothed]];
    printf("\tmesh spherical\n");  
    [self openMesh:&mesh_spherical fromFile:[appPath stringByAppendingString:path_mesh_spherical]];     
    [self setMesh:&mesh_original];
    printf("	vertices data sulcal depth\n");
    [self openVerticesData:&vf1_sulcalDepth fromFile:[appPath stringByAppendingString:path_vf1_depth]];     
    printf("	vertices data curvature\n");
    [self openVerticesData:&vf1_curvature fromFile:[appPath stringByAppendingString:path_vf1_curvature]];
    vf1_back=vf1_sulcalDepth;
    [self setVerticesData];
    
    // geometric model mesh and pictures
    printf("	mesh geometric model\n");
    [self openVerticesData:&vf3_gm fromFile:[appPath stringByAppendingString:path_vf3_gm]];
    printf("	picture geometric model\n");
    bmp_gm=[[NSBitmapImageRep imageRepWithContentsOfFile:[appPath stringByAppendingString:path_img_gm]] retain];
    [self setGMPicture];
    [self initGMParametrisation];
    [self initGMTexture:bmp_gm];
    [self setTextureActive:NO];
}
-(void) initGMParametrisation
{
    int		i;
    float3D	p;
    float3D	*gm=(float3D*)vf3_gm;
    float	a,b;
    double2D	x;
    
    // setup parametrisation
    param=(float*)calloc((*mesh).np,sizeof(float)*2);
    for(i=0;i<(*mesh).np;i++)
    {
        p=em_getPointFromSphericalCoordinate(gm[i]);
        a=acos(p.z);
        b=atan2(p.y,p.x);
        x=sca2D((double2D){cos(b),sin(b)},a*0.5/pi);
        param[i*2]=x.x+0.5;
        param[i*2+1]=0.5-x.y;
    }
    [openGLView setParam:param];
}
-(void) initGMTexture:(NSBitmapImageRep*)imgRep
{
    int			i,j;
    NSSize		s={512,512};
    unsigned char	*data=[imgRep bitmapData];
    int			bitsPerPixel=[imgRep bitsPerPixel];
    int			b=bitsPerPixel>>3;

    printf("bitsPerPixel: %i\n",bitsPerPixel);
    // setup texture
    image=calloc(3*s.width*s.height,sizeof(GLubyte));
    for(j=0;j<s.height;j++)
    for(i=0;i<s.width;i++)
    {
        image[(int)(j*s.height+i)*3+0]=data[(int)(j*s.height+i)*b+0]&0xff;
        image[(int)(j*s.height+i)*3+1]=data[(int)(j*s.height+i)*b+1]&0xff00>>8;
        image[(int)(j*s.height+i)*3+2]=data[(int)(j*s.height+i)*b+2]&0xff0000>>16;
    }
        
    [openGLView setTexture:image size:s];
}
-(int)getMeshVerticesNumber
{
    return (*mesh).np;
}
- (float*)getMeshVertices
{
    return (float*)(*mesh).p;
}
- (float*)getMeshVerticesColor
{
    return vf1_back;
}
- (float*)getMeshNormalisationMatrix
{
    return MatrixTalairachToMeshSpace;
}
#pragma mark -
#pragma mark [  volume tab  ]
//--------------------------------------------------------------------------------
// Volume methods
//--------------------------------------------------------------------------------
-(IBAction)openVolume:(id)sender
{
    int	tag=(int)[[NSApp delegate] getVolumeType];
    switch(tag)
    {
        case 0: [self openAnatomical:&an3D];
                [volView setAnat3DVolume:an3D];break;
        case 1: [self openAnatomical:&anat];
                [volView setAnatVolume:anat];break;
        case 2: [self openFunctional:&func];
                [volView setFuncVolume:func];break;
    }
    [volView setNeedsDisplay:YES];
}
-(void)openAnatomical:(VolumeDescription*)v
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*path;
    int		result;
    
    printf("open anatomical\n");

    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        path=[[openPanel filenames] objectAtIndex:0];
        [self openAnatomicalData:v path:path];
    }
}
-(void)openFunctional:(VolumeDescription*)v
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*path;
    int		result;
    
    printf("open functional\n");

    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        path=[[openPanel filenames] objectAtIndex:0];
        [self openFunctionalData:v path:path];
    }
}
-(IBAction)saveActivation:(id)sender
{
    [volView saveActivation];
}
-(IBAction)changeOrientation:(id)sender
{
    [volView setOrientation:[sender selectedTag]];
}
-(IBAction)changeSlice:(id)sender
{
    float t=[sender floatValue];
    [volView setSlice:t];
    [[NSApp delegate] setSliceFloatValue:t];
}
-(IBAction)changeSpace:(id)sender
{
    [volView setSpace:[sender selectedTag]];
}
-(IBAction)showTalairach:(id)sender
{
    [volView showTalairach:[sender intValue]];
}
-(IBAction)applyCommands:(id)sender
{
    NSString	*s;
    const char	*c;
    NSRange	r;	//location, length
    float	funcThreshold;
    float	fusion;
    float	zoom;
    float	light;
    float	orig[3];
    float	vdim[3];

    s=[[NSApp delegate] getCommandsString];
    c=[s UTF8String];

    r=[s rangeOfString:@"fusion:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&fusion);
        [volView setFusion:fusion];}

    r=[s rangeOfString:@"funcThreshold:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&funcThreshold);
        [volView setThreshold:funcThreshold];}
    
    r=[s rangeOfString:@"zoom:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&zoom);
        [volView setZoom:zoom];}
    
    //---------------------------------- set light
    r=[s rangeOfString:@"a3D_light:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&light);
        [volView setLight:light vol:1];}
    r=[s rangeOfString:@"a_light:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&light);
        [volView setLight:light vol:2];}
    r=[s rangeOfString:@"f_light:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f",&light);
        [volView setLight:light vol:3];}
    
    //---------------------------------- set origin
    r=[s rangeOfString:@"a3D_orig:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&orig[0],&orig[1],&orig[2]);
        [volView setOrigin:orig vol:1];}
    r=[s rangeOfString:@"a_orig:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&orig[0],&orig[1],&orig[2]);
        [volView setOrigin:orig vol:2];}
    r=[s rangeOfString:@"f_orig:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&orig[0],&orig[1],&orig[2]);
        [volView setOrigin:orig vol:3];}

    //---------------------------------- set voxel dimensions
    r=[s rangeOfString:@"a3D_vdim:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&vdim[0],&vdim[1],&vdim[2]);
        [volView setVoxelDimension:vdim vol:1];}
    r=[s rangeOfString:@"a_vdim:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&vdim[0],&vdim[1],&vdim[2]);
        [volView setVoxelDimension:vdim vol:2];}
    r=[s rangeOfString:@"f_vdim:"];
    if(r.length)
    {	sscanf(&c[r.location+r.length],"%f %f %f",&vdim[0],&vdim[1],&vdim[2]);
        [volView setVoxelDimension:vdim vol:3];}
}
-(IBAction)loadCommands:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*path;
    int		result;
    
    printf("open anatomical\n");

    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        path=[[openPanel filenames] objectAtIndex:0];
        [self openVolumeViewAt:path];
    }
}
-(IBAction)saveCommands:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    int result=[savePanel runModal];
    if (result == NSOKButton)
    {
        NSString *path=[savePanel filename];
        char	str[256];
        NSMutableString *s=[[NSMutableString alloc] init];

        sprintf(str,"anat3D_path:<%s>\n",an3D.path); [s appendString:[NSString stringWithUTF8String:str]];
        sprintf(str,"anat_path:<%s>\n",anat.path);   [s appendString:[NSString stringWithUTF8String:str]];
        sprintf(str,"func_path:<%s>\n\n",func.path); [s appendString:[NSString stringWithUTF8String:str]];
        
        [s appendString:@"talairach_matrix:\n"];
        [volView getTalairachMatrix:TM];
        sprintf(str,"origin: %f %f %f\n", TM[0], TM[1], TM[2]);  [s appendString:[NSString stringWithUTF8String:str]];
        sprintf(str,"sagital: %f %f %f\n",TM[3], TM[4], TM[5]);  [s appendString:[NSString stringWithUTF8String:str]];
        sprintf(str,"coronal: %f %f %f\n",TM[6], TM[7], TM[8]);  [s appendString:[NSString stringWithUTF8String:str]];
        sprintf(str,"axial: %f %f %f\n\n",TM[9], TM[10], TM[11]);[s appendString:[NSString stringWithUTF8String:str]];
        
        [s appendString:@"view_settings\n{\n"];
        [s appendString:[[NSApp delegate] getCommandsString]];
        [s appendString:@"\n}"];
        
        [s writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[s release];
    }
}
-(void)openVolumeViewAt:(NSString*)path
{
    NSString *s=[[NSString alloc] initWithContentsOfFile:path];
    const char *c;
    char file[256];
    NSRange	r={0,0};
    int		i,j,size;
    int		start,end;

    c=[s UTF8String];
    
    //_________________________load files
    for(j=0;j<3;j++)
    {
        switch(j)
        {	case 0:r=[s rangeOfString:@"anat3D_path:"];break;
                case 1:r=[s rangeOfString:@"anat_path:"];break;
                case 2:r=[s rangeOfString:@"func_path:"];break;
        }
        if(r.length)
        {
            i=r.location+r.length+1;
            size=0;
            do
            {
                file[size++]=c[i++];
            }while(c[i]!='>');
            file[size]=(char)0;
            switch(j)
            {
                case 0:	[self openAnatomicalData:&an3D path:[[NSString alloc] initWithUTF8String:file]];
                        an3D.initialised=YES;
                        [volView setAnat3DVolume:an3D]; break;
                case 1:	[self openAnatomicalData:&anat path:[[NSString alloc] initWithUTF8String:file]];
                        anat.initialised=YES;
                        [volView setAnatVolume:anat]; break;
                case 2:	[self openFunctionalData:&func path:[[NSString alloc] initWithUTF8String:file]];
                        func.initialised=YES;
                        [volView setFuncVolume:func]; break;
            }
        }
    }
    //_______________________load talairach matrix
    r=[s rangeOfString:@"talairach_matrix:"];
    if(r.length)
    {
        sscanf(&c[r.location+r.length],
                "\norigin: %f %f %f\nsagital: %f %f %f\ncoronal: %f %f %f\naxial: %f %f %f",
                &TM[0],&TM[1],&TM[2],
                &TM[3],&TM[4],&TM[5],
                &TM[6],&TM[7],&TM[8],
                &TM[9],&TM[10],&TM[11]);
        [volView setTalairachMatrix:TM];
    }
    
    //______________________load view settings
    r=[s rangeOfString:@"view_settings"];
    if(r.length)
    {
        NSString *tmp,*cmd;
    
        i=r.location+r.length;
        while(c[i]!='{') i++;
        while(c[i]==' ' || c[i]=='\n') i++;
        start=++i;
        while(c[i]!='}') i++;
        end=i-1;
        tmp=[[NSString alloc] initWithUTF8String:&c[start]];
		cmd=[tmp substringWithRange:(NSRange){0,end-start}];
        commandStr=[[NSAttributedString alloc] initWithString:cmd];
        [[NSApp delegate] setCommandsString:commandStr];
        [self applyCommands:self];
    }
    [volView setNeedsDisplay:YES];
}
-(void)openAnatomicalData:(VolumeDescription*)v path:(NSString*)path
{
    NSData *header;
    NSString *ext=[path pathExtension];
    if([ext isEqualToString:@"ima"]) printf("reading ima\n");
    if([ext isEqualToString:@"mov"]) printf("mov\n");
    if([ext isEqualToString:@"img"])
    {
        printf("read Analyze (img)\n");
		if(v->data) free(v->data);
        (*v).data=(unsigned char*)[[[NSData alloc] initWithContentsOfFile:path] bytes];
        header=[[NSData alloc] initWithContentsOfFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"hdr"]];
        parseAnalyzeData(v, (unsigned char*)[header bytes], [header length]);
		[header release];
    }
    if([ext isEqualToString:@"hdr"])
    {
        printf("read Analyze (hdr)\n");
        (*v).data=(unsigned char*)[[[NSData alloc] initWithContentsOfFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]] bytes];
        header=[[NSData alloc] initWithContentsOfFile:path];
        parseAnalyzeData(v, (unsigned char*)[header bytes], [header length]);
		[header release];
    }
    if([ext isEqualToString:@"MR"])
    {
        NSMutableData *d=[[NSMutableData alloc] initWithLength:0];
        NSData	*xd;
        NSString *name=[NSString stringWithString:[path stringByDeletingPathExtension]];
        NSString *root=[NSString stringWithString:[name substringToIndex:[name length]-1]];
        int	 i=1;
        BOOL	 loop=TRUE;
        const void *bytes;
        int	length,offset=0;
        int	bytesPerVoxel=2;
        int	width=256, height=256;
        printf("read GE Signa (MR) as Raw data\n");
        do
        {
            NSMutableString *filename=[NSMutableString stringWithString:root];
            NSNumber *num=[NSNumber numberWithInt:i];
            [filename appendString:[num stringValue]];
            [filename appendString:@".MR"];
            if([[NSFileManager defaultManager] fileExistsAtPath:filename])
            {
                xd=[[NSData alloc] initWithContentsOfFile:filename];
                bytes=[xd bytes];
                length=[xd length];
                offset=length-width*height*bytesPerVoxel;
                [d appendBytes:bytes+offset length:width*height*bytesPerVoxel];
                [xd release];
                i++;
            }
            else
                loop=FALSE;
        }
        while(loop);
        printf("data length:%i\n",[d length]);
        (*v).data=(unsigned char*)[[[NSData alloc] initWithData:d] bytes];
        [d release];
        (*v).dim[0]=width;   (*v).dim[1]=height;   (*v).dim[2]=i-1;
        (*v).pdim[0]=1.0;    (*v).pdim[1]=1.0;     (*v).pdim[2]=1.0*124/(float)i;
        (*v).orig[0]=width/2;(*v).orig[1]=height/2;(*v).orig[2]=i/2;
        (*v).dataType=4; // unsigned short
        (*v).littleEndian=YES;
        
        vol_configureTransformationMatrices(v);
    }
    
    (*v).path=(char *)calloc(strlen([path UTF8String]),sizeof(char));
    memcpy((*v).path,[path UTF8String],strlen([path UTF8String]));	//memcpy(dst,src,lngth)

    printf("dim x:%i, y:%i, z:%i\n", (*v).dim[0], (*v).dim[1], (*v).dim[2]);
    printf("pixel dim x:%f, y:%f, z:%f\n", (*v).pdim[0], (*v).pdim[1], (*v).pdim[2]);
    printf("origin x:%i, y:%i, z:%i\n", (*v).orig[0], (*v).orig[1], (*v).orig[2]);
}
-(void)openFunctionalData:(VolumeDescription*)v path:(NSString*)path
{
    if([[path pathExtension] isEqualToString:@"img"])
    {
        NSData *header;
        printf("read Analyze (img)\n");
        (*v).data=(unsigned char*)[[[NSData alloc] initWithContentsOfFile:path] bytes];
        header=[[NSData alloc] initWithContentsOfFile:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"hdr"]];
        parseAnalyzeData(&func, (unsigned char*)[header bytes], [header length]);
        
        (*v).path=(char *)calloc(strlen([path UTF8String]),sizeof(char));
        memcpy((*v).path,[path UTF8String],strlen([path UTF8String]));	//memcpy(dst,src,lngth)
		[header release];
    }
    else
        printf("only .img files by now\n");
}
-(IBAction)projectFunctionalHemisphere:(id)sender
{
    AppController *ac=(AppController*)[NSApp delegate];
    int	hemisphere=[sender tag];
    int	i;
    NSBitmapImageRep *bmp;
    
    // project on mesh vertices data
    if(vf1_front)	free(vf1_front);
    vf1_front=(float*)calloc((*mesh).np,sizeof(float));
    for(i=0;i<(*mesh).np;i++)	vf1_front[i]=-1;
    [volView projectFunctionalHemisphere:hemisphere inVertices:vf1_front];
    [self setVerticesData];

    // project on geometric model
    bmp=[NSBitmapImageRep  imageRepWithContentsOfFile:[appPath stringByAppendingString:path_img_gm]];
    ImageTalairach=[bmp bitmapData];
    tal_projectVerticesDataOnGeometricModel(&mesh_original,
            (float3D*)vf3_gm,
            vf1_front,
            ImageTalairach,
            [bmp samplesPerPixel],
            [bmp pixelsWide],
            [bmp pixelsHigh],
            [ac getColourmap]);
     img_data=[[[NSImage alloc] init] autorelease];
     [img_data addRepresentation:bmp];
     [self setGMPicture];
}
#pragma mark -
#pragma mark [  geometric atlas tab  ]
- (IBAction) savePicture:(id)sender
{
    NSString	*tab=[[tabView selectedTabViewItem] label];

    if([tab isEqualToString:@"Surface"])
            [openGLView savePicture];
    if([tab isEqualToString:@"Geometric Atlas"])
            [quickDrawView savePicture];
			//[self saveImageArrayToTiffWithLayers:img_array];
}
-(IBAction) clusterSize:(id)sender
{
    float	a[2],b[2];
    NSBezierPath	*ap,*bp,*stdp;
    NSRect		r;
    NSPoint		o;
    int			s;
    float		x;

    ga_getClusterSize(mesh,(float3D*)vf3_gm,vf1_front,a,b);
    
    r=[quickDrawView bounds];
    o=NSMakePoint(r.size.width/2,r.size.height/2);
    if(r.size.width>r.size.height)	s=r.size.height;
    else				s=r.size.width;

    ap=[NSBezierPath bezierPath];	[ap setLineWidth:2];
    bp=[NSBezierPath bezierPath];	[bp setLineWidth:2];
    stdp=[NSBezierPath bezierPath];	[stdp setLineWidth:2];

    for(x=b[0]-b[1];x<=b[0]+b[1];x+=0.1)
        if(x==b[0]-b[1])
            [ap moveToPoint:NSMakePoint(o.x+s*a[0]/360.0*cos(x*pi/180.0),o.y+s*a[0]/360.0*sin(x*pi/180.0))];
        else
            [ap lineToPoint:NSMakePoint(o.x+s*a[0]/360.0*cos(x*pi/180.0),o.y+s*a[0]/360.0*sin(x*pi/180.0))];
    [bp moveToPoint:NSMakePoint(o.x+s*(a[0]-a[1])/360.0*cos(b[0]*pi/180.0),o.y+s*(a[0]-a[1])/360.0*sin(b[0]*pi/180.0))];
    [bp lineToPoint:NSMakePoint(o.x+s*(a[0]+a[1])/360.0*cos(b[0]*pi/180.0),o.y+s*(a[0]+a[1])/360.0*sin(b[0]*pi/180.0))];
    
    [stdp moveToPoint:NSMakePoint(o.x+s*(a[0]-a[1])/360.0*cos((b[0]-b[1])*pi/180.0), o.y+s*(a[0]-a[1])/360.0*sin((b[0]-b[1])*pi/180.0))];
    [stdp lineToPoint:NSMakePoint(o.x+s*(a[0]+a[1])/360.0*cos((b[0]-b[1])*pi/180.0), o.y+s*(a[0]+a[1])/360.0*sin((b[0]-b[1])*pi/180.0))];
    for(x=b[0]-b[1];x<=b[0]+b[1];x+=0.1)
        [stdp lineToPoint:NSMakePoint(o.x+s*(a[0]+a[1])/360.0*cos(x*pi/180.0), o.y+s/360.0*(a[0]+a[1])*sin(x*pi/180.0))];
    [stdp lineToPoint:NSMakePoint(o.x+s*(a[0]-a[1])/360.0*cos((b[0]+b[1])*pi/180.0), o.y+s/360.0*(a[0]-a[1])*sin((b[0]+b[1])*pi/180.0))];
    for(x=b[0]+b[1];x>=b[0]-b[1];x-=0.1)
        [stdp lineToPoint:NSMakePoint(o.x+s*(a[0]-a[1])/360.0*cos(x*pi/180.0), o.y+s*(a[0]-a[1])/360.0*sin(x*pi/180.0))];

    [quickDrawView lockFocus];
    [[NSColor redColor] set];
    [ap stroke];
    [bp stroke];
    [[NSColor greenColor] set];
    [stdp stroke];
    [quickDrawView unlockFocus];
}
-(IBAction) findClusters:(id)sender
{
    //ga_findClusters();
}
-(IBAction) saveLayers:(id)sender
{
	[self saveImageArrayToTiffWithLayers:img_array];
}
-(int)img_array_count
{
	return [img_array count];
}
-(id)img_array_keyAtIndex:(int)index
{
	NSString	*s;
	
	if(index>=ClusterArrayCount)
		return NULL;
	s=[NSString stringWithUTF8String:ClusterArray[index].key];
	return s;
}
-(id)img_array_visibilityAtIndex:(int)index
{
	NSNumber	*n;
	
	if(index>=ClusterArrayCount)
		return NULL;
	n=[NSNumber numberWithBool:ClusterArray[index].visible];
	return n;
}
-(void)img_array_setVisibilityAtIndex:(int)row to:(BOOL)show
{
	if(row>=ClusterArrayCount)
		return;
	ClusterArray[row].visible=show;
	[self imageArrayToGMPicture];
}
-(void)saveImageArrayToTiffWithLayers:(NSArray*)img
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    int		result;
	char	hdr[]={77,77, 0,42, 0,0,0,32};
	char	count[]={0,13},
			imageWidth[]=   {1,0,  0,3, 0,0,0,1, 0,0,0,0},//
			imageHeight[]=  {1,1,  0,3, 0,0,0,1, 0,0,0,0},//
			BitsPrSmpl[]=   {1,2,  0,3, 0,0,0,4, 0,0,0,8},// points to 0x0008
			Comprssn[]=		{1,3,  0,3, 0,0,0,1, 0,1,0,0},
			PhtmtrcI[]=		{1,6,  0,3, 0,0,0,1, 0,2,0,0},
			StripOffst[]=   {1,17, 0,4, 0,0,0,1, 0,0,0,0},//
			SmplsPrPxl[]=   {1,21, 0,3, 0,0,0,1, 0,4,0,0},
			StrpBytCnt[]=   {1,23, 0,4, 0,0,0,1, 0,16,0,0},
			XResol[]=		{1,26, 0,5, 0,0,0,1, 0,0,0,16},// points to 0x0010
			YResol[]=		{1,27, 0,5, 0,0,0,1, 0,0,0,24},// points to 0x0018
			PlanarCnfg[]=   {1,28, 0,3, 0,0,0,1, 0,1,0,0},
			ResolUnit[]=	{1,40, 0,3, 0,0,0,1, 0,2,0,0},
			ExtraSmpls[]=   {1,82, 0,3, 0,0,0,1, 0,2,0,0},
			nextIFD[]=		{0,0,0,0};
	char	BPS[]={0,8,0,8,0,8,0,8},
			Res72dpi[]={0,10,252,128, 0,0,39,16};
	NSSize	size;
	int		off_strip, off_ifd;
	int		i;
	NSMutableData   *tiff;
	
    [savePanel setRequiredFileType:@"tif"];
    [savePanel setCanSelectHiddenExtension:YES];
    result=[savePanel runModal];
    if (result != NSOKButton)
		return;

	size=[[img objectAtIndex:0] size];
	imageWidth[8]=(char)(size.width/256);
	imageWidth[9]=(char)(size.width-(int)imageWidth[8]*256);
	imageHeight[8]=(char)(size.height/256);
	imageHeight[9]=(char)(size.height-(int)imageHeight[8]*256);
	
	// header + static info
	tiff = [NSMutableData dataWithBytes:hdr length:8];
	[tiff appendBytes:BPS		length:8]; // 0x000a
	[tiff appendBytes:Res72dpi	length:8]; // 0x000g
	[tiff appendBytes:Res72dpi	length:8]; // 0x0018
	
	// ifds
	for(i=0;i<[img count];i++)
	{
		off_strip=  8+8+2*8+[img count]*(2+13*12+4)+	// hdr+bps+2*res+ #IFD*(count+count*12+nextFID)
					i*size.width*size.height*4;			// i* uncompressedImageSize
		if(i<[img count]-1)
			off_ifd=	8+8+2*8+(i+1)*(2+13*12+4);
		else
			off_ifd=	0;
	
		StripOffst[8]=(off_strip&0xff000000)>>24;
		StripOffst[9]=(off_strip&0x00ff0000)>>16;
		StripOffst[10]=(off_strip&0x0000ff00)>>8;
		StripOffst[11]=(off_strip&0x000000ff);
		
		nextIFD[0]=(off_ifd&0xff000000)>>24;
		nextIFD[1]=(off_ifd&0x00ff0000)>>16;
		nextIFD[2]=(off_ifd&0x0000ff00)>>8;
		nextIFD[3]=(off_ifd&0x000000ff);
		
		[tiff appendBytes:count			length:2];
		[tiff appendBytes:imageWidth	length:12];
		[tiff appendBytes:imageHeight   length:12];
		[tiff appendBytes:BitsPrSmpl	length:12];
		[tiff appendBytes:Comprssn		length:12];
		[tiff appendBytes:PhtmtrcI		length:12];
		[tiff appendBytes:StripOffst	length:12];
		[tiff appendBytes:SmplsPrPxl	length:12];
		[tiff appendBytes:StrpBytCnt	length:12];
		[tiff appendBytes:XResol		length:12];
		[tiff appendBytes:YResol		length:12];
		[tiff appendBytes:PlanarCnfg	length:12];
		[tiff appendBytes:ResolUnit		length:12];
		[tiff appendBytes:ExtraSmpls	length:12];
		[tiff appendBytes:nextIFD		length:4];
	}
	
	// image data
	for(i=0;i<[img count];i++)
		[tiff appendBytes:[[img objectAtIndex:i] bitmapData] length:size.width*size.height*4];
	
	[tiff writeToFile:[savePanel filename] atomically:YES];
}
-(void)setGMPicture
{
	NSImage *img_gm=[[NSImage alloc] init];
	
	[img_gm addRepresentation:bmp_gm];
	
	[img_gm lockFocus];
		if(img_data)
		[img_data	compositeToPoint:NSZeroPoint
					operation:NSCompositeSourceOver];
	[img_gm unlockFocus];
	//if(img_data) /*[quickDrawView setPicture:img_data];*/
	[quickDrawView setPicture:img_gm];
	[img_gm release];
	[quickDrawView setNeedsDisplay:YES];
}
-(void)imageArrayToGMPicture
{
	AppController	*ac=(AppController*)[NSApp delegate];
	NSImage *imgfromrep;
	int		i;

    img_data=[[[NSImage alloc] initWithSize:NSMakeSize(512,512)] autorelease];

	switch([ac getProjectionMode])
	{
		case 0: // distance
			[img_data lockFocus];
			for(i=0;i<ClusterArrayCount;i++)
			if(ClusterArray[i].visible==YES)
			{
				//... make it an image
				imgfromrep = [[[NSImage alloc] init] autorelease];
				[imgfromrep addRepresentation:[img_array objectAtIndex:i]];

				[imgfromrep	compositeToPoint:NSZeroPoint
							operation:NSCompositeSourceOver
							fraction:ClusterArray[i].fraction];
			}
			[img_data unlockFocus];
			break;
		case 1: // density
		{
			NSBitmapImageRep	*bmp;
			unsigned char		*im0;
			int					*n,j;
			double				max;
			
			max=0;
			n=(int*)calloc(512*512,sizeof(int));
			for(i=0;i<512*512;i++) n[i]=0;
			for(i=0;i<ClusterArrayCount;i++)
			if(ClusterArray[i].visible==YES)
			{
				im0=[[img_array objectAtIndex:i] bitmapData];
				for(j=0;j<512*512;j++)
				if(im0[j*4+3]>0)
				{
					n[j]++;
					if(n[j]>max)  max=n[j];
				}
			}
			printf("number of keys:%i\nmaximum density:%i\n",ClusterArrayCount,(int)max);
			bmp=[[NSBitmapImageRep alloc]   initWithBitmapDataPlanes:NULL
											pixelsWide:512  pixelsHigh:512
											bitsPerSample:8 samplesPerPixel:4
											hasAlpha:YES	isPlanar:NO
											colorSpaceName:NSCalibratedRGBColorSpace
											bytesPerRow:0   bitsPerPixel:0];
			im0=[bmp bitmapData];
			for(i=0;i<512*512;i++)
			if(n[i]>0)
			{
				im0[i*4+0]=im0[i*4+1]=im0[i*4+2]=255*n[i]/max;
				im0[i*4+3]=255;
			}
			else
				im0[i*4+0]=im0[i*4+1]=im0[i*4+2]=im0[i*4+3]=0;

			//... make it an image
			[img_data addRepresentation:bmp];

			break;
		}
	}
	[self setGMPicture];
}
#pragma mark -
#pragma mark [  talairach tab  ]
- (IBAction) openTalairachCoordinates: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*filename;
    int		result;
    
    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        NSURL	*url;
        NSAttributedString *s;
        
        filename=[[openPanel filenames] objectAtIndex:0];
        url=[NSURL fileURLWithPath:filename];
       	s=[[NSAttributedString alloc] initWithURL:url documentAttributes:NULL];
        [[NSApp delegate] setTalairachViewString:s];
    }
}
- (IBAction) saveTalairachCoordinates: (id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSString	*filename;
    int		result;
    
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        NSAttributedString *s;
        filename=[savePanel filename];
        s=[[NSApp delegate] getTalairachViewString];
        [[s string] writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (IBAction) setDistanceTalairachCoordinates: (id) sender
{
    DistanceTalairach=[sender floatValue];
    if([sender isKindOfClass:[NSSlider class]])
        [[NSApp delegate] setDistanceField:DistanceTalairach];
    else
    if([sender isKindOfClass:[NSTextField class]])
        [[NSApp delegate] setDistanceSlider:DistanceTalairach];
}
- (IBAction) projectTalairachCoordinates: (id) sender
{
    AppController	*ac=(AppController*)[NSApp delegate];
    char	*data;	// text file
    int		size;	// text file size
    int		i;
	int		hemisphere=[sender tag]; //0:L 1:R
    float	colour[3];
    NSString *s;
	NSBitmapImageRep *img;
    
    // 0. configure colour for monochromatic colourmaps
    [ac getColour:colour];
    configureMonochromaticColourmap(colour);

    // 1. get string and parse script
    s=[[ac getTalairachViewString] string];
    data=(char*)[s UTF8String];
    size=strlen([s UTF8String]);
	
	tal_parseScript(data,size,&ClusterArray,&ClusterArrayCount,NO,NO);
	ClusterArray=(ClusterRec*)calloc(ClusterArrayCount,sizeof(ClusterRec));
	tal_parseScript(data,size,&ClusterArray,&ClusterArrayCount,YES,NO);
	for(i=0;i<ClusterArrayCount;i++)
		ClusterArray[i].c=(float*)calloc(ClusterArray[i].nc*3,sizeof(float));
	tal_parseScript(data,size,&ClusterArray,&ClusterArrayCount,YES,YES);
	
	// 2. project individual clusters and make image array
	[img_array removeAllObjects];
	for(i=0;i<ClusterArrayCount;i++)
	{
		img=[self projectTalairachCluster:ClusterArray[i] hemisphere:hemisphere];
		[img_array addObject:img];
	}
	[self imageArrayToGMPicture];
}
-(NSBitmapImageRep*)projectTalairachCluster:(ClusterRec)cr hemisphere:(int)hemisphere
{    
    AppController	*ac=(AppController*)[NSApp delegate];
    int		i;
	NSBitmapImageRep *bmp;

    // 1. project talairach coordinates on vertices data
    if(vf1_front)	free(vf1_front);
    vf1_front=(float*)calloc((*mesh).np,sizeof(float));
    for(i=0;i<(*mesh).np;i++)	vf1_front[i]=-1;
    tal_projectTalairachOnVerticesData(&mesh_original,
            MatrixTalairachToMeshSpace,
            cr.c,cr.nc,DistanceTalairach,
            vf1_front,hemisphere);
    [self setVerticesData];

    // 2. project vertices data on geometric model
    bmp=[[NSBitmapImageRep alloc]
			initWithBitmapDataPlanes:NULL
			pixelsWide:512
			pixelsHigh:512
			bitsPerSample:8
			samplesPerPixel:4
			hasAlpha:YES
			isPlanar:NO
			colorSpaceName:NSCalibratedRGBColorSpace
			bytesPerRow:0
			bitsPerPixel:0];
    ImageTalairach=[bmp bitmapData];
    tal_projectVerticesDataOnGeometricModel(&mesh_original,
            (float3D*)vf3_gm,
            vf1_front,
            ImageTalairach,
            [bmp samplesPerPixel],
            [bmp pixelsWide],
            [bmp pixelsHigh],
            [ac getColourmap]);
	 
	 return bmp;
}
#pragma mark -
#pragma mark [   work in progress...   ]
- (IBAction) makeMovie:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    int		result;
    
    [savePanel setRequiredFileType:@"tif"];
    [savePanel setCanSelectHiddenExtension:YES];
    result=[savePanel runModal];
    if (result == NSOKButton)
    {
        int	i;
        
        for(i=0;i<360;i++)
        {
            NSString *name,*filename;
            name=[[NSNumber numberWithInt:i] stringValue];
            filename=[[savePanel directory] stringByAppendingPathComponent:name];
            filename=[filename stringByAppendingPathExtension:@"tif"];
            [openGLView setRotationY:(float)i];
            [openGLView display];
            [openGLView savePicture:filename];
        }
    }
}
- (IBAction) smoothTalairachProjection:(id)sender
{
    tal_smoothTalairachVerticesData(&mesh_original, VerticesDataTalairach);
    [self setVerticesData];
}
- (IBAction) mapVerticesData:(id)sender
{
    AppController	*ac=(AppController*)[NSApp delegate];
    int	i;
    NSBitmapImageRep *bmp=[NSBitmapImageRep  imageRepWithContentsOfFile:[appPath stringByAppendingString:path_img_gm]];
    NSImage *img;
    ImageTalairach=[bmp bitmapData];

    if(VerticesDataTalairach)	free(VerticesDataTalairach);
    VerticesDataTalairach=(float*)calloc((*mesh).np,sizeof(float)*3);
    for(i=0;i<(*mesh).np;i++)	VerticesDataTalairach[i]=vf1_back[i];

    tal_projectVerticesDataOnGeometricModel(
            &mesh_original,
            (float3D*)vf3_gm,
            VerticesDataTalairach,
            ImageTalairach,
            [bmp samplesPerPixel],
            [bmp pixelsWide],
            [bmp pixelsHigh],
            [ac getColourmap]);
     img = [[[NSImage alloc] init] autorelease];
     [img addRepresentation:bmp];
}
- (IBAction) loadGMTexture:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString	*filename;
    int		result;
    
    [openPanel setAllowsMultipleSelection:NO];
    result=[openPanel runModalForDirectory:nil file:nil types:nil];
    if (result == NSOKButton)
    {
        NSBitmapImageRep *bmp;
        NSImage *img;
        
        filename=[[openPanel filenames] objectAtIndex:0];
        bmp=[NSBitmapImageRep imageRepWithContentsOfFile:filename];
        [self initGMTexture:bmp];
        img = [[[NSImage alloc] init] autorelease];
        [img addRepresentation:bmp];
    }
}
- (IBAction) sphereFromTexture:(id)sender
{
    em_sphereFromTxtr(mesh,(float3D*)vf3_gm);
    [openGLView setVertices:(float *)msh_getPointsPtr(mesh) number:(*mesh).np];
    [openGLView setNeedsDisplay:YES];
}
- (void) projectAreaOnGeometricModel:(MeshPtr)m
{    
	NSBitmapImageRep *bmp;

    //project mesh area on geometric model
    bmp=[[NSBitmapImageRep alloc]
			initWithBitmapDataPlanes:NULL
			pixelsWide:512
			pixelsHigh:512
			bitsPerSample:8
			samplesPerPixel:4
			hasAlpha:YES
			isPlanar:NO
			colorSpaceName:NSCalibratedRGBColorSpace
			bytesPerRow:0
			bitsPerPixel:0];
    ImageTalairach=[bmp bitmapData];
    tal_projectAreaOnGeometricModel(m,
            (float3D*)vf3_gm,
            ImageTalairach,
            [bmp samplesPerPixel],
            [bmp pixelsWide],
            [bmp pixelsHigh]);
	 
	 img_data=[[[NSImage alloc] initWithSize:NSMakeSize(512,512)] autorelease]; 
	 [img_data addRepresentation:bmp];
	 [self setGMPicture];
}
#pragma mark -
-(id)handleSayHelloScriptCommand:(NSScriptCommand*)command
{
	char c[]="tell application \"Finder\" \n say \"Hello\" using \"Zarvox\" \n end tell";
	NSAppleScript *script;
	NSDictionary	*errorInfo;
	script=[[NSAppleScript alloc] initWithSource:[NSString stringWithUTF8String:c]];
	[script executeAndReturnError:&errorInfo];
	return nil;
}
-(id)handleSayScriptCommand:(NSScriptCommand*)command
{
	NSDictionary	*arg=[command arguments];
	NSString	*data=[arg objectForKey:@"ToSay"];

	printf("it is %s and %s\n",[[arg description] UTF8String],[[data description] UTF8String]);
	char c[512];
	char c0[]="tell application \"Finder\" \n say \"";
	char c1[]="\" using \"Zarvox\" \n end tell";
	NSAppleScript *script;
	NSDictionary	*errorInfo;

	sprintf(c,"%s%s%s\n",c0,[data UTF8String],c1);
	printf("%s\n",c);
	script=[[NSAppleScript alloc] initWithSource:[NSString stringWithUTF8String:c]];
	[script executeAndReturnError:&errorInfo];

	return nil;
}
-(id)handleProjectCoordinatesScriptCommand:(NSScriptCommand*)command
{
	NSDictionary		*arg=[command arguments];
	NSArray				*data=[arg objectForKey:@"Coords"];
	NSString			*hemisph=[arg objectForKey:@"Hemisph"];
	NSString			*key=[arg objectForKey:@"Key"];
	int					hem;
	int					i,j,n=[data count];
	char				*key_UTF8String=(char*)[key UTF8String];
	NSBitmapImageRep	*img;
	NSData				*imgdata;

	if(ClusterArray!=nil)
	{
		for(i=0;i<ClusterArrayCount;i++) free(ClusterArray[i].c);
		free(ClusterArray);
	}
			
	ClusterArrayCount=1;
	ClusterArray=(ClusterRec*)calloc(ClusterArrayCount,sizeof(ClusterRec));
	ClusterArray[0].c=(float*)calloc(n,sizeof(float));
	for(i=0;i<n;i++)
		ClusterArray[0].c[i]=[[data objectAtIndex:i] floatValue];
	j=0;
	while(key_UTF8String[j]!=(char)0){ ClusterArray[0].key[j]=key_UTF8String[j];j++;}
	ClusterArray[0].key[j]=(char)0;
	ClusterArray[0].nc=n/3;
	ClusterArray[0].visible=YES;
	ClusterArray[0].fraction=1.0;

	if([hemisph isEqualTo:@"Left"]) hem=0;
	if([hemisph isEqualTo:@"Right"]) hem=1;
	[img_array removeAllObjects];
	img=[self projectTalairachCluster:ClusterArray[0] hemisphere:hem];// 0 Left
	[img_array addObject:img];
	[self imageArrayToGMPicture];
	printf("%s hemisphere\n",(hem==0)?"-----\n Left":" Right");
	
	imgdata=[NSData dataWithData:[img TIFFRepresentation]];
	return imgdata;
}
@end
