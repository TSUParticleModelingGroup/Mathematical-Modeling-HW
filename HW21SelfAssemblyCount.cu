//nvcc SelfAssemblyCount.cu -o bounce2 -lglut -lm -lGLU -lGL																													
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

#define NUMBER_OF_BODIES 6
#define PI 3.14159
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position[NUMBER_OF_BODIES], Velocity[NUMBER_OF_BODIES], Force[NUMBER_OF_BODIES], Color[NUMBER_OF_BODIES];
float BodyMass[NUMBER_OF_BODIES], BodyRadius[NUMBER_OF_BODIES];

int Trace;
int Pause;
int PrintRate;
int PrintCount;
double TotalBodyDistance;
double PrintBodyDistance;
int PolyCount, OctCount, OtherCount;
int Iteration, CheckCount;
int ViewBodies;

double SetupMaxVelocity;
double SetupGlobeSize;
double Damp;
double StopTolerance;
int CheckRate;
double DepletionForce;
double CentralForce;

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
void setupBodies();
void drawPicture();
float4 centerOfMass();
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
	
	if(key == 'v')
	{
		if(ViewBodies == 1) ViewBodies = 0;
		else ViewBodies = 1;
		PrintCount = 0;
	}
	
	float dz = 0.05f;
	if(key == 'e')
	{
		glTranslatef(0.0, 0.0, -dz);
		drawPicture();
		terminalPrint();
	}
	if(key == 'E')
	{
		glTranslatef(0.0, 0.0, dz);
		drawPicture();
		terminalPrint();
	}
	
	if(key == 'x') // Counter clockwise x-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(dAngle)*Position[i].y - sin(dAngle)*Position[i].z;
			Position[i].z  = sin(dAngle)*Position[i].y + cos(dAngle)*Position[i].z;
			Position[i].y  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
	}
	if(key == 'X') // Clockwise x-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(-dAngle)*Position[i].y - sin(-dAngle)*Position[i].z;
			Position[i].z  = sin(-dAngle)*Position[i].y + cos(-dAngle)*Position[i].z;
			Position[i].y  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
	}
	if(key == 'y') // Counter clockwise y-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(-dAngle)*Position[i].x - sin(-dAngle)*Position[i].z;
			Position[i].z  = sin(-dAngle)*Position[i].x + cos(-dAngle)*Position[i].z;
			Position[i].x  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
	}
	if(key == 'Y') // Clockwise y-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(dAngle)*Position[i].x - sin(dAngle)*Position[i].z;
			Position[i].z  = sin(dAngle)*Position[i].x + cos(dAngle)*Position[i].z;
			Position[i].x  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
	}
	if(key == 'z') // Counter clockwise y-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(dAngle)*Position[i].x - sin(dAngle)*Position[i].y;
			Position[i].y  = sin(dAngle)*Position[i].x + cos(dAngle)*Position[i].y;
			Position[i].x  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
	}
	if(key == 'Z') // Clockwise y-axis
	{
		float4 com = centerOfMass();
		float dAngle = 0.01;
		float temp;
		for(int i = 0; i < NUMBER_OF_BODIES; i++)
		{
			Position[i].x -= com.x;
			Position[i].y -= com.y;
			Position[i].z -= com.z;
			temp = cos(-dAngle)*Position[i].x - sin(-dAngle)*Position[i].y;
			Position[i].y  = sin(-dAngle)*Position[i].x + cos(-dAngle)*Position[i].y;
			Position[i].x  = temp;
			Position[i].x += com.x;
			Position[i].y += com.y;
			Position[i].z += com.z;
		}
		drawPicture();
		terminalPrint();
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
 	// Seeding the random number generater.
	srand((unsigned) time(&t));
 	
	double diameterOfPolystyrene, densityOfPolystyrene, volumeOfPolystyrene, massOfPolystyrene;
	//double Kb = (8.649828e-13); //km^3/kg*hr^2
	
	// The units that we will use to connect us to the outside world are: 
	// micrometers (um) 10^-6 meters
	// picograms (pg) 10^-12 grams
	// littleseconds (ls) 10^-4 seconds
	
	diameterOfPolystyrene = 1.0; // micrometer
	densityOfPolystyrene = 1.05; // g/cm^3
	densityOfPolystyrene *= 1e12/(1e4*1e4*1e4); //pg/(um^3) This does nothing just put it here for clarity.
	volumeOfPolystyrene = (PI/6.0)*diameterOfPolystyrene*diameterOfPolystyrene*diameterOfPolystyrene; // um^3
	massOfPolystyrene = volumeOfPolystyrene*densityOfPolystyrene;
	
	printf("\n Diameter of Polystyrene = %e micrometers", diameterOfPolystyrene);
	printf("\n Density of Polystyrene = %e picograms/micron^3", densityOfPolystyrene);
	printf("\n Volume of Polystyrene = %e micrometers^3", volumeOfPolystyrene);
	printf("\n Mass of Polystyrene = %e picograms", massOfPolystyrene);
	printf("\n");
	
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		BodyMass[i] = massOfPolystyrene;
		BodyRadius[i] = diameterOfPolystyrene/2.0;
		
		// Color of each body. 
		Color[i].x = 0.35;
		Color[i].y = 0.22;
		Color[i].z = 0.16;
	}
	printf("\n");
	
	setupBodies();
	
	// Making it run for 1 second.
	TotalRunTime = 10000.0;
	RunTime = 0.0;
	Dt = 0.001;
	
	printf("\n");
	printf("\n Units Have Been Set.");
	printf("\n");
}

