// gcc tower.c -o tower -lglut -lm -lGLU -lGL
//To stop hit "control c" in the window you launched it from.
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#define N 4

#define XWindowSize 2500
#define YWindowSize 2500

#define DRAW 10
#define PRINT 100
#define DAMP 0.3

#define G 1.0

#define DT 0.001

#define EYE 5.0
#define FAR 50.0

#define STOP_TIME 100.0

#define FLOOR_STRENGTH 200.0
#define SHERE_RADIUS 0.2
#define DROP_HIEGHT 5.0

// Globals
float Px[N], Py[N], Pz[N];
float Vx[N], Vy[N], Vz[N];
float Fx[N], Fy[N], Fz[N];
float Mass[N], CompressionStrength[N][N], TensionStrength[N][N], NaturalLength[N][N]; 
float Red[N][N], Green[N][N], Blue[N][N];

void set_initail_conditions()
{
	int i,j;
	
	//Zeroing all matrices
	for(i = 0; i < N; i++)
	{
		for(j = 0; j < N; j++)
		{
			CompressionStrength[i][j] = 0.0;
			TensionStrength[i][j] = 0.0;
			NaturalLength[i][j] = 0.0;
			
			Red[i][j] = 0.0;
			Green[i][j] = 0.0;
			Blue[i][j] = 0.0;
		}
	}
	
	//Setting node masses
	for(i = 0; i < N; i++)
	{	
		Mass[i] = 1.0;
	}
	
	//Setting node velocities
	for(i = 0; i < N; i++)
	{	
		Vx[i] = 0.0;
		Vy[i] = 0.0;
		Vz[i] = 0.0;
	}
	
	//Setting connector attributes (most of the matrix is wasted)
	CompressionStrength[0][1] = 10.0;
	TensionStrength[0][1] = 10.0;
	NaturalLength[0][1] = 2.0;
	
	CompressionStrength[0][2] = 10.0;
	TensionStrength[0][2] = 10.0;
	NaturalLength[0][2] = 2.0;
	
	CompressionStrength[0][3] = 10.0;
	TensionStrength[0][3] = 10.0;
	NaturalLength[0][3] = 2.0;
	
	CompressionStrength[1][2] = 10.0;
	TensionStrength[1][2] = 10.0;
	NaturalLength[1][2] = 2.0;
	
	CompressionStrength[1][3] = 10.0;
	TensionStrength[1][3] = 10.0;
	NaturalLength[1][3] = 2.0;
	
	CompressionStrength[2][3] = 10.0;
	TensionStrength[2][3] = 10.0;
	NaturalLength[2][3] = 2.0;
	
	//Setting node positions
	Px[0] = 0.0;
	Py[0] = 0.0 + DROP_HIEGHT;
	Pz[0] = 1.0;
	
	Px[1] = 1.0;
	Py[1] = 0.0 + DROP_HIEGHT;
	Pz[1] = 0.0;
	
	Px[2] = -1.0;
	Py[2] = 0.0 + DROP_HIEGHT;
	Pz[2] = 0.0;
	
	Px[3] = 0.0;
	Py[3] = 1.0 + DROP_HIEGHT;
	Pz[3] = 0.0;
}

void draw_picture()
{
	int i;
	
	//Clearing the picture
	glClear(GL_COLOR_BUFFER_BIT);
	glClear(GL_DEPTH_BUFFER_BIT);
	
	//Drawing the nodes
	for(i = 0; i < N; i++)
	{
		if(i == 0) glColor3d(1.0,1.0,1.0);
		if(i == 1) glColor3d(0.0,1.0,0.0);
		if(i == 2) glColor3d(1.0,0.0,0.0);
		if(i == 3) glColor3d(1.0,0.0,1.0);
		glPushMatrix();
		glTranslatef(Px[i], Py[i], Pz[i]);
		glutSolidSphere(SHERE_RADIUS,20,20);
		glPopMatrix();
	}
	
	//Drawing the Connectors (red if compressed, blue is stretched)
	glLineWidth(8.0);
	glColor3d(Red[0][1],Green[0][1],Blue[0][1]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[0], Py[0], Pz[0]);  
		glVertex3f(Px[1], Py[1], Pz[1]);   
	glEnd();
	glColor3d(Red[0][2],Green[0][2],Blue[0][2]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[0], Py[0], Pz[0]);   
		glVertex3f(Px[2], Py[2], Pz[2]); 
	glEnd();
	glColor3d(Red[0][3],Green[0][3],Blue[0][3]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[0], Py[0], Pz[0]);   
		glVertex3f(Px[3], Py[3], Pz[3]); 
	glEnd();
	glColor3d(Red[1][2],Green[1][2],Blue[1][2]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[1], Py[1], Pz[1]);   
		glVertex3f(Px[2], Py[2], Pz[2]); 
	glEnd();
	glColor3d(Red[1][3],Green[1][3],Blue[1][3]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[1], Py[1], Pz[1]);   
		glVertex3f(Px[3], Py[3], Pz[3]); 
	glEnd();
	glColor3d(Red[2][3],Green[2][3],Blue[2][3]);
	glBegin(GL_LINE_STRIP);
		glVertex3f(Px[2], Py[2], Pz[2]);   
		glVertex3f(Px[3], Py[3], Pz[3]); 
	glEnd();
	
	//Drawing the flooor
	glLineWidth(1.0);
	glColor3d(1.0,1.0,1.0);
	int floorSections = 100;
	float floorStartX = -5.0;
	float floorStopX = 5.0;
	float dx = (floorStopX - floorStartX)/floorSections;
	float floorStartZ = -5.0;
	float floorStopZ = 5.0;
	float dz = (floorStopZ - floorStartZ)/floorSections;
	float x;
	float z;
	
	x = floorStartX;
	for(i = 0; i < floorSections; i++)
	{
		glBegin(GL_LINE_STRIP);
			glVertex3f(x, 0.0, floorStartZ);   
			glVertex3f(x, 0.0, floorStopX); 
		glEnd();
		x += dx;
	}
	
	z = floorStartZ;
	for(i = 0; i < floorSections; i++)
	{
		glBegin(GL_LINE_STRIP);
			glVertex3f(floorStartX, 0.0, z);   
			glVertex3f(floorStopX, 0.0, z); 
		glEnd();
		z += dz;
	}
	
	//Pushing picture to the screen
	glutSwapBuffers();
}

