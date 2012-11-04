/*
 *  talairach.c
 *  Geometric Atlas Cocoa
 *
 *  Created by roberto on Sun Oct 05 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#include "talairach.h"

void tal_parseScript(char *txt, int size, ClusterRec **cr, int *ncr, bool fillcr, bool fillc)
{
    int		i=0,j,nc;
    char	stop,word[256]="\pUntitled";
    float	sag,cor,axi;
    int		type;

    *ncr=0;
	nc=0;
	do
	{
		type=getcharfromtxt(&i,txt,&stop);
		switch(type)
		{
			case 1: // coordinates
				sag=getnumfromtxt(&i, txt,&stop);
				cor=getnumfromtxt(&i, txt,&stop);
				axi=getnumfromtxt(&i, txt,&stop);
				if(fillc==true)
				{
					(*cr)[*ncr].c[0+3*nc]=sag;
					(*cr)[*ncr].c[1+3*nc]=cor;
					(*cr)[*ncr].c[2+3*nc]=axi;
				}
				nc++;
				break;
			case 2: // key
				if( txt[i+0]=='k' &&
					txt[i+1]=='e' &&
					txt[i+2]=='y')
				{
					if(nc>0)
					{
						if(fillcr==true)
						{
							for(j=0;j<word[0];j++)
								(*cr)[*ncr].key[j]=word[j+1];
							(*cr)[*ncr].nc=nc;
							(*cr)[*ncr].visible=true;
							(*cr)[*ncr].fraction=0.7;
						}
						*ncr+=1;
						nc=0;
					}	

					do{ type=getcharfromtxt(&i,txt,&stop);  i++;}while(type!=3);
					getwordfromtxt(&i,txt,word);
				}
				break;
		}
	}
	while(i<size);

	if(nc>0)
	{
		if(fillcr==true)
		{
			for(j=0;j<word[0];j++)
				(*cr)[*ncr].key[j]=word[j+1];
			(*cr)[*ncr].nc=nc;
			(*cr)[*ncr].visible=true;
			(*cr)[*ncr].fraction=0.7;
		}
		*ncr+=1;
	}
}

#pragma mark -
#pragma mark [   talairach on mesh   ]
int tal_projectTalairachOnVerticesData(MeshPtr m, float *M, float *c, int nc, float distance, float *vc,int hemisphere)
{
    // input: m=mesh, M=talairach matrix, c=tal coords vector, nc=nbr. coordinates, distance=radius
    // output: vc= vertices colour
    float3D	*tal;
    float3D	*p;
    float3D	pp;
    float	d;
    int		i,j;
    int		err=0;
    float	dist=distance*3/100.0;
	
	int3D   *T;
	double   sum,csum;

    tal=(float3D*)c;
    p = msh_getPointsPtr(m);

    for(j=0;j<nc;j++)
	{
		//printf("\t%i/%i\n",j,nc);
		if((hemisphere==0 && tal[j].x<=0)||(hemisphere==1 && tal[j].x>=0))
		{
			if(hemisphere==0) tal[j].x*=-1;
			tal_getPointFromTalairach((float*)&pp,(float*)&tal[j],M);
			for(i=0;i<(*m).np;i++)
			{
				d=norm3D(sub3D(p[i],pp));
				
				if(d<dist)
				{
					if(vc[i]==-1 || vc[i]<1-d/dist)
						vc[i]=1-d/dist;
				}
			}
		}
	}
    for(i=0;i<(*m).np;i++) if(vc[i]>1) vc[i]=1;
	
	//TEST
	T=msh_getTrianglesPtr(m);
	csum=sum=0;
	for(i=0;i<(*m).nt;i++)
	{
		sum+=tTriArea(m,i);
		if(vc[T[i].a]>0||vc[T[i].b]>0||vc[T[i].c]>0)
			csum+=tTriArea(m,i);
	}
	printf("cluster:%f\ttotal:%f\tc/t:%f%c\n",10000*csum,10000*sum,csum/sum,'%');
	//END TEST

    return err;
}

int tal_smoothTalairachVerticesData(MeshPtr m, float *vct)
{
    int		i,j,err=0;
    float	dist;
    float3D	*p;
    float3D	*C;
    float	*X;
    int2D	*E;
    NEdgeRec	*NE;
    int		pstack[SIZESTACK],estack[SIZESTACK];

    p=msh_getPointsPtr(m);
    C=(float3D*)vct;
    E = msh_getEdgesPtr(m);		// Edges of the mesh
    NE = msh_getNeighborEdgesPtr(m);	// Neighbor Edges for each point
    X=fvector_new((*m).np);
    
    for(i=0;i<(*m).np;i++)
    {
        dist=0;
             if(C[i].x==1 && C[i].y==0 && C[i].z==0)	dist=1;
        else if(C[i].x==0 && C[i].y==1 && C[i].z==0)	dist=2;
        else if(C[i].x==0 && C[i].y==0 && C[i].z==1)	dist=3;
        X[i]=dist;
    }

    for(i=0;i<(*m).np;i++)
    {
        msh_esort(m,i,pstack,estack);
        dist=0;
        for(j=0;j<NE[i].n;j++)
            dist+=X[pstack[j]];
        dist/=NE[i].n;
        if(dist>2.5)
            C[i]=(float3D){1,0,0};
        else
        if(dist>1.5)
            C[i]=(float3D){0,1,0};
        else
        if(dist>0.5)
            C[i]=(float3D){0,0,1};
        else
        if(dist>0)
            C[i]=(float3D){0,0,0};
    }
    fvector_dispose(X);

    return err;
}
#pragma mark -
#pragma mark [   Project data on geometric model   ]
/*int tal_projectVerticesDataOnGeometricModel(MeshPtr m, float3D *gm, float *vct, unsigned char *it, int bytesPerPixel, int width, int height)
{
    // input: m=mesh, gm=geometric model, vct=vertices colours, bytesPerPixel, width, height
    // output: bytes at it=Image Talairach base address
    int		i,n,err=0;
    int		a_dist,b_dist,c_dist;
    float	dist;
    int		colour[3];
    float3D	a,b,c;
    float3D	*p;
    int3D	*T;
    float3D	*C;
    
    p=msh_getPointsPtr(m);
    T=msh_getTrianglesPtr(m);
    C=(float3D*)vct;
    
    for(i=0;i<(*m).nt;i++)
    {
        a_dist=b_dist=c_dist=0;
             if(C[T[i].a].x==1 && C[T[i].a].y==0 && C[T[i].a].z==0)	a_dist=1;
        else if(C[T[i].a].x==0 && C[T[i].a].y==1 && C[T[i].a].z==0)	a_dist=2;
        else if(C[T[i].a].x==0 && C[T[i].a].y==0 && C[T[i].a].z==1)	a_dist=3;
             if(C[T[i].b].x==1 && C[T[i].b].y==0 && C[T[i].b].z==0)	b_dist=1;
        else if(C[T[i].b].x==0 && C[T[i].b].y==1 && C[T[i].b].z==0)	b_dist=2;
        else if(C[T[i].b].x==0 && C[T[i].b].y==0 && C[T[i].b].z==1)	b_dist=3;
             if(C[T[i].c].x==1 && C[T[i].c].y==0 && C[T[i].c].z==0)	c_dist=1;
        else if(C[T[i].c].x==0 && C[T[i].c].y==1 && C[T[i].c].z==0)	c_dist=2;
        else if(C[T[i].c].x==0 && C[T[i].c].y==0 && C[T[i].c].z==1)	c_dist=3;

        n=(a_dist!=0) + (b_dist!=0) + (c_dist!=0);
        if(n)
        {
            dist=(a_dist+b_dist+c_dist)/(float)n;
            colour[0]=colour[1]=colour[2]=0;
            switch((int)dist)
            {   case 1: colour[0]=255;	break;
                case 2: colour[1]=255;	break;
                case 3: colour[2]=255;	break;
            }
            a=em_getPointFromSphericalCoordinate(gm[T[i].a]);
            b=em_getPointFromSphericalCoordinate(gm[T[i].b]);
            c=em_getPointFromSphericalCoordinate(gm[T[i].c]);
            
            a=stereographic(a);a.y=-a.y;
            b=stereographic(b);b.y=-b.y;
            c=stereographic(c);c.y=-c.y;

            PaintTriangle(colour,a,b,c,it,bytesPerPixel, width, height);
        }
    }

    return err;
}
*/
void swap(int *ta, int *tb, float *ca, float *cb);
void swap(int *ta, int *tb, float *ca, float *cb)
{
    int tx[2]={ta[0],ta[1]};
    float cx=*ca;
    
    ta[0]=tb[0];
    ta[1]=tb[1];
    tb[0]=tx[0];
    tb[1]=tx[1];
    
    *ca=*cb;
    *cb=cx;
}
void PaintTriangle(float *c, int colourmap, float3D A, float3D B, float3D C, unsigned char *it, int bytesPerPixel, int width, int height)
{
    int	x,y,i;
    double af,bf;
    int ai,bi,d;
    int	t[6];
    double	s0,s1,t0,t1,st;
    double	a0,b0,a1,b1;
    double	n,e;
    float	colour,xcolour[3];

    t[0]=(int)(0.5+ 0.5*width*(A.x/pi+1));
    t[1]=(int)(0.5+ 0.5*height*(A.y/pi+1));
    t[2]=(int)(0.5+ 0.5*width*(B.x/pi+1));
    t[3]=(int)(0.5+ 0.5*height*(B.y/pi+1));
    t[4]=(int)(0.5+ 0.5*width*(C.x/pi+1));
    t[5]=(int)(0.5+ 0.5*height*(C.y/pi+1));

    // sort
    if(t[0]<=t[4] && t[4]<=t[2]){swap(&t[2],&t[4], &c[1],&c[2]);}
    if(t[2]<=t[0] && t[0]<=t[4]){swap(&t[0],&t[2], &c[0],&c[1]);}
    if(t[2]<=t[4] && t[4]<=t[0]){swap(&t[0],&t[2], &c[0],&c[1]); swap(&t[2],&t[4], &c[1],&c[2]);}
    if(t[4]<=t[0] && t[0]<=t[2]){swap(&t[0],&t[4], &c[0],&c[2]); swap(&t[2],&t[4], &c[1],&c[2]);}
    if(t[4]<=t[2] && t[2]<=t[0]){swap(&t[0],&t[4], &c[0],&c[2]);}
    
    s0=t[2]-t[0];
    s1=t[3]-t[1];
    t0=t[4]-t[0];
    t1=t[5]-t[1];
    st=t0*s1-t1*s0;
    
    if(!st)	return;

    a0=t1/st;
    b0=t0/st;
    a1=s1/st;
    b1=s0/st;
    
    #define round(a) (int)(0.5+(a))

    // subtriangle 1
    for(x=t[0];x<t[2];x++)
    {
        af=t[1]+(x-t[0])/(float)s0*s1;
        bf=t[1]+(x-t[0])/(float)t0*t1;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(s0)
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i*d;

            if(i==0)	      {	n=(x-t[0])*((s1*b0)/s0-a0);
                                e=(x-t[0])*(a1-(s1*b1)/s0);}
            else
            if(i==fabs(bi-ai)){	n=(x-t[0])*((t1*b0)/t0-a0);
                                e=(x-t[0])*(a1-(t1*b1)/t0);}
            else
                              {	n=(y-t[1])*b0-(x-t[0])*a0;
                                e=(x-t[0])*a1-(y-t[1])*b1;}
            
            n=round(n*255)/255.0;
            e=round(e*255)/255.0;

            colour=c[0]+n*(c[1]-c[0])+e*(c[2]-c[0]);

            if(colour>=0)
            {
                colourFromColourmap(colour ,xcolour,colourmap);

                it[(int)(bytesPerPixel*(y*width+x))+0]=xcolour[0]*255;
                it[(int)(bytesPerPixel*(y*width+x))+1]=xcolour[1]*255;
                it[(int)(bytesPerPixel*(y*width+x))+2]=xcolour[2]*255;
                if(bytesPerPixel==4)
                it[(int)(bytesPerPixel*(y*width+x))+3]=255;//alpha
            }
        }
    }
    // subtriangle 2
    for(x=t[2];x<t[4];x++)
    {
        af=t[3]+(x-t[2])/(float)(t[4]-t[2])*(t[5]-t[3]);
        bf=t[1]+(x-t[0])/(float)t0*t1;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(t[4]-t[2])
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i*d;

            if(i==0)	      {	n=(af-t[1])*b0-(x-t[0])*a0;
                                e=(x-t[0])*a1-(af-t[1])*b1;}
            else
            if(i==fabs(bi-ai)){	n=(bf-t[1])*b0-(x-t[0])*a0;
                                e=(x-t[0])*a1-(bf-t[1])*b1;}
            else
                              {	n=(y-t[1])*b0-(x-t[0])*a0;
                                e=(x-t[0])*a1-(y-t[1])*b1;}

            n=round(n*255)/255.0;
            e=round(e*255)/255.0;

            colour=c[0]+n*(c[1]-c[0])+e*(c[2]-c[0]);
            if(colour>=0)
            {
                colourFromColourmap(colour ,xcolour,colourmap);

                it[(int)(bytesPerPixel*(y*width+x))+0]=xcolour[0]*255;
                it[(int)(bytesPerPixel*(y*width+x))+1]=xcolour[1]*255;
                it[(int)(bytesPerPixel*(y*width+x))+2]=xcolour[2]*255;
                if(bytesPerPixel==4)
                it[(int)(bytesPerPixel*(y*width+x))+3]=255;//alpha
            }
        }
    }
    #undef round(a)
}