void setupBodies()
{
	double seperation;
	int test;
	int tryCount;
	double angle1, angle2, radius;
	
	TotalBodyDistance = 10000000.0; // Just set it to a big number so if will fail the first test.
	
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		// Settting the bodies randomly in a large sphere and not letting them be right on top of each other.
		test = 0;
		tryCount = 0;
		while(test == 0)
		{
			// Get random position.
			angle1 = ((float)rand()/(float)RAND_MAX)*2.0*PI;
			angle2 = ((float)rand()/(float)RAND_MAX)*PI;
			radius = ((float)rand()/(float)RAND_MAX)*SetupGlobeSize;
			Position[i].x = radius*cos(angle1)*sin(angle2);
			Position[i].y = radius*sin(angle1)*sin(angle2);
			Position[i].z = radius*cos(angle2);
			
			// Making sure the balls centers are at least a diameter apart.
			// If they are not throw these positions away and try again.
			test = 1;
			for(int j = 0; j < i; j++)
			{
				seperation = sqrt((Position[i].x-Position[j].x)*(Position[i].x-Position[j].x) + (Position[i].y-Position[j].y)*(Position[i].y-Position[j].y) + (Position[i].z-Position[j].z)*(Position[i].z-Position[j].z));
				if(seperation < (BodyRadius[i] + BodyRadius[j]))
				{
					test = 0;
					break;
				}
			}
			tryCount++;
			if(1000 < tryCount)
			{
				printf("\n\n We tried 1000 times to set the position of body %d unsuccessfully.",i);
				printf("\n Something is wrong with your setup.");
				printf("\n Good Bye. \n");
				exit(0);
			}
		}
		
		// Setting random velocities between -SetupMaxVelocity and SetupMaxVelocity.
		Velocity[i].x = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*SetupMaxVelocity;
		Velocity[i].y = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*SetupMaxVelocity;
		Velocity[i].z = (((float)rand()/(float)RAND_MAX)*2.0 - 1.0)*SetupMaxVelocity;
		
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
}

void drawPicture()
{
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
	
	// Drawing bodies.
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		glColor3d(Color[i].x, Color[i].y, Color[i].z);
		glPushMatrix();
			glTranslatef(Position[i].x, Position[i].y, Position[i].z);
			glutSolidSphere(BodyRadius[i], 30, 30);
		glPopMatrix();
	}
	
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
    		centerOfMass.x += Position[i].x*BodyMass[i];
		centerOfMass.y += Position[i].y*BodyMass[i];
		centerOfMass.z += Position[i].z*BodyMass[i];
		totalMass += BodyMass[i];
	}
	centerOfMass.x /= totalMass;
	centerOfMass.y /= totalMass;
	centerOfMass.z /= totalMass;
	
	return(centerOfMass);
}

