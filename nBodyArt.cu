// nvcc nBodyArtB.cu -o nBodyArt -lglut -lm -lGLU -lGL																																							
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
using namespace std;

FILE* ffmpeg;

// defines for terminal stuff.
#define BOLD_ON  "\e[1m"
#define BOLD_OFF   "\e[m"

FILE* MovieFile;

// Globals
int NumberOfBodies;
float TotalRunTime;
float Dt;
float G;
float H;
float Epsilon;
float MassOfBody;
float DiameterOfBody;
float VelocityMax;
float Drag;
int DrawRate;
int PrintRate;

// Other Globals
int Pause;
float *BodyPositionX, *BodyPositionY, *BodyPositionZ;
float *BodyVelocityX, *BodyVelocityY, *BodyVelocityZ;
float *BodyForceX, *BodyForceY, *BodyForceZ;
float *BodyColorX, *BodyColorY, *BodyColorZ;
int DrawTimer, PrintTimer;
float RunTime;
int* Buffer;
int MovieOn;
int MovieFlag;
int Trace;
double MouseX, MouseY, MouseZ;

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
void setSimulationParameters();
void allocateMemory();
void setInitailConditions();
void drawPicture();
void nBody();
void errorCheck(const char*);
void terminalPrint();
void setup();
void movieOn();
void movieOff();
void screenShot();
float4 centerOfMass();
float4 linearVelocity();
void zeroOutSystem();

//#include "./callBackFunctions.h"

void Display()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glClear(GL_DEPTH_BUFFER_BIT);
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

void KeyPressed(unsigned char key, int x, int y)
{	
	if(key == 'q')
	{
		pclose(ffmpeg);
		glutDestroyWindow(Window);
		printf("\nw Good Bye\n");
		exit(0);
	}
	if(key == 'o')
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-1.0, 1.0, -1.0, 1.0, Near, Far);
		glMatrixMode(GL_MODELVIEW);
		drawPicture();
	}
	if(key == 'f')
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
		glMatrixMode(GL_MODELVIEW);
		drawPicture();
	}
	if(key == 'p')
	{
		if(Pause == 1) Pause = 0;
		else Pause = 1;
		drawPicture();
		terminalPrint();
	}
	if(key == 't') // Turns tracers on and off
	{
		if(Trace == 1) Trace = 0;
		else Trace = 1;
		drawPicture();
		terminalPrint();
	}
	if(key == 'M')  // Movie on/off
	{
		if(MovieFlag == 0) 
		{
			MovieFlag = 1;
			movieOn();
		}
		else 
		{
			MovieFlag = 0;
			movieOff();
		}
		terminalPrint();
	}
	
	if(key == 'S')  // Screenshot
	{	
		screenShot();
		terminalPrint();
	}
}

void mousePassiveMotionCallback(int x, int y) 
{
	// This function is called when the mouse moves without any button pressed
	// x and y are the current mouse coordinates
	
	// x and y come in as 0 to XWindowSize and 0 to YWindowSize. 
	// Use this if you choose to.
}

// This is called when you push a mouse button.
void mymouse(int button, int state, int x, int y)
{	
	if(state == GLUT_DOWN)
	{	
		if(button == GLUT_LEFT_BUTTON)
		{	
			// Do stuff in here if you choose to when the left mouse button is pressed.
		}
		else if(button == GLUT_RIGHT_BUTTON) // Right Mouse button down
		{
			// Do stuff in here if you choose to when the right mouse button is pressed.
		}
		else if(button == GLUT_MIDDLE_BUTTON)
		{
			// Do stuff in here if you choose to when the middle mouse button is pressed.
		}
	}
	
	// If no mouse button is down (state 0, they don't have a nice word like GLUT_NOT_DOWN) 
	// but you move the mouse wheel this is called.
	if(state == 0)
	{
		// When you turn the mouse whell forward this is called.
		if(button == 3)
		{
		
		}
		
		// When you turn the mouse whell backward this is called.
		else if(button == 4)
		{
		
		}
	}
}

