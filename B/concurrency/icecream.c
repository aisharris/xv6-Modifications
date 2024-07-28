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

uint N, K, F, T;
uint global_timer = 0; // Global timer variable
pthread_mutex_t timer_mutex = PTHREAD_MUTEX_INITIALIZER; // Mutex for global timer

pthread_mutex_t getmachine_mutex = PTHREAD_MUTEX_INITIALIZER;
int* getmachine;
sem_t *machines_sem;


int last_end_time;

typedef struct
{
    char name[20];
    int time_to_prepare;
} IceCream;

typedef struct 
{
    sem_t lock;
    char name[20];
    uint quantity;
} Topping;

typedef struct 
{
    IceCream* ice_cream;
    uint numToppings;
    Topping** toppings;
} Order;

typedef struct
{
    uint index;
    uint arrival_time;
    uint order_count;
    Order** orders;
} Customer;

typedef struct
{
    uint index;
    uint start_time;
    uint end_time;
} Machine;


Machine* machines;
IceCream* ice_creams;
Topping* toppings;
Customer* customers;

void* makeIceCream(void* order) {
    Order* myOrder = (Order*)order;

    pthread_mutex_lock(&timer_mutex);
    int curtime = global_timer;
    pthread_mutex_unlock(&timer_mutex);

    int time = 0;

    for(int i = 0 ; i < F; i++)
    {
        if(strcmp(ice_creams[i].name, myOrder->ice_cream->name) == 0)
        {
            time = ice_creams[i].time_to_prepare;
        }   
    }
    // Simulate time to prepare the ice cream
    while(1)
    {
        pthread_mutex_lock(&timer_mutex);
        if(global_timer >= curtime + time)
        {
            pthread_mutex_unlock(&timer_mutex);
            break;
        }
        pthread_mutex_unlock(&timer_mutex);
    }

    pthread_exit(NULL);
}

void* serveCustomer(void* customer) {
    Customer* myCustomer = (Customer*)customer;

    while(1)
    {
        pthread_mutex_lock(&timer_mutex);
        if(global_timer >= myCustomer->arrival_time)
        {
            pthread_mutex_unlock(&timer_mutex);
            break;
        }
        pthread_mutex_unlock(&timer_mutex);
    }

    pthread_mutex_lock(&timer_mutex);
    printf("Customer %d enters at %d second(s)\n", myCustomer->index, global_timer);
    pthread_mutex_unlock(&timer_mutex);

    printf("Customer %d orders %d ice creams\n", myCustomer->index, myCustomer->order_count);
    
    for(int g = 0; g < myCustomer->order_count; g++)
    {
        printf("Ice cream %d: %s", g + 1, myCustomer->orders[g]->ice_cream->name);
        for(int h = 0; h < myCustomer->orders[g]->numToppings; h++)
        {
            printf(" %s", myCustomer->orders[g]->toppings[h]->name);
        }
        printf("\n");
    }

    for (int i = 0; i < myCustomer->order_count; i++) 
    {
        Order* myOrder = myCustomer->orders[i];

        //update ingredient availabilities
        for(int g = 0 ; g < myOrder->numToppings; g++) //for each topping
        {
            for(int h = 0; h < T; h++) //check which topping
            {
                if(strcmp(myOrder->toppings[g]->name, toppings[h].name) == 0)
                {
                    if(sem_wait(&toppings[h].lock) == 0)
                    {
                        if(toppings[h].quantity == -1)
                        {
                            continue;
                        }
                        if(toppings[h].quantity == 0)
                        {
                            printf("Customer %d was not serviced due to unavailability of toppings\n", myCustomer->index);
                            sem_post(&toppings[h].lock);
                            pthread_exit(NULL);
                        }
                        else
                        {
                            toppings[h].quantity -= 1;
                            sem_post(&toppings[h].lock);
                        }
                    }
                    break;
                }
            }
        }

        // Find an available machine. machine must work until ice cream can be completed

        int total_make_time = 0;

        total_make_time += myOrder->ice_cream->time_to_prepare;

        int assigned_machine = -1;

        for(int f = 0; f < N; f++)
        {
            if(sem_trywait(&machines_sem[f]) == 0) //machine not in use
            {
                //check if its currently working
                pthread_mutex_lock(&timer_mutex);
                if((global_timer >= machines[f].start_time) && (global_timer < machines[f].end_time - total_make_time))
                {
                    assigned_machine = f + 1;
                }
                else if(global_timer >= last_end_time)
                {
                    printf("Customer %d was not serviced due to unavailability of machines\n", myCustomer->index);
                    pthread_mutex_unlock(&timer_mutex);

                    pthread_exit(NULL);
                }
                else
                {
                    sem_post(&machines_sem[f]);
                }
                pthread_mutex_unlock(&timer_mutex);
            }
            if(assigned_machine != -1)
            {
                break;
            }
        }



        if (assigned_machine != -1) 
        {
            pthread_mutex_lock(&timer_mutex);
            printf("Machine %d starts preparing ice cream %d of customer %d at %d second(s)", assigned_machine, i + 1, myCustomer->index, global_timer);
            pthread_mutex_unlock(&timer_mutex);

            // Create a thread to make the ice cream
            pthread_t iceCreamThread;

            pthread_create(&iceCreamThread, NULL, makeIceCream, myOrder);

            pthread_join(iceCreamThread, NULL);

            pthread_mutex_lock(&timer_mutex);
            printf("Machine %d completes preparing ice cream %d of customer %d at %d seconds(s)\n", assigned_machine, i+1, myCustomer->index, global_timer);
            printf("Customer %d has collected their order(s) and left at %d second(s)", myCustomer->index, global_timer);
            pthread_mutex_unlock(&timer_mutex);

            // Release the machine
            sem_post(&machines_sem[assigned_machine - 1]);

        }
    }

    return NULL;
}