void getForces()
{
	double inOut;
	double kSphere,kSphereReduction;
	float4 d, unit, dv;
	double magnitude;
	double intersectionArea; 
	double epsilon = 0.01;
	double r1,r2,temp;
	
	// Zeroing forces outside of the force loop just to be safe.
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		Force[i].x = 0.0;
		Force[i].y = 0.0;
		Force[i].z = 0.0;
	}
	
	kSphere = 10000.0;
	kSphereReduction = 0.2;
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{	
		// This adds forces between bodies.
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
			if(d.w < (BodyRadius[i] + BodyRadius[j]))
			{
				// If the seperation gets too small the sphers may go through each other.
				// If you are ok with that you do not need this if statement.
				if(d.w < epsilon)
				{
					printf("\n Spheres %d and %d got to close. Make your sphere repultion stronger\n", i, j);
					exit(0);
				}
				
				// Finding which body is largest.
				if(BodyRadius[j] < BodyRadius[i])
				{
					r1 = BodyRadius[i];
					r2 = BodyRadius[j];
				}
				else
				{
					r1 = BodyRadius[j];
					r2 = BodyRadius[i];
				}
				
				// Finding the intection area.
				// The intersection area gets too large (If one spherez goes into the other).
				// Set it as the radius of the smaller sphere.
				temp = ((r2*r2 - r1*r1 + d.w*d.w)/(2.0*d.w));
				if(0.0 < temp)
				{
					intersectionArea = PI*(r2*r2 - temp*temp);
				}
				else
				{
					intersectionArea = PI*(r2*r2);
				}
				
				dv.x = Velocity[j].x - Velocity[i].x;
				dv.y = Velocity[j].y - Velocity[i].y;
				dv.z = Velocity[j].z - Velocity[i].z;
				inOut = d.x*dv.x + d.y*dv.y + d.z*dv.z;
				if(inOut < 0.0) magnitude = kSphere*intersectionArea; // If inOut is negative the sphere are converging.
				else magnitude = kSphereReduction*kSphere*intersectionArea; // If inOut is positive the sphere are diverging.
				
				// Doling out the force in the proper perfortions using unit vectors.
				Force[i].x -= magnitude*unit.x;
				Force[i].y -= magnitude*unit.y;
				Force[i].z -= magnitude*unit.z;
				// A force on me causes the opposite force on you. 
				Force[j].x += magnitude*unit.x;
				Force[j].y += magnitude*unit.y;
				Force[j].z += magnitude*unit.z;
			}
			else if(d.w < (BodyRadius[i] + BodyRadius[j]) + 0.08) 
			{
				// This adds the depletion force between bodies.
				Force[i].x += DepletionForce*unit.x;
				Force[i].y += DepletionForce*unit.y;
				Force[i].z += DepletionForce*unit.z;
				
				Force[j].x -= DepletionForce*unit.x;
				Force[j].y -= DepletionForce*unit.y;
				Force[j].z -= DepletionForce*unit.z;
			}
		}
		
		// This adds a small central atraction force as a fraction of the depletion force.
		d.x = Position[i].x;
		d.y = Position[i].y;
		d.z = Position[i].z;
		d.w = sqrt(d.x*d.x + d.y*d.y + d.z*d.z);
		unit.x = d.x/d.w;
		unit.y = d.y/d.w;
		unit.z = d.z/d.w;
		Force[i].x += CentralForce*unit.x;
		Force[i].y += CentralForce*unit.y;
		Force[i].z += CentralForce*unit.z;
	}
}

void updatePositions()
{
	for(int i = 0; i < NUMBER_OF_BODIES; i++)
	{
		// These are the LeapFrog formulas.
		if(RunTime == 0.0)
		{
			Velocity[i].x += (Force[i].x/BodyMass[i] - Velocity[i].x*Damp)*(Dt/2.0);
			Velocity[i].y += (Force[i].y/BodyMass[i] - Velocity[i].y*Damp)*(Dt/2.0);
			Velocity[i].z += (Force[i].z/BodyMass[i] - Velocity[i].z*Damp)*(Dt/2.0);
		}
		else
		{
			Velocity[i].x += (Force[i].x/BodyMass[i] - Velocity[i].x*Damp)*Dt;
			Velocity[i].y += (Force[i].y/BodyMass[i] - Velocity[i].y*Damp)*Dt;
			Velocity[i].z += (Force[i].z/BodyMass[i] - Velocity[i].z*Damp)*Dt;
		}

		Position[i].x += Velocity[i].x*Dt;
		Position[i].y += Velocity[i].y*Dt;
		Position[i].z += Velocity[i].z*Dt;
	}
}

