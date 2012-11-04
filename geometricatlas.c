/*
 *  geometricatlas.c
 *  Geometric Atlas
 *
 *  Created by roberto on Mon Oct 27 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#include "geometricatlas.h"

void ga_getClusterSize(MeshPtr m, float3D *gm, float *vct, float *alpha, float *beta)
{
    float3D	*p,a;
    float	amean,astd,bstd,x,anorm;
    double2D	bmean,b,zero={0,0};
    int		i;
    double	n;
    
    p=msh_getPointsPtr(m);
    
    amean=0;
    bmean=zero;
    astd=0;
    n=0;

    for(i=0;i<(*m).np;i++)
    {
        if(vct[i]>=0)
        {
            a=em_getPointFromSphericalCoordinate(gm[i]);
            a=stereographic(a);

            amean+=norm2D((double2D){a.x,a.y});
            bmean=sub2D(bmean,(double2D){a.x,a.y});
            astd+=pow(norm2D((double2D){a.x,a.y}),2);
            n++;
        }
    }
    amean=amean/n;
    bmean=sca2D(bmean,1/n);
    astd=sqrt(astd/n-amean*amean);	//n*std^2=SUM(x^2)-n*Mean(x)^2
    printf("alpha=%f +/- %f\n", amean*180/pi, astd*180/pi);
    
    b=sca2D(bmean,1/norm2D(bmean));
    bstd=0;

    for(i=0;i<(*m).np;i++)
    {
        if(vct[i]>=0)
        {
            a=em_getPointFromSphericalCoordinate(gm[i]);
            a=stereographic(a);
            anorm=sqrt(a.x*a.x+a.y*a.y);

            x=dot2D(b,(double2D){a.x/anorm,a.y/anorm});
            bstd+=pow(acos(fabs(x)),2);
        }
    }
    bstd=sqrt(bstd/n);
    printf("beta=%f +/- %f\n", atan2(bmean.y,bmean.x)*180/pi, bstd*180/pi);
    
    alpha[0]=amean*180/pi;
    alpha[1]=astd*180/pi;
    beta[0]=atan2(bmean.y,bmean.x)*180/pi;
    beta[1]=bstd*180/pi;
}
void ga_findClusters(MeshPtr m, float3D *gm, float *vct, float *alpha, float *beta)
{
    // projection of the reconstruction
    // projection of the activity
    // projection of the distortion
    // integrate activity ponderated by distortion
    float3D	*p,a;
    float	amean,astd,bstd,x,anorm;
    double2D	bmean,b,zero={0,0};
    int		i;
    double	n;
    
    p=msh_getPointsPtr(m);
    
    amean=0;
    bmean=zero;
    astd=0;
    n=0;

    for(i=0;i<(*m).np;i++)
    {
        if(vct[i]>=0)
        {
            a=em_getPointFromSphericalCoordinate(gm[i]);
            a=stereographic(a);

            amean+=norm2D((double2D){a.x,a.y});
            bmean=sub2D(bmean,(double2D){a.x,a.y});
            astd+=pow(norm2D((double2D){a.x,a.y}),2);
            n++;
        }
    }
    amean=amean/n;
    bmean=sca2D(bmean,1/n);
    astd=sqrt(astd/n-amean*amean);	//n*std^2=SUM(x^2)-n*Mean(x)^2
    printf("alpha=%f +/- %f\n", amean*180/pi, astd*180/pi);
    
    b=sca2D(bmean,1/norm2D(bmean));
    bstd=0;

    for(i=0;i<(*m).np;i++)
    {
        if(vct[i]>=0)
        {
            a=em_getPointFromSphericalCoordinate(gm[i]);
            a=stereographic(a);
            anorm=sqrt(a.x*a.x+a.y*a.y);

            x=dot2D(b,(double2D){a.x/anorm,a.y/anorm});
            bstd+=pow(acos(fabs(x)),2);
        }
    }
    bstd=sqrt(bstd/n);
    printf("beta=%f +/- %f\n", atan2(bmean.y,bmean.x)*180/pi, bstd*180/pi);
    
    alpha[0]=amean*180/pi;
    alpha[1]=astd*180/pi;
    beta[0]=atan2(bmean.y,bmean.x)*180/pi;
    beta[1]=bstd*180/pi;
}