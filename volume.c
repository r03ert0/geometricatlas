/*
 *  volume.c
 *  Geometric Atlas
 *
 *  Created by roberto on Mon Nov 10 2003.
 *  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
 *
 */

#include "volume.h"

void parseAnalyzeData(VolumeDescription *d, unsigned char *h, int nbytes)
{
    int			i=0;
    int			size;
    char		u[5];
    bool		le=false;
    short		x;

    printf("parsing analyze data\n");
    // read header
    //  header_key
    
    size=readIntFrom(h,&i,le);		// sizeof_hdr: int
    i+=10;				// data_type: 10*byte
    i+=18;	 			// db_name: 18*byte 
    i+=4; 				// extents: int
    i+=2;				// session_error: short
    i+=1;				// regular: byte
    i+=1;	 			// hkey_un0: byte

// image_dimension
    x=readShortFrom(h,&i,le);			// dim[0] (endian): short
    if ((x < 0) || (x > 15)) 
        le=(*d).littleEndian = true;
    printf(le?"little\n":"big\n");
    (*d).dim[0]=(int)readShortFrom(h,&i,le);	// dim[1] (width): short
    (*d).dim[1]=(int)readShortFrom(h,&i,le);	// dim[2] (height): short
    (*d).dim[2]=(int)readShortFrom(h,&i,le);	// dim[3] (nImages): short
    i+=2;					// dim[4] :short
    i+=2*3;					// dim[5-7] 
    u[0]=(char)readByteFrom(h,&i);	// vox_units
    u[1]=(char)readByteFrom(h,&i);
    u[2]=(char)readByteFrom(h,&i);
    u[3]=(char)readByteFrom(h,&i);
    u[4]=(char)0;
    i+=8;							// cal_units[8] : 8*byte
    i+=2;							// unused1: short
    (*d).dataType=readShortFrom(h,&i,le);	// datatype :short
    i+=2;							// bitpix:short
    i+=2;							// dim_un0:short
    i+=4;							// pixdim[0] :float
    (*d).pdim[0]=readFloatFrom(h,&i,le);	// pixdim[1] (width):float
    (*d).pdim[1]=readFloatFrom(h,&i,le); 	// pixdim[2] (height):float
    (*d).pdim[2]=readFloatFrom(h,&i,le); 	// pixdim[3] (depth):float
    i+=4*4;				// pixdim[4-7]  :float*4
    i+=4;				// vox_offset :float
    i+=4;				// roi_scale :float
    i+=4;				// funused1 :float
    i+=4;				// funused2 :float
    i+=4;				// cal_max :float
    i+=4;				// cal_min :float
    i+=4;				// compressed:int
    i+=4;				// verified  :int
    //   ImageStatistics s = imp.getStatistics();
    i+=4;	//(int) s.max		// glmax : int
    i+=4;	//(int) s.min		// glmin :int

// data_history 

    i+=80;		// descrip :byte*80 
    i+=24;		// aux_file :byte*24
    i+=1;		// orient :byte
    (*d).orig[0]=readShortFrom(h,&i,le); // origin x
    (*d).orig[1]=readShortFrom(h,&i,le); // origin y
    (*d).orig[2]=readShortFrom(h,&i,le); // origin z
	if((*d).orig[0]==0) (*d).orig[0]=(*d).dim[0]/2;
	if((*d).orig[1]==0) (*d).orig[1]=(*d).dim[1]/2;
	if((*d).orig[2]==0) (*d).orig[2]=(*d).dim[2]/2;
    i+=2*2;		// origin, origin
    i+=10;		// generated :byte*10
    i+=10;		// scannum :byte*10
    i+=10;		// patient_id  :byte*10
    i+=10;		// exp_date :byte*10
    i+=10;		// exp_time  :byte*10
    i+=3;		// hist_un0:byte*3
    i+=1;		// views :int
    i+=1;		// vols_added :int
    i+=1;		// start_field  :int
    i+=1;		// field_skip:int
    i+=1;		// omax  :int
    i+=1;		// omin :int
    i+=1;		// smax  :int
    i+=1;		// smin :int

    switch ((*d).dataType)
    {
     case 2:	// DT_UNSIGNED_CHAR 
      break;
     case 4:	// DT_SIGNED_SHORT 
      break;
     case 8:	// DT_SIGNED_INT
      break; 
     case 16:	// DT_FLOAT 
      break; 
     case 128:	// DT_RGB
      break; 
    }
    
    vol_configureTransformationMatrices(d);
	vol_configureIntensity(d);
}
void vol_configureTransformationMatrices(VolumeDescription *d)
{
	//direct voxel to milimeters_____________________
    (*d).v2m[0]=(*d).orig[0];  (*d).v2m[1]=(*d).orig[1];  (*d).v2m[2]=(*d).orig[2];// origin
    (*d).v2m[3]=(*d).pdim[0];  (*d).v2m[4]=0;	      (*d).v2m[5]=0;// (R)sagital: left to right
    (*d).v2m[6]=0;		 (*d).v2m[7]=(*d).pdim[1];  (*d).v2m[8]=0;// (A)coronal: posterior to anterior
    (*d).v2m[9]=0;		 (*d).v2m[10]=0;	      (*d).v2m[11]=(*d).pdim[2];// (S)axial: inferior to superior
    //inverse____________________
    (*d).m2v[0]=(*d).orig[0];	 (*d).m2v[1]=(*d).orig[1];  (*d).m2v[2]=(*d).orig[2];
    inverseMatrix(&(*d).v2m[3],&(*d).m2v[3]);
}
void vol_configureIntensity(VolumeDescription *d)
{
	int x,y,z;
	float   p[3], v,n=0,mean=0,std=0;
	float   t;
	
	switch((*d).dataType)
	{
		case 2: // char
			for(x=0;x<(*d).dim[0];x++)
			for(y=0;y<(*d).dim[1];y++)
			for(z=0;z<(*d).dim[2];z++)
			{
				p[0]=x;p[1]=y;p[2]=z;
				v=vol_getByteAt(*d,p);
				if(v>0)
				{
					mean+=v;
					std+=v*v;
					n++;
				}
			}
			break;
		case 4: // short
			for(x=0;x<(*d).dim[0];x++)
			for(y=0;y<(*d).dim[1];y++)
			for(z=0;z<(*d).dim[2];z++)
			{
				p[0]=x;p[1]=y;p[2]=z;
				v=vol_getShortAt(*d,p);
				if(v>0)
				{
					mean+=v;
					std+=v*v;
					n++;
				}
			}
			break;
	}
	std=sqrt((std-mean*mean/n)/(n-1));
	std=10;
	t=mean/n+3*std; // 95% of the values are under t
	printf("mean:%f std:%f\n",mean/n,std);
	
	(*d).f=255/t;
	if((*d).dataType==16)
		(*d).f=10;
}
	