int tal_projectVerticesDataOnGeometricModel(MeshPtr m, float3D* gm, float* vct, unsigned char *it, int bytesPerPixel, int width, int height, int colourmap)
{
    int		i,err=0;
    float	colour[3];
    float3D	a,b,c;
    float3D	*p;
    int3D	*T;
    float3D	*C;
    
    p=msh_getPointsPtr(m);
    T=msh_getTrianglesPtr(m);
    C=(float3D*)vct;
    
    //i=4680;
	for(i=0;i<(*m).nt;i++)
    if(vct[T[i].a]>=0||vct[T[i].b]>=0||vct[T[i].c]>=0)
    {
        colour[0]=vct[T[i].a];
        colour[1]=vct[T[i].b];
        colour[2]=vct[T[i].c];

        a=em_getPointFromSphericalCoordinate(gm[T[i].a]);
        b=em_getPointFromSphericalCoordinate(gm[T[i].b]);
        c=em_getPointFromSphericalCoordinate(gm[T[i].c]);
        
        a=stereographic(a);a.y=-a.y;
        b=stereographic(b);b.y=-b.y;
        c=stereographic(c);c.y=-c.y;
        
        if( norm3D(sub3D(a,b))<0.5*pi &&
            norm3D(sub3D(b,c))<0.5*pi &&
            norm3D(sub3D(c,a))<0.5*pi)
        {
            PaintTriangle(colour,colourmap,a,b,c,it,bytesPerPixel, width, height);
            //break;
        }
    }

    return err;
}
#pragma mark -
void swap2D(float *ta, float *tb, float *Ta, float *Tb);
void swap2D(float *ta, float *tb, float *Ta, float *Tb)
{
    float tx[2]={ta[0],ta[1]};
    float Tx[2]={Ta[0],Ta[1]};
    
    ta[0]=tb[0];
    ta[1]=tb[1];
    tb[0]=tx[0];
    tb[1]=tx[1];
    
    Ta[0]=Tb[0];
    Ta[1]=Tb[1];
	Tb[0]=Tx[0];
	Tb[1]=Tx[1];
}
void swap_(int *a, int *b);
void swap_(int *a, int *b)
{
    int c=*a;
	
	*a=*b;
	*b=c;
}
int triangleArea(float3D *gt, int width, int height)
// Compute the number of pixels that will paint a triangle...
// Input
//		gt: the triangle
//		width:  width of the buffer
//		height: height of the buffer
// Output
//		The number of pixels
{
    int x,y,i;
    double af,bf;
    int ai,bi,d;
	int		t[6];
    double	s0,s1,t0,t1/*,st*/;
	int		_0=0,_1=1,_2=2,_3=3,_4=4,_5=5;
	int		n=0;

	for(i=0;i<3;i++)
	{   t[i*2+0]=(int)(0.5+0.5* width*(gt[i].x/pi+1));
		t[i*2+1]=(int)(0.5+0.5*height*(gt[i].y/pi+1));
	}

    // sort
    if(t[_0]<=t[_4] && t[_4]<=t[_2]){swap_(&_2,&_4);}
    if(t[_2]<=t[_0] && t[_0]<=t[_4]){swap_(&_0,&_2);}
    if(t[_2]<=t[_4] && t[_4]<=t[_0]){swap_(&_0,&_2); swap_(&_2,&_4);}
    if(t[_4]<=t[_0] && t[_0]<=t[_2]){swap_(&_0,&_4); swap_(&_2,&_4);}
    if(t[_4]<=t[_2] && t[_2]<=t[_0]){swap_(&_0,&_4);}
	_1=_0+1;
	_3=_2+1;
	_5=_4+1;
    
    // Auxiliary geometric variables
	s0=t[_2]-t[_0];
    s1=t[_3]-t[_1];
    t0=t[_4]-t[_0];
    t1=t[_5]-t[_1];
    //st=t0*s1-t1*s0;
    //if(!st)	return n;

    // subtriangle 1
    for(x=t[_0];x<t[_2];x++)
    {
        af=t[_1]+(x-(int)t[_0])/(float)s0*s1;
        bf=t[_1]+(x-(int)t[_0])/(float)t0*t1;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(s0)
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i*d;
			n++;
        }
    }
    // subtriangle 2
    for(x=t[_2];x<t[_4];x++)
    {
        af=t[_3]+(x-(int)t[_2])*(t[_5]-t[_3])/(float)(t[_4]-t[_2]);
        bf=t[_1]+(x-(int)t[_0])*t1/(float)t0;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(t[_4]-t[_2])
        for(i=0;i<=fabs(bi-ai);i++)
        {
			y=ai+i*d;
			n++;
        }
    }
	
	return n;
}
/*int PaintTriangleArea(int colour, float3D *gt, unsigned char *it, int bytesPerPixel, int width, int height)
// Paint the area of a pixel in the projection with the area of the corresponding deformed quadrilateral in the original mesh
// Input
//		ba, ca: vectors b-a and c-a of the original mesh triangle projected to 2D
//		A,B,C:  corresponding coordinates for the triangle in the GM projection
//		it:		buffer to receive the image
//		byt...: ditto
//		width:  width of the buffer
//		height: height of the buffer
// Output
//		The image of the corresponding area in *it
{
    int	x,y,i;
    double af,bf;
    int ai,bi,d;
	int		t[6];
    double	s0,s1,t0,t1;//,st;
	int		_0=0,_1=1,_2=2,_3=3,_4=4,_5=5;
	int		c,c0,R,G,B;
	int		n=0;

	for(i=0;i<3;i++)
	{   t[i*2+0]=(int)(0.5+0.5* width*(gt[i].x/pi+1));
		t[i*2+1]=(int)(0.5+0.5*height*(gt[i].y/pi+1));
	}

    // sort
    if(t[_0]<=t[_4] && t[_4]<=t[_2]){swap_(&_2,&_4);}
    if(t[_2]<=t[_0] && t[_0]<=t[_4]){swap_(&_0,&_2);}
    if(t[_2]<=t[_4] && t[_4]<=t[_0]){swap_(&_0,&_2); swap_(&_2,&_4);}
    if(t[_4]<=t[_0] && t[_0]<=t[_2]){swap_(&_0,&_4); swap_(&_2,&_4);}
    if(t[_4]<=t[_2] && t[_2]<=t[_0]){swap_(&_0,&_4);}
	_1=_0+1;
	_3=_2+1;
	_5=_4+1;
    
    // Auxiliary geometric variables
	s0=t[_2]-t[_0];
    s1=t[_3]-t[_1];
    t0=t[_4]-t[_0];
    t1=t[_5]-t[_1];
    //st=t0*s1-t1*s0;
    //if(!st)	return n;

    // subtriangle 1
    for(x=t[_0];x<t[_2];x++)
    {
        af=t[_1]+(x-(int)t[_0])/(float)s0*s1;
        bf=t[_1]+(x-(int)t[_0])/(float)t0*t1;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(s0)
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i*d;
			R=it[(int)(bytesPerPixel*(y*width+x))+0];
			G=it[(int)(bytesPerPixel*(y*width+x))+1];
			B=it[(int)(bytesPerPixel*(y*width+x))+2];
			c0=(R<<16)+(G<<8)+B;
			c=colour+c0;
			if(c>0xffffff) c=0xffffff;
			it[(int)(bytesPerPixel*(y*width+x))+0]=(c&0xff0000)>>16;
			it[(int)(bytesPerPixel*(y*width+x))+1]=(c&0xff00)>>8;
			it[(int)(bytesPerPixel*(y*width+x))+2]=(c&0xff);
			if(bytesPerPixel==4)
			it[(int)(bytesPerPixel*(y*width+x))+3]=255;//alpha
			n++;
        }
    }
    // subtriangle 2
    for(x=t[_2];x<t[_4];x++)
    {
        af=t[_3]+(x-(int)t[_2])*(t[_5]-t[_3])/(float)(t[_4]-t[_2]);
        bf=t[_1]+(x-(int)t[_0])*t1/(float)t0;
        ai=round(af);
        bi=round(bf);
        d=(ai<=bi)?1:(-1);
        if(t[_4]-t[_2])
        for(i=0;i<=fabs(bi-ai);i++)
        {
			y=ai+i*d;
			R=it[(int)(bytesPerPixel*(y*width+x))+0];
			G=it[(int)(bytesPerPixel*(y*width+x))+1];
			B=it[(int)(bytesPerPixel*(y*width+x))+2];
			c0=(R<<16)+(G<<8)+B;
			c=colour+c0;
			if(c>0xffffff) c=0xffffff;
			it[(int)(bytesPerPixel*(y*width+x))+0]=(c&0xff0000)>>16;
			it[(int)(bytesPerPixel*(y*width+x))+1]=(c&0x00ff00)>>8;
			it[(int)(bytesPerPixel*(y*width+x))+2]=(c&0x0000ff);
			if(bytesPerPixel==4)
			it[(int)(bytesPerPixel*(y*width+x))+3]=255;//alpha
			n++;
        }
    }
	return n;
}
int tal_projectAreaOnGeometricModel(MeshPtr m, float3D* gm, unsigned char *it, int bytesPerPixel, int width, int height)
{
    int		i,j,k,err=0;
	float3D t[3],ot[3];
    float3D	*p;
    int3D	*T;
	float   mean,std;
	double  n,aot,at,da,maxda=-1,ar,tot,pxtot;
	int		colour,px;
	int		R,G,B,A;
    
    p=msh_getPointsPtr(m);
    T=msh_getTrianglesPtr(m);
	
	std=mean=0;
	for(k=0;k<2;k++)
	{
		ar=tot=0;
		pxtot=0;
		n=0;
		for(i=0;i<(*m).nt;i++)
		{
			ot[0]=p[T[i].a];
			ot[1]=p[T[i].b];
			ot[2]=p[T[i].c];
			aot=10000*triArea(ot[0],ot[1],ot[2]);
			tot+=aot;

			t[0]=em_getPointFromSphericalCoordinate(gm[T[i].a]);
			t[1]=em_getPointFromSphericalCoordinate(gm[T[i].b]);
			t[2]=em_getPointFromSphericalCoordinate(gm[T[i].c]);
			for(j=0;j<3;j++)
			{   t[j]=stereographic(t[j]);t[j].y=-t[j].y;}
			if( norm3D(r3D(t[0],t[1]))<0.95*pi &&
				norm3D(r3D(t[1],t[2]))<0.95*pi &&
				norm3D(r3D(t[2],t[0]))<0.95*pi)
			{
				at=triangleArea(t,width,height);
				//if(k==0&&i%1000==0) printf("%f\t%f\n",at,da);
				if(at)
				{
					n++;
					da=aot/at;
					ar+=aot;
					if(k==0)
					{
						mean+=da;
						std+=da*da;
					}
					else
					{
						colour=round((da/maxda)*0xffffff);
						if(colour>0xffffff) colour=0xffffff;
						if(colour<0) printf("-1\n");

						px=PaintTriangleArea(colour, t, it,bytesPerPixel,width,height);
						pxtot+=px*maxda*colour/(double)0xffffff;
					}
				}
			}
		}
		if(k==0)
		{   mean=mean/n;
			std=sqrt((std-mean*mean*n)/(n-1.0));
			maxda=mean+20*std;
			printf("mean:%f std:%f\n",mean,std);
			printf("max pixel area: %f\n",maxda);
		}
		else
		{   printf("rep.area: %f, total area: %f, ar/tot: %f%c\n",ar,tot,ar/tot*100,'%');
			printf("px.tot: %f\n",pxtot);
		}
	}

	//
	pxtot=0;
	for(i=0;i<width;i++)
	for(j=0;j<height;j++)
	{   R=*(it+j*width*4+i*4+0);
		G=*(it+j*width*4+i*4+1);
		B=*(it+j*width*4+i*4+2);
		A=*(it+j*width*4+i*4+3);
		if(A)
		{   //da=maxda*(R/(double)0xff+G/(double)0xffff+B/(double)0xffffff);
			colour=(R<<16)+(G<<8)+B;
			if(colour<0)
				printf("-1\n");
			pxtot+=maxda*colour/(double)0xffffff;
		}
	}
	printf("total:%f\n",pxtot);
	//

    return err;
}
*/
double PaintTriangleAreaDistortion(double aot, double2D *gt, unsigned char *it, int bytesPerPixel, int width, int height)
// Paint the area of a pixel in the projection of GM with the percentage of area
// corresponding to the intersecting triangles in the original mesh
// Input
//		aot: original triangle area
//		gt: corresponding GM triangle
//		it:		buffer to receive the image
//		byt...: ditto
//		width:  width of the buffer
//		height: height of the buffer
// Output
//		The image of the corresponding area in *it
{
    double		x,y;
	int			i,ai,bi;
	double		agm,val,maxval=0;
	double		T[6],t[6];
    double		s0,s1,t0,t1,u0,u1;
	int			_0=0,_1=1,_2=2,_3=3,_4=4,_5=5;

	for(i=0;i<3;i++)
	{   gt[i]=(double2D){0.5* width*(gt[i].x/pi+1),0.5*height*(gt[i].y/pi+1)};
		T[i*2+0]=gt[i].x;
		T[i*2+1]=gt[i].y;
	}
	agm=triangleArea2D(gt);

    // sort
    if(T[_0]<=T[_4] && T[_4]<=T[_2]){swap_(&_2,&_4);}
    if(T[_2]<=T[_0] && T[_0]<=T[_4]){swap_(&_0,&_2);}
    if(T[_2]<=T[_4] && T[_4]<=T[_0]){swap_(&_0,&_2); swap_(&_2,&_4);}
    if(T[_4]<=T[_0] && T[_0]<=T[_2]){swap_(&_0,&_4); swap_(&_2,&_4);}
    if(T[_4]<=T[_2] && T[_2]<=T[_0]){swap_(&_0,&_4);}
	_1=_0+1;
	_3=_2+1;
	_5=_4+1;
	t[0]=T[_0];t[1]=T[_1];t[2]=T[_2];t[3]=T[_3];t[4]=T[_4];t[5]=T[_5];
    
    // Auxiliary geometric variables
	s0=t[2]-t[0];
    s1=t[3]-t[1];
    t0=t[4]-t[0];
    t1=t[5]-t[1];
    u0=t[4]-t[2];
    u1=t[5]-t[3];
    //st=t0*s1-t1*s0;
    //if(!st)	return 0;

    // initial point
	x=t[0];
	chooselimits0(t,x,s0,s1,t0,t1,&ai,&bi);
	for(i=0;i<=fabs(bi-ai);i++)
	{
		y=ai+i;
		val=paintpixel(it,bytesPerPixel,width,x,y,aot,agm,gt);
		if(val>maxval) maxval=val;
	}
	
	// subtriangle 1
    for(x=(int)t[0]+1;x<t[2];x++)
    {
        chooselimits1(t,x,s0,s1,t0,t1,&ai,&bi);		
        if(s0)
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i;
			val=paintpixel(it,bytesPerPixel,width,x,y,aot,agm,gt);
			if(val>maxval) maxval=val;
        }
    }
    // subtriangle 2
    for(x=ceil(t[2]);x<t[4];x++)
    {
		chooselimits2(t,x,u0,u1,t0,t1,&ai,&bi);
        if(u0)
        for(i=0;i<=fabs(bi-ai);i++)
        {
            y=ai+i;
			val=paintpixel(it,bytesPerPixel,width,x,y,aot,agm,gt);
			if(val>maxval) maxval=val;
        }
    }

	return maxval;
}
double paintpixel(unsigned char *it, int bytesPerPixel, int width, int x, int y,double aot, double agm, double2D *gt)
{
	int R,G,B;
	int c,c0;
	double aint,val;
	double2D	sq[4];
	
	if(y<0||y>=width||x<0||x>=width) return 0;

	R=it[(int)(bytesPerPixel*(((int)y)*width+((int)x)))+0];
	G=it[(int)(bytesPerPixel*(((int)y)*width+((int)x)))+1];
	B=it[(int)(bytesPerPixel*(((int)y)*width+((int)x)))+2];
	c0=(R<<16)+(G<<8)+B;
	sq[0]=(double2D){(int)x,(int)y};
	sq[1]=(double2D){(int)x+1,(int)y};
	sq[2]=(double2D){(int)x+1,(int)y+1};
	sq[3]=(double2D){(int)x,(int)y+1};
	//printf("sq=[%f %f;%f %f;%f %f;%f %f;%f %f];plot(sq(:,1),sq(:,2))\n",sq[0].x,sq[0].y,sq[1].x,sq[1].y,sq[2].x,sq[2].y,sq[3].x,sq[3].y,sq[0].x,sq[0].y);
	aint=areaOfTriangleInSquare2D(gt,sq);
	val=aot*aint/agm; 
	c=val*0xffffff+c0;
	if(c>0xffffff) c=0xffffff;
	it[(int)(bytesPerPixel*(y*width+x))+0]=(c&0xff0000)>>16;
	it[(int)(bytesPerPixel*(y*width+x))+1]=(c&0xff00)>>8;
	it[(int)(bytesPerPixel*(y*width+x))+2]=(c&0xff);
	if(bytesPerPixel==4)
	it[(int)(bytesPerPixel*(y*width+x))+3]=255;//alpha
	
	return val;
}
void chooselimits0(double *t, double x,double s0, double s1, double t0, double t1, int *ai, int *bi)
{
	double af,af1,bf,bf1,min,max;
	
	
	if(s1/s0<=t1/t0)
	{
		af=t[1]+(x-t[0])/s0*s1;
		af1=t[1]+((int)x+1-t[0])/s0*s1;
		bf=t[1]+(x-t[0])/t0*t1;
		bf1=t[1]+((int)x+1-t[0])/t0*t1;
		if(s1/s0>=0)	*ai=(int)(t[1]+(x-t[0])/s0*s1);
		else			*ai=(int)(t[1]+(x+1-t[0])/s0*s1);
		if(t1/t0>=0)	*bi=(int)(t[1]+(x+1-t[0])/t0*t1);
		else			*bi=(int)(t[1]+(x-t[0])/t0*t1);
	}
	else
	{
		af=t[1]+(x-t[0])/t0*t1;
		af1=t[1]+((int)x+1-t[0])/t0*t1;
		bf=t[1]+(x-t[0])/s0*s1;
		bf1=t[1]+((int)x+1-t[0])/s0*s1;
		if(t1/t0>=0)	*ai=(int)(t[1]+(x-t[0])/t0*t1);
		else			*ai=(int)(t[1]+((int)x+1-t[0])/t0*t1);
		if(s1/s0>=0)	*bi=(int)(t[1]+((int)x+1-t[0])/s0*s1);
		else			*bi=(int)(t[1]+(x-t[0])/s0*s1);
	}
	min=t[1];
	if(t[3]<min) min=t[3];
	if(t[5]<min) min=t[5];
	if(*ai<min){ printf("ai: look at this %i\n",*ai);*ai=min;}
	max=t[1];
	if(t[3]>max) max=t[3];
	if(t[5]>max) max=t[5];
	if(*bi>max){ printf("bi: look at this %i\n",*bi);*bi=max;}
}

