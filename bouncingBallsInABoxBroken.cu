//nvcc bouncingBallsInABoxBroken.cu -o bounce -lglut -lm -lGLU -lGL																													
//To stop hit "control c" in the window you launched it from.
#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <cuda.h>
#include <curand.h>
#include <curand_kernel.h>

#define NUMBER_OF_BALLS 20
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position[NUMBER_OF_BALLS], Velocity[NUMBER_OF_BALLS], Force[NUMBER_OF_BALLS], Color[NUMBER_OF_BALLS];
float SphereMass;
float SphereDiameter;
float BoxSideLength;
float MaxVelocity;

// Window globals
static int Window;
int XWindowSize;
int YWindowSize;
double Near;
double Far;
double EyeX;
double EyeY;
double EyeZ;
double CenterX;
double CenterY;
double CenterZ;
double UpX;
double UpY;
double UpZ;

void setInitailConditions();
void drawPicture();
void getForces();
void updatePositions();
void nBody();
void startMeUp();

void Display()
{
	drawPicture();
}

void idle()
{
	nBody();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);
}

void setInitailConditions()
{
	time_t t;
	float randomNumber;
	float halfBoxSideLength;
	float sphereRadius;
	float seperation;
	int test;
	
	// Seading the random number generater.
	srand((unsigned) time(&t));
	
	SphereDiameter = 0.5;
	sphereRadius = SphereDiameter/2.0;
	SphereMass = 1.0;
	BoxSideLength = 5.0;
	MaxVelocity = 10.0;
	halfBoxSideLength = BoxSideLength/2.0;
	
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		// Settting the balls randomly in the box and not letting them be right on top of each other.
		test = 0;
		while(test == 0)
		{
			// Get random 0 and 1.
			randomNumber = ((float)rand()/(float)RAND_MAX);
			// Making it between -1 and 1
			randomNumber = randomNumber*2.0 - 1.0;
			// Making it between -halfBoxSideLength and halfBoxSideLength
			randomNumber = randomNumber*(halfBoxSideLength - sphereRadius);
			// Putting the ball there x.
			Position[i].x = randomNumber;
			
			// Get random 0 and 1.
			randomNumber = ((float)rand()/(float)RAND_MAX);
			// Making it between -1 and 1
			randomNumber = randomNumber*2.0 - 1.0;
			// Making it between -halfBoxSideLength and halfBoxSideLength
			randomNumber = randomNumber*(halfBoxSideLength - sphereRadius);
			// Putting the ball there y.
			Position[i].y = randomNumber;
			
			// Get random 0 and 1.
			randomNumber = ((float)rand()/(float)RAND_MAX);
			// Making it between -1 and 1
			randomNumber = randomNumber*2.0 - 1.0;
			// Making it between -halfBoxSideLength and halfBoxSideLength
			randomNumber = randomNumber*(halfBoxSideLength - sphereRadius);
			// Putting the ball there z.
			Position[i].z = randomNumber;
			
			// Making sure the balls centers are at least a diameter apart.
			// If they are not throw these position away and try again.
			test = 1;
			for(int j = 0; j < i; j++)
			{
				seperation = sqrt((Position[i].x-Position[j].x)*(Position[i].x-Position[j].x) + (Position[i].y-Position[j].y)*(Position[i].y-Position[j].y) + (Position[i].z-Position[j].z)*(Position[i].z-Position[j].z));
				if(seperation < SphereDiameter)
				{
					test = 0;
					break;
				}
			}
		}
		
		// Setting random velocities between -MaxVelocity and MaxVelocity.
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].x = randomNumber;
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].y = randomNumber;
		randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].z = randomNumber;
		
		// Randomly coloring the balls
		randomNumber = ((float)rand()/(float)RAND_MAX);
		Color[i].x = randomNumber;
		randomNumber = ((float)rand()/(float)RAND_MAX);
		Color[i].y = randomNumber;
		randomNumber = ((float)rand()/(float)RAND_MAX);
		Color[i].z = randomNumber;
		
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	TotalRunTime = 10000.0;
	RunTime = 0.0;
	Dt = 0.001;
}