int main()
{

    scanf("%d %d %d %d", &N, &K, &F, &T);

    machines = malloc(sizeof(Machine) * N);
    machines_sem = (sem_t *)malloc(N * sizeof(sem_t));

    for (int i = 0; i < N; i++)
    {
        machines[i].index = i;
        scanf("%d %d", &machines[i].start_time, &machines[i].end_time);
    }

    for (int i = 0; i < N; i++)
    {
        sem_init(&machines_sem[i], 0, 1); // Initialize each semaphore with a value of 1
    }

    ice_creams = malloc(sizeof(IceCream) * F);

    for(int i = 0; i < F; i++)
    {
        scanf("%s %d", ice_creams[i].name, &ice_creams[i].time_to_prepare);
    }

    toppings = malloc(sizeof(Topping) * T);

    for(int i = 0; i < T; i++)
    {
        scanf("%s %d", toppings[i].name, &toppings[i].quantity);
    }


    // Create customer threads
    pthread_t customer_threads[K];
    customers = malloc(sizeof(Customer) * K);

    int cust_count = 0;
    int total_orders = 0;

    //take input
    for(int i = 0 ; i < K; i++)
    {
        int orders;
        scanf("%d %d %d", &customers[i].index, &customers[i].arrival_time, &orders);

        customers[i].order_count = orders;

        total_orders += orders;

        Order** order = (Order**)malloc(sizeof(Order *) * orders);

        int flag = 0;

        for(int j = 0; j < orders; j++)
        {
            // printf("\n j = %d\n", j);
            scanf("\n");
            order[j] = (Order*)malloc(sizeof(Order));

            char buffer[100];

            if(fgets(buffer, sizeof(buffer), stdin) != NULL)
            {
                if ( buffer[strcspn(buffer, "\n\n")] = '\0')
                {
                    flag = 1;
                    break;
                }
                cust_count++;
                // printf("buf: %s\n", buffer);
                // Remove newline character if present
                buffer[strcspn(buffer, "\n")] = '\0';

                // Tokenize the line to get ice cream and toppings
                char *token = strtok(buffer, " ");
                if (token == NULL) 
                {
                    // Empty line, handle accordingly
                    continue;
                }

                // Allocate memory for ice cream and copy its value
                
                for(int h = 0; h < F; h++)
                {
                    if(strcmp(ice_creams[h].name, token) == 0)
                    {
                        order[j]->ice_cream = &ice_creams[h];
                        // printf("GOT ICEKEEM%d: %s\n", j + 1, order[j]->ice_cream->name);
                        break;
                    }
                }

                // Allocate memory for toppings
                char **thesetoppings = NULL;
                int numToppings = 0;

                // Continue tokenizing to get toppings
                while ((token = strtok(NULL, " ")) != NULL) 
                {
                    // Allocate memory for each topping and copy its value
                    thesetoppings = realloc(thesetoppings, (numToppings + 1) * sizeof(char *));
                    thesetoppings[numToppings] = strdup(token);
                    numToppings++;
                }

                // Allocate memory for the final array of toppings
                Topping **finalToppings = malloc((numToppings) * sizeof(Topping *));
                for (int k = 0; k < numToppings; k++) 
                {
                    // Find the topping in the array of toppings
                    for(int h = 0; h < T; h++)
                    {
                        if(strcmp(thesetoppings[k], toppings[h].name) == 0)
                        {
                            finalToppings[k] = &toppings[h];
                            break;
                        }
                    }
                }

                order[j]->toppings = finalToppings;
                order[j]->numToppings = numToppings;
            }
            if(flag == 1)
            {
                break;
            }
            // else
            // {
            //     printf("\n    ITS NULL    \n");
            // }
        }

        customers[i].orders = order;
        
    }

    for (int i = 0; i < cust_count; i++)
    {
        int ret = pthread_create(&customer_threads[i], NULL, serveCustomer, (void *)&customers[i]);
        if (ret != 0)
        {
            printf("Error in creating thread\n");
            exit(1);
        }
    }

    //find last end time of machine
    last_end_time = 0;
    for(int i = 0; i < N; i++)
    {
        if(machines[i].end_time > last_end_time)
        {
            last_end_time = machines[i].end_time;
        }
    }

    while(global_timer < last_end_time)
    {
        for(int i  = 0; i < N; i++)
        {
            pthread_mutex_lock(&timer_mutex);
            if(global_timer == machines[i].start_time)
            {
                printf("Machine %d has started working at %d second(s)\n", machines[i].index + 1, global_timer);
            }
            if(global_timer == machines[i].end_time)
            {
                printf("Machine %d has stopped working at %d second(s)\n", machines[i].index + 1, global_timer);
            }
            pthread_mutex_unlock(&timer_mutex);
        }
        sleep(1);
        pthread_mutex_lock(&timer_mutex);
        global_timer += 1;
        pthread_mutex_unlock(&timer_mutex);

    }

    //Join customer threads
    for (int i = 0; i < N; i++)
    {
        pthread_join(customer_threads[i], NULL);
    }


    // Destroy semaphores
    for (int i = 0; i < N; i++)
    {
        sem_destroy(&machines_sem[i]);
    }

    return 0;
}
