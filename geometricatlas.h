/*
 *  geometricatlas.h
 *  Geometric Atlas
 *
 *  Created by roberto on Mon Oct 27 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __geometric_atlas__
#define __geometric_atlas__

#ifndef __talairach__
 #include "talairach.h"
#endif

void ga_getClusterSize(MeshPtr m, float3D *gm, float *vct, float *alpha, float *beta);

#endif