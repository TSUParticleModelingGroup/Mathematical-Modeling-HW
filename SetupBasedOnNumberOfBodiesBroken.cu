//nvcc SetupBasedOnNumberOfBodiesFixed.cu -o bounce -lglut -lm -lGLU -lGL																													
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

#define NUMBER_OF_BODIES 10
#define PI 3.14159
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position[NUMBER_OF_BODIES], Velocity[NUMBER_OF_BODIES], Force[NUMBER_OF_BODIES], Color[NUMBER_OF_BODIES];
float SphereMass;
float SphereDiameter;
float MaxVelocity;
int Trace;
int Pause;
int PrintRate;
int PrintCount;
int WallCount;

// Units and universal constants
double MassUnitConverter;
double LengthUnitConverter;
double TimeUnitConverter;
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
float4 centerOfMass();
float4 linearVelocity();
void zeroOutSystem();
void getForces();
void updatePositions();
void nBody();
void startMeUp();
void terminalPrint();

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
	if(key == 'g')
	{
		Pause = 1;
		terminalPrint();
		zeroOutSystem();
		
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Velocity[i].x += 20.0;
			Velocity[i].y += 0.0;
			Velocity[i].z += 0.0;
		}
		drawPicture();
		printf("\n Asteroids are ready to go.");
		printf("\n Press 'p' to hire them into the wall with a velocity of %f kilometers per hour.\n", 20.0*LengthUnitConverter/TimeUnitConverter);
	}
	
	if(key == 'k')
	{
		Pause = 1;
		terminalPrint();
		zeroOutSystem();
		drawPicture();
		printf("\n The simulation has been zeroed out.\n");
	}
	
	if(key == '1')
	{
		float4 pos, vel;
		Pause = 1;
		terminalPrint();
		pos = centerOfMass();
		printf("\n Center of mass = (%f, %f, %f)\n", pos.x, pos.y, pos.z); 
		vel = linearVelocity();
		printf("\n Linear velocity = (%f, %f, %f)\n", vel.x, vel.y, vel.z);
	}
	
	// Turns tracers on and off
	if(key == 't')
	{
		if(Trace == 1) Trace = 0;
		else Trace = 1;
		drawPicture();
		terminalPrint();
	}
	
	if(key == 'p')
	{
		if(Pause == 1) Pause = 0;
		else Pause = 1;
		drawPicture();
		terminalPrint();
	}
	
	float dx = 0.05f;
	if(key == 'x')
	{
		glTranslatef(-dx, 0.0, 0.0);
		drawPicture();
		terminalPrint();
	}
	if(key == 'X')
	{
		glTranslatef(dx, 0.0, 0.0);
		drawPicture();
	}
	
	float dy = 0.05f;
	if(key == 'y')
	{
		glTranslatef(0.0, -dy, 0.0);
		drawPicture();
		terminalPrint();
	}
	if(key == 'Y')
	{
		glTranslatef(0.0, dy, 0.0);
		drawPicture();
	}
	
	float dz = 0.05f;
	if(key == 'z')
	{
		glTranslatef(0.0, 0.0, -dz);
		drawPicture();
		terminalPrint();
	}
	if(key == 'Z')
	{
		glTranslatef(0.0, 0.0, dz);
		drawPicture();
	}
	
	if(key == 'q')
	{
		glutDestroyWindow(Window);
		printf("\nExiting....\n\nGood Bye\n");
		exit(0);
	}
}