string getTimeStamp()
{
	// Want to get a time stamp string representing current date/time, so we have a
	// unique name for each video/screenshot taken.
	time_t t = time(0); 
	struct tm * now = localtime( & t );
	int month = now->tm_mon + 1, day = now->tm_mday, year = now->tm_year, 
				curTimeHour = now->tm_hour, curTimeMin = now->tm_min, curTimeSec = now->tm_sec;
	stringstream smonth, sday, syear, stimeHour, stimeMin, stimeSec;
	smonth << month;
	sday << day;
	syear << (year + 1900); // The computer starts counting from the year 1900, so 1900 is year 0. So we fix that.
	stimeHour << curTimeHour;
	stimeMin << curTimeMin;
	stimeSec << curTimeSec;
	string timeStamp;

	if (curTimeMin <= 9)	
		timeStamp = smonth.str() + "-" + sday.str() + "-" + syear.str() + '_' + stimeHour.str() + ".0" + stimeMin.str() + 
					"." + stimeSec.str();
	else			
		timeStamp = smonth.str() + "-" + sday.str() + '-' + syear.str() + "_" + stimeHour.str() + "." + stimeMin.str() +
					"." + stimeSec.str();
	return timeStamp;
}

void movieOn()
{
	string ts = getTimeStamp();
	ts.append(".mp4");

	// Setting up the movie buffer.
	/*const char* cmd = "ffmpeg -loglevel quiet -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
		      "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output.mp4";*/

	string baseCommand = "ffmpeg -loglevel quiet -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
				"-c:v libx264rgb -threads 0 -preset fast -y -pix_fmt yuv420p -crf 0 -vf vflip ";

	string z = baseCommand + ts;

	const char *ccx = z.c_str();
	MovieFile = popen(ccx, "w");
	//Buffer = new int[XWindowSize*YWindowSize];
	Buffer = (int*)malloc(XWindowSize*YWindowSize*sizeof(int));
	MovieOn = 1;
}

void movieOff()
{
	if(MovieOn == 1) 
	{
		pclose(MovieFile);
	}
	free(Buffer);
	MovieOn = 0;
}