void nBody()
{	
	float4 d;
	double newTotalBodyDistance;
	getForces();
	updatePositions();
	
	RunTime += Dt;
	PrintCount++;
	CheckCount++;
	
	if(CheckRate < CheckCount)
	{
		newTotalBodyDistance = 0.0;
		for(int i = 0; i < NUMBER_OF_BODIES - 1; i++)
		{
			for(int j = i + 1; j < NUMBER_OF_BODIES; j++)
			{
				d.x = Position[j].x - Position[i].x;
				d.y = Position[j].y - Position[i].y;
				d.z = Position[j].z - Position[i].z;
				d.w = sqrt(d.x*d.x + d.y*d.y + d.z*d.z);
				newTotalBodyDistance += d.w;
			}
		}
		if(fabs(newTotalBodyDistance - TotalBodyDistance) < StopTolerance)
		{
			if(16.8 < newTotalBodyDistance && newTotalBodyDistance < 17.2) PolyCount++;
			else if(16.0 < newTotalBodyDistance && newTotalBodyDistance < 16.4) OctCount++;
			else OtherCount++;
			if(OctCount != 0)
			{
				printf("\n %d: %d, %d, %d Ratio = %f -- Distance = %f \n", Iteration, PolyCount, OctCount, OtherCount, (float)PolyCount/(float)OctCount, newTotalBodyDistance);
			}
			else
			{
				printf("\n %d: %d, %d, %d -- Distance = %f \n", Iteration, PolyCount, OctCount, OtherCount, newTotalBodyDistance);
			}
			TotalBodyDistance = 0.0;
			drawPicture();
			setupBodies();
			CheckCount = 0;
			Iteration++;
		}
		else
		{
			TotalBodyDistance = newTotalBodyDistance;
			CheckCount = 0;
		}
	}
	
	if(ViewBodies == 1)
	{
		drawPicture();
		
		if(PrintCount == PrintRate)
		{
			PrintBodyDistance = 0.0;
			for(int i = 0; i < NUMBER_OF_BODIES - 1; i++)
			{
				for(int j = i + 1; j < NUMBER_OF_BODIES; j++)
				{
					d.x = Position[j].x - Position[i].x;
					d.y = Position[j].y - Position[i].y;
					d.z = Position[j].z - Position[i].z;
					d.w = sqrt(d.x*d.x + d.y*d.y + d.z*d.z);
					PrintBodyDistance += d.w;
				}
			}
			terminalPrint();
			PrintCount = 0;
		}
	}
}

void startMeUp() 
{	
	// The Rolling Stones
	// Tattoo You: 1981
	Trace = 0;
	Pause = 1;
	ViewBodies = 1;
	
	PrintRate = 10;
	PrintCount = 0;
	
	PolyCount = 0; 
	OctCount = 0;
	OtherCount = 0;
	
	CheckCount = 0;
	Iteration = 1;
	
	DepletionForce = 2.07097375; //pg*microM/MyS^2
	
	// Choose different central force strengths (should be grounded to the depletion force) and damping 
	// to see if you can find break points in the ratio of oct to poly.
	// Should run for a few hundred interations. Maybe a 1000.
	CentralForce = -0.1*DepletionForce;
	Damp = 0.1;
	
	SetupMaxVelocity = 1.1;
	SetupGlobeSize = 20.0;
	StopTolerance = 0.0001;
	CheckRate = 10000;
	
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
	printf("\n X/x: Clockwise/Counter Clockwise Rotation X-axis");
	printf("\n Y/y: Clockwise/Counter Clockwise Rotation Y-axis");
	printf("\n Z/z: Clockwise/Counter Clockwise Rotation Z-axis");
	printf("\n E/e: Zoom In/Zoom Out");
	
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
	printf(" p: Pause on/off toggle --> ");
	printf(" The simulation is:");
	if (Pause == 1) 
	{
		printf("\e[1m" " \033[0;31mPaused\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mRunning\n" "\e[m");
	}
	
	printf(" v: Viewing on/off toggle = %d", ViewBodies);
	printf("\n");
	printf(" q: Terminates the simulation");
	
	// Print the time out in hours. TotalBodyDistance;
	printf("\n\n Time = %f seconds 10^-4", RunTime);
	printf("\n TotalBodyDistance = %f microns", PrintBodyDistance);
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
	Far = 50.0;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = SetupGlobeSize;

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