float get_force(int i, int j, float separation)
{
	if(separation <= NaturalLength[i][j])
	{
		Red[i][j] = 1.0;
		Green[i][j] = 0.0;
		Blue[i][j] = 0.0;
		return(CompressionStrength[i][j]*(separation - NaturalLength[i][j]));
	}
	else
	{
		Red[i][j] = 0.0;
		Green[i][j] = 0.0;
		Blue[i][j] = 1.0;
		return(TensionStrength[i][j]*(separation - NaturalLength[i][j]));
	}
}

void n_body()
{
	float force_mag; 
	float dx,dy,dz,d, d2, dt;
	int    tdraw = 0; 
	int    tprint = 0;
	float  time = 0.0;
	int i,j;
	
	dt = DT;

	while(time < STOP_TIME)
	{
		for(i = 0; i < N; i++)
		{
			Fx[i] = 0.0;
			Fy[i] = 0.0;
			Fz[i] = 0.0;
		}
		
		for(i = 0; i < N; i++)
		{
			for(j = i+1; j < N; j++)
			{
				//Finding the distance between nodes.
				dx = Px[j] - Px[i];
				dy = Py[j] - Py[i];
				dz = Pz[j] - Pz[i];
				d2 = dx*dx + dy*dy + dz*dz;
				d  = sqrt(d2);
				
				//Getting the magnitude of the force caused by node positions.
				force_mag  =  get_force(i, j, d);
				
				//Seperating into x, y, z components 
				Fx[i] += force_mag*dx/d;
				Fx[j] -= force_mag*dx/d;
				Fy[i] += force_mag*dy/d;
				Fy[j] -= force_mag*dy/d;
				Fz[i] += force_mag*dz/d;
				Fz[j] -= force_mag*dz/d;
			}
			
			//Adding in the force of gravity
			Fy[i] += -G;
			
			//Adding in the push back force from the floor.
			if((Py[i] - SHERE_RADIUS) < 0.0) Fy[i] += FLOOR_STRENGTH*(0.0 - (Py[i] - SHERE_RADIUS)); 
		}

		//Leapfrog formulas to move the nodes forward in time dt.
		for(i = 0; i < N; i++)
		{
			if(time == 0.0)
			{
				Vx[i] += ((Fx[i]-DAMP*Vx[i])/Mass[i])*0.5*dt;
				Vy[i] += ((Fy[i]-DAMP*Vy[i])/Mass[i])*0.5*dt;
				Vz[i] += ((Fz[i]-DAMP*Vz[i])/Mass[i])*0.5*dt;
			}
			else
			{
				Vx[i] += ((Fx[i]-DAMP*Vx[i])/Mass[i])*dt;
				Vy[i] += ((Fy[i]-DAMP*Vy[i])/Mass[i])*dt;
				Vz[i] += ((Fz[i]-DAMP*Vz[i])/Mass[i])*dt;
			}

			Px[i] += Vx[i]*dt;
			Py[i] += Vy[i]*dt;
			Pz[i] += Vz[i]*dt;
		}

		if(tdraw == DRAW) 
		{
			draw_picture();
			tdraw = 0;
		}
		
		time += dt;
		tdraw++;
		tprint++;
	}
}

void control()
{	
	int    tdraw = 0;
	float  time = 0.0;
	set_initail_conditions();
	draw_picture();
    	n_body();
	
	printf("\n DONE \n");
	while(1);
}

void Display(void)
{
	gluLookAt(EYE, EYE, EYE, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	control();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);

	glMatrixMode(GL_PROJECTION);

	glLoadIdentity();

	glFrustum(-0.2, 0.2, -0.2, 0.2, 0.2, FAR);

	glMatrixMode(GL_MODELVIEW);
}

int main(int argc, char** argv)
{
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
	glutInitWindowSize(XWindowSize,YWindowSize);
	glutInitWindowPosition(0,0);
	glutCreateWindow("Tower");
	GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glShadeModel(GL_SMOOTH);
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
	glLightfv(GL_LIGHT0, GL_POSITION, light_position);
	glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
	glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
	glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_COLOR_MATERIAL);
	glEnable(GL_DEPTH_TEST);
	glutDisplayFunc(Display);
	glutReshapeFunc(reshape);
	glutMainLoop();
	return 0;
}