void screenShot()
{	
	int pauseFlag;
	FILE* ScreenShotFile;
	int* buffer;

	const char* cmd = "ffmpeg -loglevel quiet -framerate 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
				"-c:v libx264rgb -threads 0 -preset fast -y -crf 0 -vf vflip output1.mp4";
	//const char* cmd = "ffmpeg -r 60 -f rawvideo -pix_fmt rgba -s 1000x1000 -i - "
	//              "-threads 0 -preset fast -y -pix_fmt yuv420p -crf 21 -vf vflip output1.mp4";
	ScreenShotFile = popen(cmd, "w");
	buffer = (int*)malloc(XWindowSize*YWindowSize*sizeof(int));
	
	if(Pause == 0) 
	{
		Pause = 1;
		pauseFlag = 0;
	}
	else
	{
		pauseFlag = 1;
	}
	
	for(int i =0; i < 1; i++)
	{
		drawPicture();
		glReadPixels(5, 5, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
		fwrite(buffer, sizeof(int)*XWindowSize*YWindowSize, 1, ScreenShotFile);
	}
	
	pclose(ScreenShotFile);
	free(buffer);

	string ts = getTimeStamp(); // Only storing in a separate variable for debugging purposes.
	string s = "ffmpeg -loglevel quiet -i output1.mp4 -qscale:v 1 -qmin 1 -qmax 1 " + ts + ".jpeg";
	// Convert back to a C-style string.
	const char *ccx = s.c_str();
	system(ccx);
	system("rm output1.mp4");
	printf("\nScreenshot Captured: \n");
	cout << "Saved as " << ts << ".jpeg" << endl;

	
	//system("ffmpeg -i output1.mp4 screenShot.jpeg");
	//system("rm output1.mp4");
	
	Pause = pauseFlag;
	//ffmpeg -i output1.mp4 output_%03d.jpeg
}

void setSimulationParameters()
{
	NumberOfBodies = 16;

	TotalRunTime = 10000.0;

	Dt = 0.002;

	// This is a lennard-Jones type force G*m1*m2/(r^2) - H*m1*m2/(r^4).
	// If you want a gravity type force just set G to your gravity and set H equal 0.
	G = 0.03;

	H = 0.0;

	Epsilon = 0.01;

	MassOfBody = 1.0;

	DiameterOfBody = 0.2;

	VelocityMax = 0.0;

	Drag = 0.001;

	DrawRate = 8;
	
	PrintRate = 100;
}

void allocateMemory()
{
	BodyPositionX = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyPositionY = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyPositionZ = (float*)malloc(NumberOfBodies*sizeof(float));
	
	BodyVelocityX = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyVelocityY = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyVelocityZ = (float*)malloc(NumberOfBodies*sizeof(float));
	
	BodyForceX    = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyForceY    = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyForceZ    = (float*)malloc(NumberOfBodies*sizeof(float));
	
	BodyColorX    = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyColorY    = (float*)malloc(NumberOfBodies*sizeof(float));
	BodyColorZ    = (float*)malloc(NumberOfBodies*sizeof(float));
}

void setInitailConditions()
{
    float dx, dy, dz, d, d2;
    int test;
	time_t t;
	
	srand((unsigned) time(&t));
	for(int i = 0; i < NumberOfBodies; i++)
	{
		test = 0;
		while(test == 0)
		{
			// Get random number between -1 at 1.
			BodyPositionX[i] = ((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			BodyPositionY[i] = ((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			BodyPositionZ[i] = 0.0;  //((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
			test = 1;
			
			for(int j = 0; j < i; j++)
			{
				dx = BodyPositionX[i] - BodyPositionX[j];
				dy = BodyPositionY[i] - BodyPositionY[j];
				dz = BodyPositionZ[i] - BodyPositionZ[j];
				d2  = dx*dx + dy*dy + dz*dz;
				d = sqrt(d2);
				if(d < DiameterOfBody)
				{
					test = 0;
					break;
				}
			}
			
			if(test == 1)
			{
				BodyVelocityX[i] = 0.0; //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				BodyVelocityY[i] = 0.0; //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				BodyVelocityZ[i] = 0.0;  //VelocityMax*((float)rand()/(float)RAND_MAX)*2.0 - 1.0;
				
				BodyColorX[i] = ((float)rand()/(float)RAND_MAX);
				BodyColorY[i] = ((float)rand()/(float)RAND_MAX);
				BodyColorZ[i] = ((float)rand()/(float)RAND_MAX);
			}
		}
	}
}

float4 centerOfMass()
{
	float totalMass;
	float4 centerOfMass;
	
	centerOfMass.x = 0.0;
	centerOfMass.y = 0.0;
	centerOfMass.z = 0.0;
	totalMass = 0.0;
	
	for(int i = 0; i < NumberOfBodies; i++)
	{
    		centerOfMass.x += BodyPositionX[i]*MassOfBody;
		centerOfMass.y += BodyPositionY[i]*MassOfBody;
		centerOfMass.z += BodyPositionZ[i]*MassOfBody;
		totalMass += MassOfBody;
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
	
	for(int i = 0; i < NumberOfBodies; i++)
	{
    		linearVelocity.x += BodyVelocityX[i]*MassOfBody;
		linearVelocity.y += BodyVelocityY[i]*MassOfBody;
		linearVelocity.z += BodyVelocityZ[i]*MassOfBody;
		totalMass += MassOfBody;
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
		
	for(int i = 0; i < NumberOfBodies; i++)
	{
		BodyPositionX[i] -= pos.x;
		BodyPositionY[i] -= pos.y;
		BodyPositionZ[i] -= pos.z;
		
		BodyVelocityX[i] -= vel.x;
		BodyVelocityY[i] -= vel.y;
		BodyVelocityZ[i] -= vel.z;
	}
}

void drawPicture()
{
	if(Trace == 0)
	{
		glClear(GL_COLOR_BUFFER_BIT);
		glClear(GL_DEPTH_BUFFER_BIT);
	}
		
	for(int i = 0; i < NumberOfBodies; i++)
	{
		glColor3d(BodyColorX[i], BodyColorY[i], BodyColorZ[i]);
		glPushMatrix();
			glTranslatef(BodyPositionX[i], BodyPositionY[i], BodyPositionZ[i]);
			glutSolidSphere(DiameterOfBody/2.0, 20, 20);
		glPopMatrix();
	}
	glutSwapBuffers();
	
	if(MovieOn == 1)
	{
		glReadPixels(5, 5, XWindowSize, YWindowSize, GL_RGBA, GL_UNSIGNED_BYTE, Buffer);
		fwrite(Buffer, sizeof(int)*XWindowSize*YWindowSize, 1, MovieFile);
	}
}

void getForces(float *posX, float *posY,float *posZ, float *velX, float *velY, float *velZ, float *forceX, float *forceY, float *forceZ, float mass, float G, float H, float Epsilon, float drag, float dt, int n)
{
	float dx, dy, dz, d2, d;
	float forceMag;
    
	for(int i = 0; i < n; i++)
	{
		forceX[i] = 0.0;
		forceY[i] = 0.0;
		forceZ[i] = 0.0;
	}
	
	// Getting force
	for(int i = 0; i < n; i++)
	{   
		for(int j = i + 1; j < n; j++)
		{
			dx = posX[j] - posX[i];
			dy = posY[j] - posY[i];
			dz = posZ[j] - posZ[i];
		 	d2 = dx*dx + dy*dy + dz*dz + Epsilon;
		 	d = sqrt(d2);
			forceMag  = (G*mass*mass)/(d2) - (H*mass*mass)/(d2*d2);
			forceX[i] += forceMag*dx/d;
			forceY[i] += forceMag*dy/d;
			forceZ[i] += forceMag*dz/d;
			forceX[j] -= forceMag*dx/d;
			forceY[j] -= forceMag*dy/d;
			forceZ[j] -= forceMag*dz/d;
		}
    	}
    
    	// Updating positions
	for(int i = 0; i < n; i++)
	{
		velX[i] += ((forceX[i] - drag*velX[i])/mass)*dt;
		velY[i] += ((forceY[i] - drag*velY[i])/mass)*dt;
		velZ[i] += ((forceZ[i] - drag*velZ[i])/mass)*dt;
		
		posX[i] += velX[i]*dt;
		posY[i] += velY[i]*dt;
		posZ[i] += velZ[i]*dt;
	}
}

void nBody()
{
	if(Pause != 1)
	{	
		getForces(BodyPositionX, BodyPositionY, BodyPositionZ, BodyVelocityX, BodyVelocityY, BodyVelocityZ, BodyForceX, BodyForceY, BodyForceZ, MassOfBody,  G,  H,  Epsilon,  Drag, Dt, NumberOfBodies);
        
        	DrawTimer++;
		if(DrawTimer == DrawRate) 
		{
			drawPicture();
			DrawTimer = 0;
		}
		
		PrintTimer++;
		if(PrintTimer == PrintRate) 
		{
			terminalPrint();
			PrintTimer = 0;
		}
		
		RunTime += Dt; 
		if(TotalRunTime < RunTime)
		{
			printf("\n\n Done\n");
			exit(0);
		}
	}
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
	
	printf("\n\n");
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
	
	printf("\n");
	printf("\033[0m");
	printf(" t: Trace on/off toggle --> ");
	printf(" Trace is:");
	if (Trace == 1) 
	{
		printf("\e[1m" " \033[0;31mOn\n" "\e[m");
	}
	else 
	{
		printf("\e[1m" " \033[0;32mOff\n" "\e[m");
	}
	
	printf("\n M: Video On/Off toggle --> ");
	if (MovieFlag == 0) 
	{
		printf("\033[0;31m");
		printf(BOLD_ON "Video Recording Off" BOLD_OFF); 
	}
	else 
	{
		printf("\033[0;32m");
		printf(BOLD_ON "Video Recording On" BOLD_OFF);
	}
	
	printf("\n");
	printf("\n S: Screenshot");
	
	printf("\n");
	printf("\n q: Terminates the simulation");
	
	printf("\n");
}

void setup()
{	
	setSimulationParameters();
	allocateMemory();
	setInitailConditions();
	zeroOutSystem();
    	DrawTimer = 0;
    	PrintRate = 0;
	RunTime = 0.0;
	Trace = 0;
	Pause = 1;
	MovieOn = 0;
	terminalPrint();
}

int main(int argc, char** argv)
{
	setup();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 
	//Buffer = new int[XWindowSize*YWindowSize];

	// Clip plains
	Near = 0.2;
	Far = 30.0;

	//Direction here your eye is located location
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 2.0;

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
	Window = glutCreateWindow("N Body");
	
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
	glMatrixMode(GL_MODELVIEW);
	glClearColor(0.0, 0.0, 0.0, 0.0);
	
	GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
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
	
	glutPassiveMotionFunc(mousePassiveMotionCallback);
	glutMouseFunc(mymouse);
	glutDisplayFunc(Display);
	glutReshapeFunc(reshape);
	glutKeyboardFunc(KeyPressed);
	glutIdleFunc(idle);
	terminalPrint();
	glutMainLoop();
	return 0;
}






