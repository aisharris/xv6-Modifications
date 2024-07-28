#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>

#define MAX_CUSTOMERS 5
#define MAX_MACHINES 2

typedef struct {
    char name[100];
    int time_to_prepare;
} IceCream;

typedef struct {
    char name[100];
    int put_time;
} Topping;

typedef struct {
    IceCream *ice_cream;
    Topping **toppings;
    int numToppings;
} Order;

typedef struct {
    int index;
    int start_time;
    int end_time;
    pthread_mutex_t lock;
} Machine;

typedef struct {
    int index;
    int arrival_time;
    Order *orders;
    int numOrders;
} Customer;

Machine machines[MAX_MACHINES];
IceCream ice_creams[] = {
    {"Vanilla", 3},
    {"Chocolate", 4},
    {"Strawberry", 5},
    // Add more ice creams as needed
};

Topping toppings[] = {
    {"Caramel", 2},
    {"Chocolate Chips", 3},
    {"Sprinkles", 1},
    // Add more toppings as needed
};

void* makeIceCream(void* order) {
    Order* myOrder = (Order*)order;

    // Simulate time to prepare the ice cream

    // Simulate adding toppings

    return NULL;
}

void* serveCustomer(void* customer) {
    Customer* myCustomer = (Customer*)customer;

    for (int i = 0; i < myCustomer->numOrders; i++) {
        Order* myOrder = &(myCustomer->orders[i]);

        // Find an available machine. machine must work until ice cream can be completed
        //if current time is past the end times of all machines, print 
        //customer left due to unavailability of machines
        
        //check if ingredients there, if not leave machine and print cust left due to ingredient deficiency

        if (machineIndex != -1) {
            printf("Customer %d: Started making Order %d\n", myCustomer->index, i + 1);

            // Assign the machine to the order
            

            // Create a thread to make the ice cream
            pthread_t iceCreamThread;
            pthread_create(&iceCreamThread, NULL, makeIceCream, myOrder);
            pthread_join(iceCreamThread, NULL);

            printf("Customer %d: Finished making Order %d\n", myCustomer->index, i + 1);

            // Release the machine
            pthread_mutex_unlock(&(machines[machineIndex].lock));

            // Simulate serving time
            sleep(1);
        }
    }

    return NULL;
}

int main() {
    srand(time(NULL));

    // Initialize machines
    for (int i = 0; i < MAX_MACHINES; i++) {
        machines[i].index = i;
        machines[i].start_time = i * 3;
        machines[i].end_time = (i + 1) * 3;
        pthread_mutex_init(&(machines[i].lock), NULL);
    }

    // Create customer threads
    pthread_t customer_threads[MAX_CUSTOMERS];
    Customer customers[MAX_CUSTOMERS];

    for (int i = 0; i < MAX_CUSTOMERS; i++) {
        customers[i].index = i + 1;
        customers[i].arrival_time = i * 2;
        customers[i].numOrders = rand() % 3 + 1;  // Random number of orders between 1 and 3

        customers[i].orders = malloc(customers[i].numOrders * sizeof(Order));

        pthread_create(&customer_threads[i], NULL, serveCustomer, &(customers[i]));
    }

    // Wait for all customer threads to finish
    for (int i = 0; i < MAX_CUSTOMERS; i++) {
        pthread_join(customer_threads[i], NULL);
        free(customers[i].orders);
    }

    // Cleanup machines
    for (int i = 0; i < MAX_MACHINES; i++) {
        pthread_mutex_destroy(&(machines[i].lock));
    }

    return 0;
}
