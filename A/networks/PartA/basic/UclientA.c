#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 50000

int main() {
    int sockfd;
    struct sockaddr_in s_addr;
    char buffer[200];
    int decision;


    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }


    memset(&s_addr, 0, sizeof(s_addr));
    s_addr.sin_family = AF_INET;
    s_addr.sin_port = htons(SERVER_PORT);
    inet_pton(AF_INET, SERVER_IP, &s_addr.sin_addr);

    while (1) {
        printf("Input(0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &decision);
        if(decision < 0 || decision > 2)
        {
            printf("Invalid input\n");
            continue;
        }


        sprintf(buffer, "%d", decision);
        sendto(sockfd, buffer, strlen(buffer), 0, (struct sockaddr*)&s_addr, sizeof(s_addr));


        recvfrom(sockfd, buffer, sizeof(buffer), 0, NULL, NULL);
        int result = atoi(buffer);
        if (result == 0) 
        {
            printf("Draw\n");
        } 
        else if (result == 1) 
        {
            printf("Win\n");
        } 
        else 
        {
            printf("Lost\n");
        }

        // Next prompt
        char choice;
        printf("Play again? (y for yes, n for no): ");
        getchar(); 
        scanf("%c", &choice);
        
        int c;
        if(choice == 'y' || choice == 'Y')
        {
            c = 1;
            printf("y\n");
        }
        else
        {
            c = 0;
        }

        sprintf(buffer, "%d", c);
        printf("buffer: %s\n", buffer);
        sendto(sockfd, buffer, strlen(buffer), 0, (struct sockaddr*)&s_addr, sizeof(s_addr));

        if (choice != 'y' && choice != 'Y') //no
        {
            break; 
        }

    }

    close(sockfd);
    return 0;
}