void setInitailConditions()
{
	time_t t;
	float seperation;
	int test;
	float globeSize, angle1, angle2, radius;
	double massOfCeres;
	double diameterOfCeres;
	double densityOfCeres;
	double volumeOfCeres;
	double G = ????; //km^3/kg*hr^2
	
	// Seeding the random number generater.
	srand((unsigned) time(&t));
	
	// The units that we will use to contect us to the outside world are: 
	// kilometers (km)
	// kilograms (kg)
	// hours (hr)
	// If you multiply one of our units by this number it will convert it the outside world units.
	// If you divide an outside world unit by this number it will convert it to our units
	// We are setting the mass unit to be the mass of Ceres.
	// We are settting the length unit to be th diameter of Ceres.
	// We are setting the time unit to be the such that the universal gravity constant is 1.
	
	massOfCeres = ????; // kg
	diameterOfCeres = ????; // km
	densityOfCeres = ????; // kg/km^3
	volumeOfCeres = ????; // km^3
	
	MassUnitConverter = ????; // kg
	LengthUnitConverter = ????; // km
	TimeUnitConverter = ????; // hr
	
	printf("\n MassUnitConverter = %e kilograms", MassUnitConverter);
	printf("\n LengthUnitConverter = %e kilometers", LengthUnitConverter);
	printf("\n TimeUnitConverter = %e hours", TimeUnitConverter);
	
	// If we did everthing right the universal gravity constant should be 1.
	GavityConstant = 1.0;
	printf("\n The gavity constant = %f in our units", GavityConstant);
	
	// All spheres are the same diameter and mass so these should be 1..
	SphereDiameter = 1.0;
	SphereMass = 1.0;
	
	// Making the size of the intial globe we use to place the bodies.
	globeSize = 10.0*SphereDiameter;
	
	// You get to pick this but it is nice to print it out in common units to get a feel for what it is.
	MaxVelocity = 1.0;
	printf("\n Max velocity = %f kilometers/hour or %f miles/hour", MaxVelocity*LengthUnitConverter/TimeUnitConverter, (MaxVelocity*LengthUnitConverter/TimeUnitConverter)*0.621371);
	
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		// Settting the balls randomly in a large sphere and not letting them be right on top of each other.
		test = 0;
		while(test == 0)
		{
			// Get random position.
			angle1 = ((float)rand()/(float)RAND_MAX)*2.0*PI;
			angle2 = ((float)rand()/(float)RAND_MAX)*PI;
			radius = ((float)rand()/(float)RAND_MAX)*globeSize;
			Position[i].x = radius*cos(angle1)*sin(angle2);
			Position[i].y = radius*sin(angle1)*sin(angle2);
			Position[i].z = radius*cos(angle2);
			
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
		Velocity[i].x = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].y = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		Velocity[i].z = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*MaxVelocity;
		
		// Color of each asteroid. 
		Color[i].x = 0.35;
		Color[i].y = 0.22;
		Color[i].z = 0.16;
		
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	// Making it run for 10 days.
	// Taking days to hours then to our units.
	TotalRunTime = 10.0*24.0/TimeUnitConverter;
	RunTime = 0.0;
	Dt = 0.001;
	// How many time steps between termenal prints
	PrintRate = 10;
}

void drawPicture()
{
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
	
	// Drawing balls.
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		glColor3d(Color[i].x, Color[i].y, Color[i].z);
		glPushMatrix();
			glTranslatef(Position[i].x, Position[i].y, Position[i].z);
			glutSolidSphere(SphereDiameter/2.0, 30, 30);
		glPopMatrix();
	}
	
	// Drawing the wall.
	int temp;
	glBegin(GL_QUADS);
		temp = WallCount%511;
		if(temp <= 255)
		{
			glColor3d((float)temp/255.0, 0.0, 0.0);
		}
		else 
		{
			temp = 256 - temp%255;
			//glColor3d((float)temp/255.0, (float)temp/255.0, (float)temp/255.0);
			glColor3d((float)temp/255.0, 0.0, 0.0);
		}
		glVertex3f(25.0, -5.0, 5.0);
		glVertex3f(25.0, -5.0, -5.0);
		glVertex3f(25.0, 5.0, -5.0);
		glVertex3f(25.0, 5.0, 5.0);
		glVertex3f(25.0, -5.0, 5.0);
	glEnd();
	WallCount++;
	
	glColor3d(1.0, 0.0, 0.0);
	glPointSize(10.0f);
	glBegin(GL_POINTS);
		glVertex3f(25.0f, 0.0f, 0.0f);
	glEnd();
	
	glutSwapBuffers();
}

