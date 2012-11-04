/*
 *  talairach.h
 *  Geometric Atlas Cocoa
 *
 *  Created by roberto on Sun Oct 05 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __talairach__
#define __talairach__

#ifndef __editmesh__
#include "editmesh.h"
#endif

#ifndef __util__
#include "util.h"
#endif

typedef struct
{
	int		nc;
	float   *c;
	
	bool	visible;
	char	key[256];
	float   fraction;
}ClusterRec;

void tal_parseScript(char *txt, int size, ClusterRec **cr, int *ncr, bool fillcr, bool fillc);

int tal_projectTalairachOnVerticesData(MeshPtr m, float *M, float *c, int nc, float distance, float *vc,int hemisphere);
int tal_smoothTalairachVerticesData(MeshPtr m, float *vc);

//--------------------------
// non talairach in fact!!
void PaintTriangle(float *colour, int colourmap, float3D a, float3D b, float3D c, unsigned char *it, int bytesPerPixel, int width, int height);
int tal_projectVerticesDataOnGeometricModel(MeshPtr m,float3D *gm,float *VerticesDataTalairach, unsigned char *ImageTalairach, int bytesPerPixel, int width,int height, int colourmap);

int triangleArea(float3D *gt, int width, int height);
double PaintTriangleAreaDistortion(double aot, double2D *gt, unsigned char *it, int bytesPerPixel, int width, int height);
double paintpixel(unsigned char *it, int bytesPerPixel, int width, int x, int y,double aot, double agm, double2D *gt);
void chooselimits0(double *t, double x,double s0, double s1, double t0, double t1, int *ai, int *bi);
void chooselimits1(double *t, int x,double s0, double s1, double t0, double t1, int *ai, int *bi);
void chooselimits2(double *t, int x,double u0, double u1, double t0, double t1, int *ai, int *bi);
int tal_projectAreaOnGeometricModel(MeshPtr m, float3D* gm, unsigned char *it, int bytesPerPixel, int width, int height);
//--------------------------

void tal_getPointFromTalairach(float *p, float *tal, float *M);
void tal_getTalairachFromPoint(float *tal, float *p, float *M);
#endif