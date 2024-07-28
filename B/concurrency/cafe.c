#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <string.h>

#define uint unsigned int

#define BLK "\e[0;30m"
#define RED "\e[0;31m"
#define GRN "\e[0;32m"
#define YEL "\e[0;33m"
#define BLU "\e[0;34m"
#define MAG "\e[0;35m"
#define CYN "\e[0;36m"
#define WHT "\e[0;37m"

#define reset "\e[0m"

uint B, N;
uint global_timer = 0; // Global timer variable
pthread_mutex_t timer_mutex = PTHREAD_MUTEX_INITIALIZER; // Mutex for global timer
uint coffees_prepared = 0;
pthread_mutex_t coffees_prepared_mutex = PTHREAD_MUTEX_INITIALIZER; // Mutex for coffees_prepared
uint coffees_wasted = 0;
pthread_mutex_t coffees_wasted_mutex = PTHREAD_MUTEX_INITIALIZER; // Mutex for coffees_wasted
pthread_t timer_thread; // Timer thread
pthread_mutex_t getbarista_mutex = PTHREAD_MUTEX_INITIALIZER;
uint* waittime;

int *getbarista;

typedef struct
{
    char name[20];
    int time_to_prepare;
} Coffee;

typedef struct
{
    uint index;
    char coffee_ordered[20];
    uint arrival_time;
    uint tolerance;
} Customer;

sem_t *barista_sem;
Coffee *coffees;

void *customer(void *arg)
{
    Customer *customer = (Customer *)arg;

    // Simulate scheduled arrival time
    // printf("Customer %d scheduled to arrive at %d seconds.\n", customer->index, customer->arrival_time);
    while(1)
    {
        pthread_mutex_lock(&timer_mutex);
        if(global_timer >= customer->arrival_time)
        {
            pthread_mutex_unlock(&timer_mutex);
            break;
        }
        pthread_mutex_unlock(&timer_mutex);
    }
    // sleep(customer->arrival_time);

    // get start time
    pthread_mutex_lock(&timer_mutex);
    uint starttime = global_timer;
    pthread_mutex_unlock(&timer_mutex);

    // Simulate customer arriving
    printf("Customer %d arrives at %d second(s)\n", customer->index, customer->arrival_time);

    // Place an order for the specified coffee
    printf(YEL"Customer %d orders a %s.\n"reset, customer->index, customer->coffee_ordered);

    // Wait for any available barista (lock)
    uint assigned_barista = -1;

    // printf("%d waiting for barista\n", customer->index);

    while (1)
    {
        pthread_mutex_lock(&getbarista_mutex);
        if(getbarista[customer->index - 1] == 1)
        {
            pthread_mutex_unlock(&getbarista_mutex);

            for (int i = 0; i < B; i++)
            {
                if (sem_trywait(&barista_sem[i]) == 0)
                {
                    assigned_barista = i + 1;

                    pthread_mutex_lock(&getbarista_mutex);
                    getbarista[customer->index] = 1;
                    getbarista[customer->index - 1] = 0;
                    if(customer->index == N)
                    {
                        getbarista[0] = 1;
                    }
                    pthread_mutex_unlock(&getbarista_mutex);

                    break;
                }
                // else if(customer->index == 2 || customer->index == 3)
                // {
                //     printf("for %d: barista %d unavailable\n", customer->index, i + 1);
                // }
            }
            if (assigned_barista != -1)
            {
                break;
            }
        }
        else
        {
            pthread_mutex_unlock(&getbarista_mutex);
        }
    }


    pthread_mutex_lock(&timer_mutex);
    uint curtime = global_timer;
    pthread_mutex_unlock(&timer_mutex);

    uint tolerance = customer->tolerance;
 
    while(1)
    {
        pthread_mutex_lock(&timer_mutex);
        if(global_timer >= 1 + curtime)
        {
            pthread_mutex_unlock(&timer_mutex);
            break;
        }
        pthread_mutex_unlock(&timer_mutex);
    }

    //waittime update
    pthread_mutex_lock(&timer_mutex);
    waittime[customer->index - 1] = global_timer - starttime;
    pthread_mutex_unlock(&timer_mutex);

    pthread_mutex_lock(&timer_mutex);
    // printf("global time: %d\n", global_timer);
    if(global_timer >= customer->tolerance + customer->arrival_time + 1)
    {
        printf(RED "Customer %d leaves without their order at %d second(s)\n" reset, customer->index, customer->tolerance + customer->arrival_time + 1);
        pthread_mutex_unlock(&timer_mutex);

        pthread_mutex_lock(&coffees_prepared_mutex);
        coffees_prepared++;
        pthread_mutex_unlock(&coffees_prepared_mutex);

        sem_post(&barista_sem[assigned_barista - 1]);

        pthread_exit(NULL);
    }
    // printf("barista %d assgnd to %d at %d\n", assigned_barista, customer->index, global_timer);
    pthread_mutex_unlock(&timer_mutex);

    pthread_mutex_lock(&timer_mutex); 
    printf(CYN "Barista %d begins preparing the order of customer %d at %d second(s)\n" reset, assigned_barista, customer->index, global_timer);
    pthread_mutex_unlock(&timer_mutex);

    //get prep time for type of coffee
    uint time;
    for (int i = 0;; i++)
    {
        if (strcmp(coffees[i].name, customer->coffee_ordered) == 0)
        {
            time = coffees[i].time_to_prepare;
            break;
        }
    }
    
    pthread_mutex_lock(&timer_mutex);
    curtime = global_timer;
    pthread_mutex_unlock(&timer_mutex);

    uint received = 1;

    while(1)
    {
        pthread_mutex_lock(&timer_mutex);
        if(global_timer >= time + curtime)
        {
            pthread_mutex_unlock(&timer_mutex);
            break;
        }
        else if((global_timer > tolerance + customer->arrival_time) && received == 1)
        {
        
            printf(RED "Customer %d  leaves without their order at %d second(s)\n" reset, customer->index, tolerance + customer->arrival_time + 1);
            pthread_mutex_unlock(&timer_mutex);

            pthread_mutex_lock(&coffees_wasted_mutex);
            coffees_wasted++;
            pthread_mutex_unlock(&coffees_wasted_mutex);

            received = 0;
            //break;
        }
        else
        {
            pthread_mutex_unlock(&timer_mutex);
        }
    }

    pthread_mutex_lock(&timer_mutex);
    printf(BLU"Barista %d completes the order of customer %d at %d second(s)\n" reset, assigned_barista, customer->index, global_timer);
    pthread_mutex_unlock(&timer_mutex);

    pthread_mutex_lock(&coffees_prepared_mutex);
    coffees_prepared++;
    // printf("coffees prepared: %d\n", coffees_prepared);
    pthread_mutex_unlock(&coffees_prepared_mutex);
    
    if(received)
    {
        // Customer receives the coffee
        pthread_mutex_lock(&timer_mutex);
        printf(GRN"Customer %d leaves with their order at %d second(s).\n" reset, customer->index, global_timer);
        pthread_mutex_unlock(&timer_mutex);
    }

    // Signal that the barista (lock) is available
    sem_post(&barista_sem[assigned_barista - 1]);

    pthread_exit(NULL);
}