float4 centerOfMass()
{
	float totalMass;
	float4 centerOfMass;
	
	centerOfMass.x = 0.0;
	centerOfMass.y = 0.0;
	centerOfMass.z = 0.0;
	totalMass = 0.0;
	
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
    		centerOfMass.x += Position[i].x*SphereMass;
		centerOfMass.y += Position[i].y*SphereMass;
		centerOfMass.z += Position[i].z*SphereMass;
		totalMass += SphereMass;
	}
	centerOfMass.x /= totalMass;
	centerOfMass.y /= totalMass;
	centerOfMass.z /= totalMass;
	
	return(centerOfMass);
}

float4 linearVelocity()
{
	float totalMass;
	float4 linearVelocity;
	
	linearVelocity.x = 0.0;
	linearVelocity.y = 0.0;
	linearVelocity.z = 0.0;
	totalMass = 0.0;
	
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
    		linearVelocity.x += Velocity[i].x*SphereMass;
		linearVelocity.y += Velocity[i].y*SphereMass;
		linearVelocity.z += Velocity[i].z*SphereMass;
		totalMass += SphereMass;
	}
	linearVelocity.x /= totalMass;
	linearVelocity.y /= totalMass;
	linearVelocity.z /= totalMass;
	
	return(linearVelocity);
}

void zeroOutSystem()
{
	float4 pos, vel;
	pos = centerOfMass();
	vel = linearVelocity();
		
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		Position[i].x -= pos.x;
		Position[i].y -= pos.y;
		Position[i].z -= pos.z;
		
		Velocity[i].x -= vel.x;
		Velocity[i].y -= vel.y;
		Velocity[i].z -= vel.z;
	}
}

void getForces()
{
	float inOut;
	float kSphere,kSphereReduction;
	float kWall, kWallReduction;
	float4 d, unit, dv;
	float magnitude;
	float intersectionArea; 
	float sphereRadius = SphereDiameter/2.0;
	
	// Zeroing forces outside of the force loop just to be safe.
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	kWall = 20000.0;
	kWallReduction = 0.2;
	kSphere = 10000.0;
	kSphereReduction = 0.5;
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{	
		if(25.0 < Position[i].x + SphereDiameter/2.0 && Position[i].x + SphereDiameter/2.0 < 26.0)
		{
			if(-5.0 < Position[i].z && Position[i].z < 5.0 && -5.0 < Position[i].z && Position[i].z < 5.0)
			{
				if(0.0 < Velocity[i].x)
				{
					magnitude = (Position[i].x + SphereDiameter/2.0 - 25.0)*kWall;
				}
				else
				{
					magnitude = (Position[i].x + SphereDiameter/2.0 - 25.0)*kWall*kWallReduction;
				}
				Force[i].x -= magnitude;
			}
		}
		
		
		// This adds forces between asteriods.
		for(int j = 0; j < i; j++)
		{
			d.x = Position[j].x - Position[i].x;
			d.y = Position[j].y - Position[i].y;
			d.z = Position[j].z - Position[i].z;
			d.w = sqrt(d.x*d.x + d.y*d.y + d.z*d.z);
			unit.x = d.x/d.w;
			unit.y = d.y/d.w;
			unit.z = d.z/d.w;
			
			// Nonelastic sphere collisions 
			if(d.w < SphereDiameter)
			{
				// If the seperation gets too small the sphers may go through each other.
				// If you are ok with that you do not need this line.
				if(d.w < sphereRadius/10.0)
				{
					printf("\n Spheres %d and %d got to close. Make your sphere repultion stronger\n", i, j);
					exit(0);
				}
				
				intersectionArea = (PI/4.0)*(SphereDiameter*SphereDiameter - d.w*d.w);
				
				dv.x = Velocity[j].x - Velocity[i].x;
				dv.y = Velocity[j].y - Velocity[i].y;
				dv.z = Velocity[j].z - Velocity[i].z;
				inOut = d.x*dv.x + d.y*dv.y + d.z*dv.z;
				if(inOut < 0.0) magnitude = kSphere*intersectionArea; // If inOut is negative the sphere are converging.
				else magnitude = kSphereReduction*kSphere*intersectionArea; // If inOut is positive the sphere are diverging.
				
				//if(inOut < 0.0) magnitude = kSphere*(SphereDiameter - d.w); // If inOut is negative the sphere are converging.
				//else magnitude = kSphereReduction*kSphere*(SphereDiameter - d.w); // If inOut is positive the sphere are diverging.
				
				// Doling out the force in the proper perfortions using unit vectors.
				Force[i].x -= magnitude*unit.x;
				Force[i].y -= magnitude*unit.y;
				Force[i].z -= magnitude*unit.z;
				// A force on me causes the opposite force on you. 
				Force[j].x += magnitude*unit.x;
				Force[j].y += magnitude*unit.y;
				Force[j].z += magnitude*unit.z;
				
				// This adds the gravity between asteroids but the gravity is lock in at what it 
				// was at impact.
				magnitude = GavityConstant*SphereMass*SphereMass/(SphereDiameter*SphereDiameter);
				Force[i].x += magnitude*unit.x;
				Force[i].y += magnitude*unit.y;
				Force[i].z += magnitude*unit.z;
				
				Force[j].x -= magnitude*unit.x;
				Force[j].y -= magnitude*unit.y;
				Force[j].z -= magnitude*unit.z;
			}
			else
			{
				// This adds the gravity between asteroids when they are not touching.
				magnitude = GavityConstant*SphereMass*SphereMass/(d.w*d.w);
				Force[i].x += magnitude*unit.x;
				Force[i].y += magnitude*unit.y;
				Force[i].z += magnitude*unit.z;
				
				Force[j].x -= magnitude*unit.x;
				Force[j].y -= magnitude*unit.y;
				Force[j].z -= magnitude*unit.z;
			}
		}
	}
}

