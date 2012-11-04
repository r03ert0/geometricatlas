/*
 *  volume.h
 *  Geometric Atlas
 *
 *  Created by roberto on Mon Nov 10 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */
#ifndef __volume__
#define __volume__

#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "math3D.h"

typedef struct
{
    bool	littleEndian;
    int		dim[3];
    float	pdim[3];
    int		orig[3];
	
	float   f;			// intensity correction factor (to have 95% of the volume under 255)
    
    float	v2m[12];	// voxel to milimeter: origin(v), sag(m/v), cor(m/v), axi(m/v)
    float	m2v[12];	// milimeter to voxel: origin(v), sag(v/m), cor(v/m), axi(v/m)

    short	dataType;
    
    char		*path;
    
    bool		initialised;
    unsigned char	*data;
}VolumeDescription;

typedef struct
{
    float	M[4*3];// direct: tal to mm (orig, dir sag, dir cor, dir axi)
    float	iM[4*3]; // inverse: mm to tal (orig, s,c,a)
}TalairachBox;

void parseAnalyzeData(VolumeDescription *d, unsigned char *header, int nbytes);

unsigned char readByteFrom(unsigned char *b, int *i);
short readShortFrom(unsigned char *b, int *i, bool little);
int readIntFrom(unsigned char *b, int *i, bool little);
float readFloatFrom(unsigned char *b, int *i, bool little);
short shortAt(unsigned char *b, bool flag);
float floatAt(unsigned char *b, bool flag);

void inverseMatrix(float *a,float *b);
void multiplyMatrices(float *a, float *b,float *c);

float distancePointSegment(float *p,float *e0,float *e1);

void vol_configureTransformationMatrices(VolumeDescription *d);
void vol_configureIntensity(VolumeDescription *d);

void talairachToMilimeters(float *T, float *M, float *m);
void milimetersToTalairach(float *M, float *T, float *im);
void vol_setTransformMatrix(float *m,	float a,float b,float c,
                                        float d,float e,float f,
                                        float g,float h,float i,
                                        float j,float k,float l);
void vol_screenToMilimeters(float *a, float *b, float *ab);
void vol_screenToTalairach(float *a, float *b, float *ab);
void vol_indexToMilimeters(float *a, float *b, float *ab);
void vol_voxelsToMilimeters(float *a, float *b, float *ab);
void vol_milimetersToVoxels(float *a, float *b, float *ab);
void vol_talairachToMilimeters(float *a, float *b, float *ab);
void vol_milimetersToTalairach(float *a, float *b, float *ab);

double vol_getValueAt(VolumeDescription d, float *p);
short vol_getByteAt(VolumeDescription d, float *p);
short vol_getShortAt(VolumeDescription d, float *p);
void vol_setShortAt(VolumeDescription d, float *p, short val);
float vol_getFloatAt(VolumeDescription d, float *p);

//----------------
void connectaround(int x,int y,int z, short value, VolumeDescription vol);
#endif