void drawPicture()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glClear(GL_DEPTH_BUFFER_BIT);
	
	float halfSide = BoxSideLength/2.0;
	
	// Drawing balls.
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		glColor3d(Color[i].x, Color[i].y, Color[i].z);
		glPushMatrix();
			glTranslatef(Position[i].x, Position[i].y, Position[i].z);
			glutSolidSphere(SphereDiameter/2.0, 30, 30);
		glPopMatrix();
	}
	
	glLineWidth(3.0);
	//Drawing front of box
	glColor3d(0.0, 1.0, 0.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
	glEnd();
	//Drawing back of box
	glColor3d(1.0, 1.0, 1.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off right side
	glBegin(GL_LINES);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off left side
	glBegin(GL_LINES);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	
	
	glutSwapBuffers();
}

void getForces()
{
	float wallStiffnessIn = 10000.0;
	float wallStiffnessOut = 8000.0;
	float k;
	float halfSide = BoxSideLength/2.0;
	float howMuch;
	float ballRadius = SphereDiameter/2.0;
	
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
		
		if((Position[i].x - ballRadius) < -halfSide)
		{
			howMuch = -halfSide - (Position[i].x - ballRadius);
			if(Velocity[i].x < 0.0) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].x += k*howMuch;
		}
		else if(halfSide < (Position[i].x + ballRadius))
		{
			howMuch = (Position[i].x + ballRadius) - halfSide;
			if(0.0 < Velocity[i].x) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].x -= k*howMuch;
		}
		
		if((Position[i].y - ballRadius) < -halfSide)
		{
			howMuch = -halfSide - (Position[i].y - ballRadius);
			if(Velocity[i].y < 0.0) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].y += k*howMuch;
		}
		else if(halfSide < (Position[i].y + ballRadius))
		{
			howMuch = (Position[i].y + ballRadius) - halfSide;
			if(0.0 < Velocity[i].y) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].y -= k*howMuch;
		}
		
		if((Position[i].z - ballRadius) < -halfSide)
		{
			howMuch = -halfSide - (Position[i].z - ballRadius);
			if(Velocity[i].z < 0.0) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].z += k*howMuch;
		}
		else if(halfSide < (Position[i].z + ballRadius))
		{
			howMuch = (Position[i].z + ballRadius) - halfSide;
			if(0.0 < Velocity[i].z) k = wallStiffnessIn;
			else k = wallStiffnessOut;
			Force[i].z -= k*howMuch;
		}
		for(int j = i + 1; j < NUMBER_OF_BALLS; j++)
		{
			// Maybe put something here and do it for i and the opposite for j.
			// Might also need to think about magna-dude and unit vectors.
			//
			// An eletron get pulled over by a cop. 
			// The cop says "Mam I clocked you at 8000 miles an hour."
			// Ms. Electron replies "Oh thanks a lot!!! Now I'm lost."
		}
	}
}

void updatePositions()
{
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		// These are the LeapFrog formulas.
		if(RunTime == 0.0)
		{
			Velocity[i].x += (Force[i].x/SphereMass)*(Dt/2.0);
			Velocity[i].y += (Force[i].y/SphereMass)*(Dt/2.0);
			Velocity[i].z += (Force[i].z/SphereMass)*(Dt/2.0);
		}
		else
		{
			Velocity[i].x += (Force[i].x/SphereMass)*Dt;
			Velocity[i].y += (Force[i].y/SphereMass)*Dt;
			Velocity[i].z += (Force[i].z/SphereMass)*Dt;
		}

		Position[i].x += Velocity[i].x*Dt;
		Position[i].y += Velocity[i].y*Dt;
		Position[i].z += Velocity[i].z*Dt;
	}
}

void nBody()
{	
	getForces();
	updatePositions();
	drawPicture();
	printf("\n Time = %f", RunTime);
	RunTime += Dt;
	
	if(TotalRunTime < RunTime)
	{
		glutDestroyWindow(Window);
		printf("\n Later Dude \n");
		exit(0);
	}
}

void startMeUp() 
{	
	// The Rolling Stones
	// Tattoo You: 1981
	setInitailConditions();
}

int main(int argc, char** argv)
{
	startMeUp();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 

	// Clip plains
	Near = 0.2;
	//Far = BoxSideLength;
	Far = 10.0;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 6.0;

	//Where you are looking
	CenterX = 0.0;
	CenterY = 0.0;
	CenterZ = 0.0;

	//Up vector for viewing
	UpX = 0.0;
	UpY = 1.0;
	UpZ = 0.0;
	
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
	glutInitWindowSize(XWindowSize,YWindowSize);
	glutInitWindowPosition(5,5);
	Window = glutCreateWindow("Particle In A Box");
	
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
	glMatrixMode(GL_MODELVIEW);
	
	glClearColor(0.0, 0.0, 0.0, 0.0);
		
	GLfloat light_Position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
	glShadeModel(GL_SMOOTH);
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
	glLightfv(GL_LIGHT0, GL_POSITION, light_Position);
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
	//glutMouseFunc(mymouse);
	//glutKeyboardFunc(KeyPressed);
	glutIdleFunc(idle);
	glutMainLoop();
	
	return 0;
}
