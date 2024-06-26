#include "planets.h"

#include <cuda_runtime.h>
#include <curand.h>
#include <curand_kernel.h>

#define RANDVEL 0.2f
#define GRAVITATION 0.02f

#define WIDTH 1366
#define HEIGHT 768

#define BLOCK_SIZE 256

#define SOFTENING 6.0
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define NUMPLANETS 64736

#define ALIGNEMENT 64

void CHECK_CUDA_ERR(cudaError_t error)
{
    if(error != cudaSuccess)
    {
        printf("code: %d, reason: %s\n", error, cudaGetErrorString(error));
        exit(1);
    }
}

extern "C"
{
    extern void glutSetOption(GLenum, int);
}
struct Planet
{
    float2 position;
    float2 velocity;
    float2 acceleration;
};

static struct Planet *host_planets;
static struct Planet *device_planets;

static dim3 block(BLOCK_SIZE);
static dim3 grid((NUMPLANETS + BLOCK_SIZE - 1) / BLOCK_SIZE);

void init(void)
{
    for(int i = 0; i < NUMPLANETS; i++)
    {
        host_planets[i].position.x = rand() % WIDTH;
        host_planets[i].position.y = rand() % HEIGHT;
        float x_diff               = host_planets[i].position.x - WIDTH / 2.f;
        float y_diff               = host_planets[i].position.y - HEIGHT / 2.f;

        float rand_x = (float)(rand()) / (float)RAND_MAX * (RANDVEL * 2) - RANDVEL;
        float rand_y = (float)(rand()) / (float)RAND_MAX * (RANDVEL * 2) - RANDVEL;

        float distance             = sqrtf(x_diff * x_diff + y_diff * y_diff);
        host_planets[i].velocity.x = -y_diff / sqrtf(distance) * 2 * GRAVITATION + rand_x;
        host_planets[i].velocity.y = x_diff / sqrtf(distance) * 2 * GRAVITATION + rand_y;
    }
}

__global__ void calcForces(struct Planet *planets)
{
    int i = (int)(blockIdx.x * blockDim.x + threadIdx.x);
    if(i < NUMPLANETS)
    {
        float2 force = make_float2(0.f, 0.f);
        for(int j = 0; j < NUMPLANETS; j++)
        {
            if(i != j)
            {
                float2 direction;
                direction.x = planets[j].position.x - planets[i].position.x;
                direction.y = planets[j].position.y - planets[i].position.y;

                float distsqr = (direction.x * direction.x) + (direction.y * direction.y) + SOFTENING;
                float distinv = 1 / sqrtf(distsqr);

                force.x += distinv * distinv * distinv * direction.x * GRAVITATION;
                force.y += distinv * distinv * distinv * direction.y * GRAVITATION;
            }
        }
        planets[i].acceleration = force;
    }
}

__global__ void updateVelPos(struct Planet *planets)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if(i < NUMPLANETS)
    {
        planets[i].velocity.x += planets[i].acceleration.x;
        planets[i].velocity.y += planets[i].acceleration.y;
        planets[i].position.x += planets[i].velocity.x;
        planets[i].position.y += planets[i].velocity.y;
    }
}

#ifdef VISUALIZE

static char keyStates[256];

void draw_planet(void)
{
    glColor3f(1.0f, 1.0f, 1.0f);
    glPointSize(1);
    glBegin(GL_POINTS);
    for(int i = 0; i < NUMPLANETS; i++)
    {
        glVertex2f(host_planets[i].position.x, host_planets[i].position.y);
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
        CHECK_CUDA_ERR(
            cudaMemcpy(device_planets, host_planets, NUMPLANETS * sizeof(struct Planet), cudaMemcpyHostToDevice));

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
    CHECK_CUDA_ERR(
        cudaMemcpy(host_planets, device_planets, NUMPLANETS * sizeof(struct Planet), cudaMemcpyDeviceToHost));
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    draw_planet();
    glutSwapBuffers();
    keyOperations();
}

void update(void)
{
    calcForces<<<grid, block>>>(device_planets);
    CHECK_CUDA_ERR(cudaGetLastError());

    updateVelPos<<<grid, block>>>(device_planets);
    CHECK_CUDA_ERR(cudaGetLastError());

    CHECK_CUDA_ERR(cudaDeviceSynchronize());
}

void timer(int value)
{
    update();

    glutTimerFunc(0, timer, 0);
    glutPostRedisplay();
}

int main(int argc, char *argv[])
{
    host_planets = (struct Planet *)malloc(sizeof(struct Planet) * NUMPLANETS);
    init();
    CHECK_CUDA_ERR(cudaMalloc((void **)&device_planets, sizeof(struct Planet) * NUMPLANETS));
    CHECK_CUDA_ERR(
        cudaMemcpy(device_planets, host_planets, NUMPLANETS * sizeof(struct Planet), cudaMemcpyHostToDevice));

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
    struct timespec start, end;

    time_t t;
    srand((unsigned)time(&t));

    host_planets = (struct Planet *)malloc(sizeof(struct Planet) * NUMPLANETS);
    CHECK_CUDA_ERR(cudaMalloc((void **)&device_planets, sizeof(struct Planet) * NUMPLANETS));
    init();
    CHECK_CUDA_ERR(
        cudaMemcpy(device_planets, host_planets, NUMPLANETS * sizeof(struct Planet), cudaMemcpyHostToDevice));

    int interval = 1;
    double elapsed;
    for(;;)
    {
        clock_gettime(CLOCK_MONOTONIC, &start);
        for(int i = 0; i < interval; i++)
        {
            calcForces<<<grid, block>>>(device_planets);
            CHECK_CUDA_ERR(cudaGetLastError());
            CHECK_CUDA_ERR(cudaDeviceSynchronize());
            updateVelPos<<<grid, block>>>(device_planets);
            CHECK_CUDA_ERR(cudaGetLastError());
            CHECK_CUDA_ERR(cudaDeviceSynchronize());
        }
        clock_gettime(CLOCK_MONOTONIC, &end);

        elapsed = (double)(end.tv_sec - start.tv_sec) + (double)(end.tv_nsec - start.tv_nsec) / 1e9;

        double gens = interval / elapsed;
        interval    = MAX((int)(interval / elapsed), 1);
        printf("%.2e g/s | %.2e OPS\n", gens, gens * NUMPLANETS * NUMPLANETS);
        fflush(stdout);
    }
    free(host_planets);
    CHECK_CUDA_ERR(cudaFree(device_planets));
}
#endif
