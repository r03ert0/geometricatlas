/* VolumeView */

#import <Cocoa/Cocoa.h>
#ifndef __volume__
    #include "volume.h"
#endif

@interface VolumeView : NSView
{
    VolumeDescription	an3D;
    VolumeDescription	anat;
    VolumeDescription	func;

    int		orient;				// 0:sagital, 1:coronal, 2:axial
    float	slice;				// 0:first slice, 1:last slice
    float	zoom;
    int		space;				// 0:mm, 1:pixel
    BOOL	showTalairach;			// 0:NO, 1:YES
    float	v0[12];	// view sagital (transform screen coords into mm)
    float	v1[12];	// view coronal
    float	v2[12];	// view axial
    float	i2m[12];// index to milimeter: origin(i), sag(m/i), cor(m/i), axi(m/i)
    float	m2i[12];// milimeter to index: origin(i), sag(i/m), cor(i/m), axi(i/m)

    float	thresh;				// t value
    float	fusion;				// 0:anat3D, 1:anat
    float	a3D_light,a_light,f_light;	// multiplying factor
    
    TalairachBox	tb;
}
//-(int)getAnat:(VolumeDescription)v at:(float*)p; //s,c,a in mm
//-(float)getFunc:(VolumeDescription)v at:(float*)p; // s,c,a in mm
-(void)displacement:(NSPoint*)di;
-(void)drawTalairach;

-(int)hitAxiTalairach:(NSPoint)p;
-(void)dragAxiTranslate:(NSPoint)p;
-(void)dragAxiResize:(NSPoint)p;

-(int)hitSagTalairach:(NSPoint)p;
-(void)dragSagResize:(NSPoint)p;
-(void)dragSagTurn:(NSPoint)p;
-(void)dragSagHeader:(NSPoint)p;

-(void)setTalairachMatrix:(float*)TM;
-(void)getTalairachMatrix:(float*)TM;
-(void)configureInverseTalairachMatrix;

-(void)setAnat3DVolume:(VolumeDescription)vd;
-(void)setAnatVolume:(VolumeDescription)vd;
-(void)setFuncVolume:(VolumeDescription)vd;
-(void)setOrientation:(int)o;
-(void)setSlice:(float)slice;
-(void)setZoom:(float)z;
-(void)setSpace:(int)t;
-(void)showTalairach:(BOOL)flag;

-(void)setThreshold:(float)t;
-(void)setFusion:(float)t;
-(void)setLight:(float)t vol:(int)i;
-(void)setOrigin:(float*)origin vol:(int)i;
-(void)setVoxelDimension:(float*)voxel vol:(int)i;

-(void)saveActivation;

-(void)projectFunctionalHemisphere:(int)hemisphere inVertices:(float*)txtr;//0:L, 1:R
@end