#pragma mark -
unsigned char readByteFrom(unsigned char *b, int *i)
{
    int	p=(*i);
    (*i)++;
    return *(unsigned char*)(b+p);
}
short readShortFrom(unsigned char *b, int *i, bool flag)
{
    short x;
    int	p=(*i);
    (*i)+=2;
    if(!flag)
    {
        unsigned char b1=readByteFrom(b,&p);
        unsigned char b2=readByteFrom(b,&p);
        x=(short)(((b2 & 0xff) << 8) | (b1 & 0xff));
    }
    else
        x= *(short*)(b+p);
    return x;
}
int readIntFrom(unsigned char *b, int *i, bool flag)
{
    int	x;
    int	p=(*i);
    (*i)+=4;
    if(!flag)
    {
        unsigned char by[4];
        by[3]=readByteFrom(b,&p);
        by[2]=readByteFrom(b,&p);
        by[1]=readByteFrom(b,&p);
        by[0]=readByteFrom(b,&p);
        x=*(int*)by;
    }
    else
        x=*(int*)(b+p);
    return x;
}
float readFloatFrom(unsigned char *b, int *i, bool flag)
{
    int	p=(*i);
    (*i)+=4;
    if(!flag)
    {
        unsigned char by[4];
        by[3]=readByteFrom(b,&p);
        by[2]=readByteFrom(b,&p);
        by[1]=readByteFrom(b,&p);
        by[0]=readByteFrom(b,&p);
        return *(float*)by;
    }
    else
        return *(float*)(b+p);
}
short shortAt(unsigned char *b, bool flag)
{
    if(!flag)
    {
        unsigned char by[2];
        by[1]=*(b+0);
        by[0]=*(b+1);
        return *(short*)by;
    }
    else
        return *(short*)b;
}

