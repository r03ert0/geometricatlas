//
//  MyDocument.h
//  Geometric Atlas Cocoa
//
//  Created by roberto on Sat Sep 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MyOpenGLView.h"
#import "MyView.h"
#import "VolumeView.h"
#include "util.h"
#include "geometricatlas.h"
#include "editmesh.h"
#include "talairach.h"

@interface MyDocument : NSDocument
{
    IBOutlet NSTabView			*tabView;
    IBOutlet MyOpenGLView		*openGLView;
    IBOutlet MyView				*quickDrawView;
    IBOutlet VolumeView			*volView;
    
    // mesh data
    MeshRec			*mesh;
    float			*vertscolour;	// vertices colour (depth, curvature)
    char			*image;		// texture image (geometric model)
    float			*param;		// 2D surface parametrisation
    
    // surface tab
    int			selectedMesh, selectedVerticesData;
    MeshRec		mesh_original, mesh_smoothed, mesh_spherical;
    float		*vf1_back,*vf1_front;
    float		*vf1_proj, *vf1_sulcalDepth, *vf1_curvature, *vf3_gm;
    NSBitmapImageRep	*bmp_gm;
	NSImage				*img_data;
    NSString	*path_mesh_original;
    NSString	*path_mesh_smoothed;
    NSString	*path_mesh_spherical;
    NSString	*path_vf1_depth;
    NSString	*path_vf1_curvature;
    NSString	*path_vf3_gm;
    NSString	*path_img_gm;
    NSString	*path_img_gmsulci;
    NSString	*path_img_gmbrodman;
    
    // talairach tab
    float	MatrixTalairachToMeshSpace[12];
    float	DistanceTalairach;		// Talairach sphere radius
    float3D	*VerticesProjection;		// vertices for projections (stereographic, sinusoidal)
    float	*VerticesDataTalairach;		// vertices data array for Talairach projection
    unsigned char *ImageTalairach;		// stereographic image for Talairach projection
    int		RadiusStereographic;		// radius of the stereographic projection in pixels
	ClusterRec		*ClusterArray;		// talairach studies clusters array
	int				ClusterArrayCount;  // number of talairach clusters
	
	// geometric atlas tab
	NSMutableArray  *img_array;			// array storing

    // volume data
    VolumeDescription	an3D;
    VolumeDescription	anat;
    VolumeDescription	func;
    NSAttributedString	*commandStr;
    float		TM[12];

    // global
    NSString	*appPath;
}

- (IBAction) savePicture:(id)sender;

// General mesh handling methods
-(IBAction) openMesh: (id) sender;
-(void) openMesh:(MeshRec*)mesh fromFile:(NSString*)filename;
-(void) setMesh:(MeshRec*)mesh;
-(IBAction) meshAction: (id) sender;

-(IBAction) openVerticesData: (id) sender;
-(void) openVerticesData:(float**)txtr fromFile:(NSString*)filename;
-(void) setVerticesData;
-(IBAction) verticesDataAction: (id) sender;

-(void) setTextureActive:(BOOL)hasTxtr;

-(IBAction) setStandardRotation: (id) sender;
-(IBAction) setRotationX: (id) sender;
-(IBAction) setRotationY: (id) sender;
-(IBAction) setRotationZ: (id) sender;

-(IBAction) setZoom: (id) sender;

// Geometric atlas methods
// surface tab
-(IBAction) changeMesh: (id) sender;
-(IBAction) changeProjection: (id) sender;
-(IBAction) changeVerticesData: (id) sender;
-(IBAction) changeGMTexture: (id) sender;
-(void) awakeGA;
-(void) initGMParametrisation;
-(void) initGMTexture:(NSBitmapImageRep*)imgRep;
-(int)getMeshVerticesNumber;
- (float*)getMeshVertices;
- (float*)getMeshVerticesColor;
- (float*)getMeshNormalisationMatrix;
// volume tab
-(IBAction)openVolume:(id)sender;
-(IBAction)saveActivation:(id)sender;
-(IBAction)changeSlice:(id)sender;
-(IBAction)changeOrientation:(id)sender;
-(IBAction)changeSpace:(id)sender;
-(IBAction)showTalairach:(id)sender;
-(IBAction)applyCommands:(id)sender;
-(IBAction)loadCommands:(id)sender;
-(IBAction)saveCommands:(id)sender;
-(void)openVolumeViewAt:(NSString*)path;
-(void)openAnatomical:(VolumeDescription*)v;
-(void)openFunctional:(VolumeDescription*)v;
-(void)openAnatomicalData:(VolumeDescription*)v path:(NSString*)path;
-(void)openFunctionalData:(VolumeDescription*)v path:(NSString*)path;
-(IBAction)projectFunctionalHemisphere:(id)sender;
// talairach tab
- (IBAction) openTalairachCoordinates: (id) sender;
- (IBAction) saveTalairachCoordinates: (id) sender;
- (IBAction) projectTalairachCoordinates: (id) sender;
-(NSBitmapImageRep*)projectTalairachCluster:(ClusterRec)cr hemisphere:(int)hemisphere;
- (IBAction) setDistanceTalairachCoordinates: (id) sender;
- (IBAction) smoothTalairachProjection:(id)sender;
// geometric atlas tab
- (IBAction) savePicture:(id)sender;
-(IBAction) clusterSize:(id)sender;
-(IBAction) findClusters:(id)sender;
-(IBAction) saveLayers:(id)sender;
-(int)img_array_count;
-(id)img_array_keyAtIndex:(int)index;
-(id)img_array_visibilityAtIndex:(int)index;
-(void)img_array_setVisibilityAtIndex:(int)row to:(BOOL)show;
-(void)saveImageArrayToTiffWithLayers:(NSArray*)img;
-(void)setGMPicture;
-(void)imageArrayToGMPicture;

// work in progress
- (IBAction) mapVerticesData:(id)sender;
- (IBAction) loadGMTexture:(id)sender;
- (IBAction) makeMovie:(id)sender;
- (IBAction) sphereFromTexture:(id)sender;
- (void) projectAreaOnGeometricModel:(MeshPtr)m;

// apple script support
-(id)handleSayHelloScriptCommand:(NSScriptCommand*)command;
-(id)handleSayScriptCommand:(NSScriptCommand*)command;
-(id)handleProjectCoordinatesScriptCommand:(NSScriptCommand*)command;
@end
