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
    int choice;

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) 
    {
        perror("Socket creation failed");
        exit(1);
    }

    memset(&s_addr, 0, sizeof(s_addr));
    s_addr.sin_family = AF_INET;
    s_addr.sin_port = htons(SERVER_PORT);
    inet_pton(AF_INET, SERVER_IP, &s_addr.sin_addr);

    if (connect(sockfd, (struct sockaddr*)&s_addr, sizeof(s_addr)) == -1) 
    {
        perror("Connection failed");
        exit(1);
    }

    while (1) 
    {
        buffer[0] = '\0';
        printf("Input(0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        sprintf(buffer, "%d", choice);
        if(send(sockfd, buffer, strlen(buffer), 0) == -1)
        {
            perror("Send");
            exit(1);
        }

        if(recv(sockfd, buffer, sizeof(buffer), 0) == -1)
        {
            perror("Recv");
            exit(1);
        }

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

        char playagain;
        printf("Play again? (y for yes, n for no): ");
        getchar(); 
        scanf("%c", &playagain);

        send(sockfd, &playagain, sizeof(playagain), 0);

        if (playagain != 'y' && playagain != 'Y') {
            break; 
        }
    }

    close(sockfd);
    return 0;
}