float floatAt(unsigned char *b, bool flag)
{
    if(!flag)
    {
        unsigned char by[4];
        by[3]=*(b+0);
        by[2]=*(b+1);
        by[1]=*(b+2);
        by[0]=*(b+3);
        return *(float*)by;
    }
    else
        return *(float*)b;
}
#pragma mark -
void multiplyMatrices(float *a, float *b,float *c)
{
    float	aux[9];
    int		i;

    aux[0] = a[0]*b[0] + a[1]*b[3] + a[2]*b[6];
    aux[1] = a[0]*b[1] + a[1]*b[4] + a[2]*b[7];
    aux[2] = a[0]*b[2] + a[1]*b[5] + a[2]*b[8];
    
    aux[3] = a[3]*b[0] + a[4]*b[3] + a[5]*b[6];
    aux[4] = a[3]*b[1] + a[4]*b[4] + a[5]*b[7];
    aux[5] = a[3]*b[2] + a[4]*b[5] + a[5]*b[8];
    
    aux[6] = a[6]*b[0] + a[7]*b[3] + a[8]*b[6];
    aux[7] = a[6]*b[1] + a[7]*b[4] + a[8]*b[7];
    aux[8] = a[6]*b[2] + a[7]*b[5] + a[8]*b[8];
    
    for(i=0;i<9;i++) c[i]=aux[i];
}
void inverseMatrix(float *a,float *b)
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
#pragma mark -
float distancePointSegment(float *p,float *e0,float *e1)
{
    float	t,d;
    float	a0=(p[0]-e0[0]);
    float	a1=(p[1]-e0[1]);
    float	a2=(p[2]-e0[2]);
    float	b0=(e1[0]-e0[0]);
    float	b1=(e1[1]-e0[1]);
    float	b2=(e1[2]-e0[2]);
    
    t=(a0*b0+a1*b1+a2*b2)/(b0*b0+b1*b1+b2*b2);
    if(t<0)
        d=sqrt(a0*a0+a1*a1+a2*a2);
    else
    if(t>1)
        d=sqrt(pow(p[0]-e1[0],2)+pow(p[1]-e1[1],2)+pow(p[2]-e1[2],2));
    else
        d=sqrt(pow(a0-t*b0,2)+pow(a1-t*b1,2)+pow(a2-t*b2,2));
    
    return d;
}
#pragma mark -
void talairachToMilimeters(float *T, float *M, float *m)
{
    M[0]=T[0]*m[1*3+0]+T[1]*m[2*3+0]+T[2]*m[3*3+0];
    M[1]=T[0]*m[1*3+1]+T[1]*m[2*3+1]+T[2]*m[3*3+1];
    M[2]=T[0]*m[1*3+2]+T[1]*m[2*3+2]+T[2]*m[3*3+2];
}
void milimetersToTalairach(float *M, float *T, float *im)
{
    T[0]=M[0]*im[1*3+0]+M[1]*im[2*3+0]+M[2]*im[3*3+0];
    T[1]=M[0]*im[1*3+1]+M[1]*im[2*3+1]+M[2]*im[3*3+1];
    T[2]=M[0]*im[1*3+2]+M[1]*im[2*3+2]+M[2]*im[3*3+2];
}
void vol_setTransformMatrix(float *m,	float a,float b,float c,
                                        float d,float e,float f,
                                        float g,float h,float i,
                                        float j,float k,float l)
{
    m[0]=a;	m[1]=b;	    m[2]=c;
    m[3]=d;	m[4]=e;	    m[5]=f;
    m[6]=g;	m[7]=h;	    m[8]=i;
    m[9]=j;	m[10]=k;    m[11]=l;
}
void vol_screenToMilimeters(float *a, float *b, float *ab)
{
    // milimeters have 0 origin
    // voxels have !=0 origin
    b[0]=(a[0]-ab[0])*ab[1*3+0]+(a[1]-ab[1])*ab[2*3+0]+(a[2]-ab[2])*ab[3*3+0];
    b[1]=(a[0]-ab[0])*ab[1*3+1]+(a[1]-ab[1])*ab[2*3+1]+(a[2]-ab[2])*ab[3*3+1];
    b[2]=(a[0]-ab[0])*ab[1*3+2]+(a[1]-ab[1])*ab[2*3+2]+(a[2]-ab[2])*ab[3*3+2];
}
void vol_screenToTalairach(float *a, float *b, float *ab)
{
    b[0]=(a[0]-ab[0])*ab[1*3+0]+(a[1]-ab[1])*ab[2*3+0]+(a[2]-ab[2])*ab[3*3+0];
    b[1]=(a[0]-ab[0])*ab[1*3+1]+(a[1]-ab[1])*ab[2*3+1]+(a[2]-ab[2])*ab[3*3+1];
    b[2]=(a[0]-ab[0])*ab[1*3+2]+(a[1]-ab[1])*ab[2*3+2]+(a[2]-ab[2])*ab[3*3+2];
}
void vol_indexToMilimeters(float *a, float *b, float *ab)
{
    b[0]=(a[0]-ab[0])*ab[1*3+0]+(a[1]-ab[1])*ab[2*3+0]+(a[2]-ab[2])*ab[3*3+0];
    b[1]=(a[0]-ab[0])*ab[1*3+1]+(a[1]-ab[1])*ab[2*3+1]+(a[2]-ab[2])*ab[3*3+1];
    b[2]=(a[0]-ab[0])*ab[1*3+2]+(a[1]-ab[1])*ab[2*3+2]+(a[2]-ab[2])*ab[3*3+2];
}
void vol_voxelsToMilimeters(float *a, float *b, float *ab)
{
    // milimeters have 0 origin
    // voxels have !=0 origin
    b[0]=(a[0]-ab[0])*ab[1*3+0]+(a[1]-ab[1])*ab[2*3+0]+(a[2]-ab[2])*ab[3*3+0];
    b[1]=(a[0]-ab[0])*ab[1*3+1]+(a[1]-ab[1])*ab[2*3+1]+(a[2]-ab[2])*ab[3*3+1];
    b[2]=(a[0]-ab[0])*ab[1*3+2]+(a[1]-ab[1])*ab[2*3+2]+(a[2]-ab[2])*ab[3*3+2];
}
void vol_milimetersToVoxels(float *a, float *b, float *ab)
{
    // milimeters have 0 origin
    // voxel have !=0 origin
    b[0]=a[0]*ab[1*3+0]+a[1]*ab[2*3+0]+a[2]*ab[3*3+0]+ab[0];
    b[1]=a[0]*ab[1*3+1]+a[1]*ab[2*3+1]+a[2]*ab[3*3+1]+ab[1];
    b[2]=a[0]*ab[1*3+2]+a[1]*ab[2*3+2]+a[2]*ab[3*3+2]+ab[2];
}
void vol_talairachToMilimeters(float *a, float *b, float *ab)
{
    // milimeters have !=0 origin
    // talairach has 0 origin
    b[0]=a[0]*ab[1*3+0]+a[1]*ab[2*3+0]+a[2]*ab[3*3+0]+ab[0];
    b[1]=a[0]*ab[1*3+1]+a[1]*ab[2*3+1]+a[2]*ab[3*3+1]+ab[1];
    b[2]=a[0]*ab[1*3+2]+a[1]*ab[2*3+2]+a[2]*ab[3*3+2]+ab[2];
}
void vol_milimetersToTalairach(float *a, float *b, float *ab)
{
    // milimeters have !=0 origin,talairach has 0 origin
    b[0]=(a[0]-ab[0])*ab[1*3+0]+(a[1]-ab[1])*ab[2*3+0]+(a[2]-ab[2])*ab[3*3+0];
    b[1]=(a[0]-ab[0])*ab[1*3+1]+(a[1]-ab[1])*ab[2*3+1]+(a[2]-ab[2])*ab[3*3+1];
    b[2]=(a[0]-ab[0])*ab[1*3+2]+(a[1]-ab[1])*ab[2*3+2]+(a[2]-ab[2])*ab[3*3+2];
}