void updatePositions()
{
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
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
	
	RunTime += Dt;
	PrintCount++;
	
	if(PrintCount == PrintRate)
	{
		terminalPrint();
		PrintCount = 0;
	}
	
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
	PrintCount = 0;
	setInitailConditions();
	printf("\033[0;31m\n\n The simulation is paused. Type p in the simulation window to start it. \n");
	printf("\033[0m");
}

void terminalPrint()
{
	/*
	default  \033[0m
	Black:   \033[0;30m
	Red:     \033[0;31m
	Green:   \033[0;32m
	Yellow:  \033[0;33m
	Blue:    \033[0;34m
	Magenta: \033[0;35m
	Cyan:    \033[0;36m
	White:   \033[0;37m
	printf("\033[0;30mThis text is black.\033[0m\n");
	
	BOLD_ON  "\e[1m"
	BOLD_OFF   "\e[m"
	*/
	
	system("clear");
	
	printf("\n");
	printf("\n X/x: Move Right move left");
	printf("\n Y/y: Move Up move down");
	printf("\n Z/z: Move in move out");
	
	printf("\n");
	printf("\n k: Will zero out the center of mass and linear velocity of the system.");
	printf("\n 1: Will print the center of mass and the linear velocity of the system.");
	printf("\n");
	printf("\n g: Will center the asteroids then fire them into the wall on your comand.");
	printf("\n");
	printf("\033[0m");
	printf("\n t: Trace on/off toggle --> ");
	printf(" Tracing is:");
	if (Trace == 1) 
	{
		printf("\e[1m" " \033[0;32mON\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;31mOFF\n" "\e[m");
	}
	
	printf("\033[0m");
	printf(" p: pause on/off toggle --> ");
	printf(" The simulation is:");
	if (Pause == 1) 
	{
		printf("\e[1m" " \033[0;31mPaused\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mRunning\n" "\e[m");
	}
	
	printf(" q: Terminates the simulation");
	
	// Print the time out in hours.
	printf("\n\n Time = %f \033[0;34mhours", RunTime*TimeUnitConverter);
	printf("\033[0m");
	printf("\n");
}


int main(int argc, char** argv)
{
	startMeUp();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 

	// Clip plains
	Near = 0.2;
	Far = 50.0*SphereDiameter;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 25.0*SphereDiameter;

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
