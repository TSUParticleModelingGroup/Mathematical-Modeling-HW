//nvcc bouncingAsteriodsInABoxBroken.cu -o bounce -lglut -lm -lGLU -lGL																													
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
#define PI 3.14159
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position[NUMBER_OF_BALLS], Velocity[NUMBER_OF_BALLS], Force[NUMBER_OF_BALLS], Color[NUMBER_OF_BALLS];
float SphereMass;
float SphereDiameter;
float BoxSideLength;
float MaxVelocity;
int Trace;
int Pause;
// ????????????????????????????????????
// I did this for you you just need to fill them in later.
float MassUnitConverter;
float LengthUnitConverter;
float TimeUnitConverter;
float GavityConstant;

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

// Prototyping functions
void Display();
void idle();
void reshape(int, int);
void KeyPressed(unsigned char, int, int);
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
	if(Pause == 0) nBody();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);
}

void KeyPressed(unsigned char key, int x, int y)
{
	// Turns tracers on and off
	if(key == 't')
	{
		if(Trace == 1) Trace = 0;
		else Trace = 1;
		drawPicture();
	}
	
	if(key == 'p')
	{
		if(Pause == 1) Pause = 0;
		else Pause = 1;
		drawPicture();
	}
}

void setInitailConditions()
{
	time_t t;
	float randomNumber;
	float halfBoxSideLength;
	float sphereRadius;
	float seperation;
	int test;
	
	// Seeding the random number generater.
	srand((unsigned) time(&t));
	
	// ??????????????????????????????????????????????????????????
	// For the units that we will use to contect us to the outside world let use 
	// kilometers (km)
	// kilograms (kg)
	// hours (hr)
	// If you multiply one of our units by this number it will convert it to the outside world units.
	// If you divide an outside world unit by this number it will convert it to our units
	// Set your convertion units then print them out.
	// Uncomment these and fix them.
	// MassUnitConverter = ???; // kg
	// LengthUnitConverter = ???; // km
	// TimeUnitConverter = ???; // hr
	// printf("\n MassUnitConverter = %f kilograms", MassUnitConverter);
	// printf("\n LengthUnitConverter = %f kilometers", LengthUnitConverter);
	// printf("\n TimeUnitConverter = %f hours", TimeUnitConverter);
	
	// ??????????????????????????????????????????????????????????
	// Set the GavityConstant. and print it out.
	// Uncomment these and fix them.
	// GavityConstant = ???;
	// printf("\n The gavity constant = %f in our units", GavityConstant);
	
	// ??????????????????????????????????????????????????????????
	// Anything with a mass, time or length needs to be thought about.
	// Coment about each of these. Most will may not need to be changed but just say why.
	SphereDiameter = 0.5;
	sphereRadius = SphereDiameter/2.0;
	SphereMass = 1.0;
	BoxSideLength = 5.0;
	MaxVelocity = 10.0;
	halfBoxSideLength = BoxSideLength/2.0;
	
	// ??????????????????????????????????????????????????????????
	// Print out how many kilometers long each box side is.
	// Print out how many kilometers/hour the max Velocity is.
	// Uncomment these and fix them.
	//printf("\n Box side length = %f kilometers", ???);
	//printf("\n Max velocity = %f kilometers/hour", ???);
	
	
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		// Settting the balls randomly in the box and not letting them be right on top of each other.
		test = 0;
		while(test == 0)
		{
			// Get random position.
			randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*(halfBoxSideLength - sphereRadius);
			Position[i].x = randomNumber;
			randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*(halfBoxSideLength - sphereRadius);
			Position[i].y = randomNumber;
			randomNumber = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*(halfBoxSideLength - sphereRadius);
			Position[i].z = randomNumber;
			
			// Making sure the balls centers are at least a diameter apart.
			// If they are not throw these positions away and try again.
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
		
		// ?????????????????????????????????????????
		// Asteriods are brown not just any color. 
		// Well I have not seen many asteriods maybe they are all the colors in the rainbow.
		// But make them brown anyway. 
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
	
	// ?????????????????????????????????????????
	// Make this a 10 day long run
	TotalRunTime = 10000.0;
	RunTime = 0.0;
	Dt = 0.001;
}

void drawPicture()
{
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
	
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
	float kWall, kBall;
	float halfSide = BoxSideLength/2.0;
	float amiuntOut;
	float ballRadius = SphereDiameter/2.0;
	float d, dx, dy, dz;
	float magnitude;
	
	kBall = 1000.0;
	for(int i = 0; i < NUMBER_OF_BALLS; i++)
	{
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;

		if((Position[i].x - ballRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].x - ballRadius);
			if(Velocity[i].x < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].x += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].x + ballRadius))
		{
			amiuntOut = (Position[i].x + ballRadius) - halfSide;
			if(0.0 < Velocity[i].x) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].x -= kWall*amiuntOut;
		}
		
		if((Position[i].y - ballRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].y - ballRadius);
			if(Velocity[i].y < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].y += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].y + ballRadius))
		{
			amiuntOut = (Position[i].y + ballRadius) - halfSide;
			if(0.0 < Velocity[i].y) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].y -= kWall*amiuntOut;
		}
		
		if((Position[i].z - ballRadius) < -halfSide)
		{
			amiuntOut = -halfSide - (Position[i].z - ballRadius);
			if(Velocity[i].z < 0.0) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].z += kWall*amiuntOut;
		}
		else if(halfSide < (Position[i].z + ballRadius))
		{
			amiuntOut = (Position[i].z + ballRadius) - halfSide;
			if(0.0 < Velocity[i].z) kWall = wallStiffnessIn;
			else kWall = wallStiffnessOut;
			Force[i].z -= kWall*amiuntOut;
		}
		
		for(int j = 0; j < i; j++)
		{
			dx = Position[j].x - Position[i].x;
			dy = Position[j].y - Position[i].y;
			dz = Position[j].z - Position[i].z;
			d = sqrt(dx*dx + dy*dy + dz*dz);
			
			// This causes the asteroids to bounce off of each other.
			if(d < SphereDiameter)
			{
				magnitude = kBall*d;
				// Doling out the force in the proper perfortions using unit vectors.
				Force[i].x -= magnitude*(dx/d);
				Force[i].y -= magnitude*(dy/d);
				Force[i].z -= magnitude*(dz/d);
				// A force on me causes the opposite force on you. 
				Force[j].x += magnitude*(dx/d);
				Force[j].y += magnitude*(dy/d);
				Force[j].z += magnitude*(dz/d);
			}
			
			// ???????????????????????????????????????????????????????
			// Add gravity between asteroids here.
			
			
			// Two elderly ladies get pulled over by a cop on I-35 in Dallas.
			// The cop says "Mam you were going 35 miles an hour in a 70. You are causing a trafic jam 
			// and may get someone, perhaps yourself, hurt".
			// He turns his atention to the lady in the pasangers seat and says "mam
			// are you okay", because she was breathing really hard and looked completely freaked out.
			// She replied " Yes young man I will be okay in a minute. We just pulled off of 
			// highway 114.
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
	// ??????????????????????????????????????????????
	// Print the time out in hours.
	printf("\n Time = %f hours ???", RunTime);
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
	Trace = 0;
	Pause = 1;
	setInitailConditions();
	printf("\033[0;31m\n\n The simulation is paused. Type p in the simulation window to start it. \n");
	printf("\033[0m");
}

int main(int argc, char** argv)
{
	startMeUp();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 
	
	// Clip plains
	Near = 0.2;
	Far = 2.2*BoxSideLength;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 1.1*BoxSideLength;

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
	glutKeyboardFunc(KeyPressed);
	//glutMouseFunc(mymouse);
	glutIdleFunc(idle);
	glutMainLoop();
	
	return 0;
}
