#include <GL/glew.h>
#include <GL/glut.h>
#include <math.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <time.h>

void memInit(void);
void cleanUp(int a);
void updateWorld(void);
void draw_planet(void);
int make_resources(void);
void Initialize(void);
void keyOperations(void);
void keyPressed(unsigned char key, int x, int y);
void render(void);
void update(void);
void timer(int value);