void chooselimits1(double *t, int x,double s0, double s1, double t0, double t1, int *ai, int *bi)
{
	double af,af1,bf,bf1;
	
	if(s1/s0<=t1/t0)
	{
		af=t[1]+(x-t[0])/s0*s1;
		af1=t[1]+(x+1-t[0])/s0*s1;
		bf=t[1]+(x-t[0])/t0*t1;
		bf1=t[1]+(x+1-t[0])/t0*t1;
		if(s1/s0>=0)	*ai=(int)(t[1]+(x-t[0])/s0*s1);
		else			*ai=(int)(t[1]+(x+1-t[0])/s0*s1);
		if(t1/t0>=0)	*bi=(int)(t[1]+(x+1-t[0])/t0*t1);
		else			*bi=(int)(t[1]+(x-t[0])/t0*t1);
	}
	else
	{
		af=t[1]+(x-t[0])/t0*t1;
		af1=t[1]+(x+1-t[0])/t0*t1;
		bf=t[1]+(x-t[0])/s0*s1;
		bf1=t[1]+(x+1-t[0])/s0*s1;
		if(t1/t0>=0)	*ai=(int)(t[1]+(x-t[0])/t0*t1);
		else			*ai=(int)(t[1]+(x+1-t[0])/t0*t1);
		if(s1/s0>=0)	*bi=(int)(t[1]+(x+1-t[0])/s0*s1);
		else			*bi=(int)(t[1]+(x-t[0])/s0*s1);
	}
}
void chooselimits2(double *t, int x,double u0, double u1, double t0, double t1, int *ai, int *bi)
{
	double af,af1,bf,bf1;
	
	if(u1/u0<=t1/t0)
	{
        af=t[1]+(x-t[0])*t1/t0;
        af1=t[1]+(x+1-t[0])*t1/t0;
        bf=t[3]+(x-t[2])/u0*u1;
        bf1=t[3]+(x+1-t[2])/u0*u1;

		if(t1/t0>=0)	*ai=(int)(t[1]+(x-t[0])*t1/t0);
		else			*ai=(int)(t[1]+(x+1-t[0])*t1/t0);
		if(u1/u0>=0)	*bi=(int)(t[3]+(x+1-t[2])/u0*u1);
		else			*bi=(int)(t[3]+(x-t[2])/u0*u1);
	}
	else
	{
        af=t[3]+(x-t[2])/u0*u1;
        af1=t[3]+(x+1-t[2])/u0*u1;
        bf=t[1]+(x-t[0])*t1/t0;
        bf1=t[1]+(x+1-t[0])*t1/t0;

		if(u1/u0>=0)	*ai=(int)(t[3]+(x-t[2])/u0*u1);
		else			*ai=(int)(t[3]+(x+1-t[2])/u0*u1);
		if(t1/t0>=0)	*bi=(int)(t[1]+(x+1-t[0])*t1/t0);
		else			*bi=(int)(t[1]+(x-t[0])*t1/t0);
	}
}
int tal_projectAreaOnGeometricModel(MeshPtr m, float3D* gm, unsigned char *it, int bytesPerPixel, int width, int height)
{
    int		i,j,err=0;
	float3D tmp[3],ot[3];
    float3D	*p;
    int3D	*T;
	double2D t[3];
	double  aot,maxval,globalmaxval=0,k=1000000;
    
    p=msh_getPointsPtr(m);
    T=msh_getTrianglesPtr(m);
	
	printf("starting\n");
	for(i=0;i<(*m).nt;i++)
	{
		//if(i%((*m).nt/100)==0) printf("%i%c\n",100*i/(float)(*m).nt,'%'); // TEST
		if(i%1==0)
			printf("%i\n",i);
	
		tmp[0]=em_getPointFromSphericalCoordinate(gm[T[i].a]);
		tmp[1]=em_getPointFromSphericalCoordinate(gm[T[i].b]);
		tmp[2]=em_getPointFromSphericalCoordinate(gm[T[i].c]);
		for(j=0;j<3;j++)
		{   tmp[j]=stereographic(tmp[j]);tmp[j].y=-tmp[j].y;}
		
		if( norm3D(sub3D(tmp[0],tmp[1]))<0.95*pi &&
			norm3D(sub3D(tmp[1],tmp[2]))<0.95*pi &&
			norm3D(sub3D(tmp[2],tmp[0]))<0.95*pi)
		{
			ot[0]=p[T[i].a];
			ot[1]=p[T[i].b];
			ot[2]=p[T[i].c];
			aot=k*triArea(ot[0],ot[1],ot[2]);
			t[0]=(double2D){tmp[1].x,tmp[1].y}; // NOTE THAT TRIANGLE IS INVERTED!!
			t[1]=(double2D){tmp[0].x,tmp[0].y};
			t[2]=(double2D){tmp[2].x,tmp[2].y};
			maxval=PaintTriangleAreaDistortion(aot, t, it,bytesPerPixel,width,height);
			if(maxval>globalmaxval) globalmaxval=maxval;
		}
	}
	printf("Global Maximum Value of Area in a Pixel: %f\n",globalmaxval);

    return err;
}
#pragma mark -
#pragma mark [   general   ]
void tal_getPointFromTalairach(float *p, float *tal, float *M)
{
    // M[0]: origin in Point space
    // M[3]: sagital talairach to Point
    // M[6]: coronal talairach to Point
    // M[9]: axial talairach to Point
    float3D		sa,ax,co,P;

    // tal[] is sag,cor,axi
    // p[] is cor,axi,sag

    sa=sca3D(*(float3D*)&M[3],tal[0]);
    co=sca3D(*(float3D*)&M[6],tal[1]);
    ax=sca3D(*(float3D*)&M[9],tal[2]);
    P=add3D(add3D(sa,add3D(co,ax)),*(float3D*)&M[0]);
    
    p[0]=P.y;
    p[1]=P.z;
    p[2]=P.x;
}
void tal_getTalairachFromPoint(float *t, float *p, float *M)
{
    float iM[9];
    float3D sa,ax,co,Tal;
    
    iMat(&M[3], iM);
    
    // tal[] is sag,cor,axi
    // p[] is cor,axi,sag

    sa=sca3D(*(float3D*)&iM[0],(p[2]-M[0]));
    co=sca3D(*(float3D*)&iM[3],(p[0]-M[1]));
    ax=sca3D(*(float3D*)&iM[6],(p[1]-M[2]));
    Tal=add3D(sa,add3D(co,ax));
    
    t[0]=Tal.x;
    t[1]=Tal.y;
    t[2]=Tal.z;
}