int main()
{
    uint K;

    // Read input
    scanf("%d %d %d", &B, &K, &N);

    // Create an array to track the time to make each coffee type
    coffees = malloc(K * sizeof(Coffee));

    waittime = malloc(sizeof(uint) * N);
    for(int i = 0 ; i < N; i++)
    {
        waittime[i] = 0;
    }

    pthread_mutex_lock(&getbarista_mutex);   
    getbarista = malloc(sizeof(int) * (N + 1));
    getbarista[0] = 1;
    for(int i = 1 ; i < N + 1; i++)
    {
        getbarista[i] = 0;
    }
    pthread_mutex_unlock(&getbarista_mutex);

    barista_sem = (sem_t *)malloc(B * sizeof(sem_t));

    // Initialize semaphores for each barista
    for (int i = 0; i < B; i++)
    {
        sem_init(&barista_sem[i], 0, 1); // Initialize each semaphore with a value of 1
    }

    // Initialize coffees array
    for (int i = 0; i < K; i++)
    {
        scanf("%s %d", coffees[i].name, &coffees[i].time_to_prepare);
    }

    // Create customer threads
    pthread_t customer_threads[N];
    Customer customers[N];


    for (int i = 0; i < N; i++)
    {
        scanf("%d %s %d %d", &customers[i].index, customers[i].coffee_ordered, &customers[i].arrival_time, &customers[i].tolerance);
    }
    for (int i = 0; i < N; i++)
    {
        int ret = pthread_create(&customer_threads[i], NULL, customer, (void *)&customers[i]);
        if (ret != 0)
        {
            printf("Error in creating thread\n");
            exit(1);
        }
    }

    while(1)
    {
        sleep(1);
        pthread_mutex_lock(&timer_mutex);
        global_timer += 1;
        pthread_mutex_unlock(&timer_mutex);

        pthread_mutex_lock(&coffees_prepared_mutex);
        if(coffees_prepared == N)
        {
            pthread_mutex_unlock(&coffees_prepared_mutex);
            break;
        }
        pthread_mutex_unlock(&coffees_prepared_mutex);
    }

    // Join customer threads
    for (int i = 0; i < N; i++)
    {
        pthread_join(customer_threads[i], NULL);
    }

    //average of waittimes
    uint avg = 0;
    for(int i = 0; i < N; i++)
    {
        avg += waittime[i];
    }
    avg = avg / N;
    printf("Average waiting time: %d\n", avg);

    printf("\n%d coffee(s) wasted\n", coffees_wasted);

    // Destroy semaphores
    for (int i = 0; i < B; i++)
    {
        sem_destroy(&barista_sem[i]);
    }

    // Free allocated memory
    free(coffees);

    free(waittime);

    free(getbarista);

    return 0;
}