double vol_getValueAt(VolumeDescription d, float *p)
{
    double		val;
	
	switch(d.dataType)
	{
		case 2: // byte
			val=vol_getByteAt(d,p);
			break;
		case 4: // short
			val=vol_getShortAt(d,p);
			break;
		case 16: //float
			val=vol_getFloatAt(d,p);
			break;
	}

	return val;
}

short vol_getByteAt(VolumeDescription d, float *p)
{
    int		voxel;
	unsigned char b;
    
    if(p[0]<0||p[0]>=d.dim[0]||p[1]<0||p[1]>=d.dim[1]||p[2]<0||p[2]>=d.dim[2])
        return 0;
    voxel=((int)p[2])*d.dim[0]*d.dim[1]+((int)p[1])*d.dim[0]+((int)p[0]);
    b=(d.data+voxel)[0];
	return b;
}
short vol_getShortAt(VolumeDescription d, float *p)
{
    bool	flag=d.littleEndian;
    int		voxel;
    unsigned char b[2];
    
    if(p[0]<0||p[0]>=d.dim[0]||p[1]<0||p[1]>=d.dim[1]||p[2]<0||p[2]>=d.dim[2])
        return 0;
    voxel=((int)p[2])*d.dim[0]*d.dim[1]+((int)p[1])*d.dim[0]+((int)p[0]);
    voxel*=sizeof(short);
    b[0]=(d.data+voxel)[0];
    b[1]=(d.data+voxel)[1];
    if(!flag)
    {
        unsigned char by[2];
        by[1]=*(b+0);
        by[0]=*(b+1);
        return *(short*)by;
    }
    else
        return *(short*)b;
}
void vol_setShortAt(VolumeDescription d, float *p, short val)
{
    int	voxel;

    if(p[0]<0||p[0]>=d.dim[0]||p[1]<0||p[1]>=d.dim[1]||p[2]<0||p[2]>=d.dim[2])
        return;
    voxel=((int)p[2])*d.dim[0]*d.dim[1]+((int)p[1])*d.dim[0]+((int)p[0]);
    voxel*=sizeof(short);
    
    // big endian only !!
    (d.data+voxel)[0]=val&0x00ff;
    (d.data+voxel)[1]=val>>8;
}
float vol_getFloatAt(VolumeDescription d, float *p)
{
    bool	flag=d.littleEndian;
    int		voxel;
    unsigned char b[4];
    
    if(p[0]<0||p[0]>=d.dim[0]||p[1]<0||p[1]>=d.dim[1]||p[2]<0||p[2]>=d.dim[2])
        return 0;
    voxel=((int)p[2])*d.dim[0]*d.dim[1]+((int)p[1])*d.dim[0]+((int)p[0]);
    voxel*=sizeof(float);
    b[0]=(d.data+voxel)[0];
    b[1]=(d.data+voxel)[1];
    b[2]=(d.data+voxel)[2];
    b[3]=(d.data+voxel)[3];
    if(!flag)
    {
        unsigned char by[4];
        by[3]=*(b+0);
        by[2]=*(b+1);
        by[1]=*(b+2);
        by[0]=*(b+3);
        return *(float*)by;
    }
    else
        return *(float*)b;
}
#pragma mark -
void connectaround(int x,int y,int z, short value, VolumeDescription vol)
{
	int		k,n;
	int		dx,dy,dz;
	float   p[3];
	int		dire[6]={0,0,0,0,0,0};
	int		*dstack,nstack=0,maxstack=256000;
	int3D   *stack;
	int		empty,mark;
	unsigned char	*label;

	label=(unsigned char *)calloc(vol.dim[0]*vol.dim[1]*vol.dim[2],1);
	dstack=(int*)calloc(maxstack,sizeof(int));
	stack=(int3D*)calloc(maxstack,sizeof(int3D));
	n=0;
				
	for(;;)
	{
		label[z*vol.dim[0]*vol.dim[1]+y*vol.dim[0]+x] |= 1;
		n++;
		
		for(k=0;k<6;k++)
		{
			dx = (-1)*(	k==3 ) + ( 1)*( k==1 );
			dy = (-1)*( k==2 ) + ( 1)*( k==0 );
			dz = (-1)*( k==5 ) + ( 1)*( k==4 );

			if(	z+dz>=0 && z+dz<vol.dim[2] &&
				y+dy>=0 && y+dy<vol.dim[1] &&
				x+dx>=0 && x+dx<vol.dim[0] )
			{
				
				p[0]=x+dx;p[1]=y+dy;p[2]=z+dz;
				empty = vol_getShortAt(vol, p)&(value);
				mark = label[(z+dz)*vol.dim[0]*vol.dim[1]+(y+dy)*vol.dim[0]+(x+dx)];
				
				if( empty && !mark && !dire[k])
				{
					dire[k] = true;
					dstack[nstack] = k+1;
					stack[nstack++] = (int3D){x+dx,y+dy,z+dz};
				}
				else
					if( dire[k] && !empty && !mark)
						dire[k] = false;
			}
		}
		
		if(nstack>maxstack-10)
		{
			printf("StackOverflow\n");
			free(stack);
			return;
		}
		
		if(nstack)
		{
			nstack--;
			
			z = stack[nstack].c;
			y = stack[nstack].b;
			x = stack[nstack].a;
			
			for(k=0;k<6;k++)
				dire[k] = (dstack[nstack]==(k+1))?false:dire[k];
		}
		else
			break;
	}
	free((void*)label);
	free((void*)dstack);
	free((void*)stack);
	return;
}
