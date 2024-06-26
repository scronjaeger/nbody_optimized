#include "planets.h"

#define RANDVEL 0.2
#define GRAVITATION 1.

#define WIDTH 1366
#define HEIGHT 768

#define SOFTENING 6.0
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define NUMPLANETS 8092

#define ALIGNEMENT 64

extern void glutSetOption(GLenum, int);
struct Planet
{
    double position[2];
    double velocity[2];
};

static char keyStates[256];
static struct Planet planets[NUMPLANETS];

void init(void)
{
    for(int i = 0; i < NUMPLANETS; i++)
    {
        planets[i].position[0] = rand() % WIDTH;
        planets[i].position[1] = rand() % HEIGHT;
        double x_diff          = planets[i].position[0] - WIDTH / 2.;
        double y_diff          = planets[i].position[1] - HEIGHT / 2.;

        double distance        = sqrt(x_diff * x_diff + y_diff * y_diff);
        double rand_x          = (double)(rand()) / (double)RAND_MAX * (RANDVEL * 2) - RANDVEL;
        double rand_y          = (double)(rand()) / (double)RAND_MAX * (RANDVEL * 2) - RANDVEL;
        planets[i].velocity[0] = -y_diff / sqrt(distance) * GRAVITATION * 0.1 + rand_x;
        planets[i].velocity[1] = x_diff / sqrt(distance) * GRAVITATION * 0.1 + rand_y;
    }
}

void updateWorld(void)
{
    for(int i = 0; i < NUMPLANETS; i++)
    {
        double a_x = 0.;
        double a_y = 0.;
        for(int j = 0; j < NUMPLANETS; j++)
        {
            if(j != i)
            {
                double distx = planets[j].position[0] - planets[i].position[0];
                double disty = planets[j].position[1] - planets[i].position[1];

                double distsqr = (distx * distx) + (disty * disty) + SOFTENING;
                double distinv = 1 / sqrt(distsqr);

                a_x += distinv * distinv * distinv * distx * GRAVITATION;
                a_y += distinv * distinv * distinv * disty * GRAVITATION;
            }
        }
        planets[i].velocity[0] += a_x;
        planets[i].velocity[1] += a_y;
    }
    for(int i = 0; i < NUMPLANETS; i++)
    {
        planets[i].position[0] += planets[i].velocity[0];
        planets[i].position[1] += planets[i].velocity[1];
    }
}

#ifdef VISUALIZE
void draw_planet(void)
{
    glColor3f(1.0f, 1.0f, 1.0f);
    glPointSize(2);
    glBegin(GL_POINTS);
    for(int i = 0; i < NUMPLANETS; i++)
    {
        glVertex2f((float)planets[i].position[0], (float)planets[i].position[1]);
    }
    glEnd();
}

void Initialize(void)
{
    glClearColor(0, 0, 0, 1.0);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, WIDTH, 0.0, HEIGHT, 0.0, 1.0);
}

void keyOperations(void)
{
    if(keyStates[114])
    {
        init();
        keyStates[114] = 0;
    }
    if(keyStates[113] || keyStates[27])
    {
        exit(0);
    }
}

void keyPressed(unsigned char key, int x, int y)
{
    keyStates[key] = 1;
}

void render(void)
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    draw_planet();
    glutSwapBuffers();
    keyOperations();
}

void update(void)
{
    updateWorld();
}

void timer(int value)
{
    update();

    glutTimerFunc(0, timer, 0);
    glutPostRedisplay();
}

int main(int argc, char *argv[])
{
    time_t t;
    srand((unsigned)time(&t));
    init();
    glutInit(&argc, argv);
    glutSetOption(GLUT_MULTISAMPLE, 8);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_MULTISAMPLE);
    glEnable(GL_MULTISAMPLE);
    glutInitWindowSize(WIDTH, HEIGHT);
    glutCreateWindow("Planets");
    glutFullScreen();
    Initialize();
    glutDisplayFunc(&render);
    glutKeyboardFunc(keyPressed);
    glutIdleFunc(NULL);

    glewInit();
    if(!GLEW_VERSION_2_0)
    {
        fprintf(stderr, "OpenGL 2.0 not available\n");
        return 1;
    }

    glutTimerFunc(0, timer, 0);
    glutMainLoop();

    return 0;
}
#else
int main(void)
{
    init();
    struct timespec start, end;
    int interval = 1;
    double elapsed;
    for(;;)
    {
        clock_gettime(CLOCK_MONOTONIC, &start);
        for(int i = 0; i < interval; i++)
        {
            updateWorld();
        }
        clock_gettime(CLOCK_MONOTONIC, &end);

        elapsed = (double)(end.tv_sec - start.tv_sec) + (double)(end.tv_nsec - start.tv_nsec) / 1e9;

        double gens = interval / elapsed;
        interval    = MAX((int)(interval / elapsed), 1);
        printf("%.2e g/s | %.2e OPS\n", gens, gens * NUMPLANETS * NUMPLANETS);
        fflush(stdout);
    }
}
#endif
