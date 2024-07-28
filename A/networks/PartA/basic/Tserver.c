#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>

#define PORT_1 50000
#define PORT_2 50001

int main() {
    int sock_1_fd, sock_2_fd;
    struct sockaddr_in s1_addr, s2_addr, clientA_addr, clientB_addr;
    
    socklen_t clientA_len = sizeof(clientA_addr);
    socklen_t clientB_len = sizeof(clientB_addr);

    char buffer[200];

    if ((sock_1_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) 
    {
        perror("Socket creation failed");
        exit(1);
    }

    memset(&s1_addr, 0, sizeof(s1_addr));
    s1_addr.sin_family = AF_INET;
    s1_addr.sin_port = htons(PORT_1);
    s1_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock_1_fd, (struct sockaddr*)&s1_addr, sizeof(s1_addr)) == -1) 
    {
        perror("Bind failed");
        exit(1);
    }

    if (listen(sock_1_fd, 1) == -1) 
    {
        perror("Listen failed");
        exit(1);
    }

    if ((sock_2_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) 
    {
        perror("Socket creation failed");
        exit(1);
    }

    memset(&s2_addr, 0, sizeof(s2_addr));
    s2_addr.sin_family = AF_INET;
    s2_addr.sin_port = htons(PORT_2);
    s2_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock_2_fd, (struct sockaddr*)&s2_addr, sizeof(s2_addr)) == -1) 
    {
        perror("Bind failed");
        exit(1);
    }

    if (listen(sock_2_fd, 1) == -1) 
    {
        perror("Listen failed");
        exit(1);
    }

    int A_sfd, B_sfd;
    
    while (1) 
    {
        A_sfd = accept(sock_1_fd, (struct sockaddr*)&clientA_addr, &clientA_len);

        if (A_sfd == -1) 
        {
            perror("Accept failed");
            continue;
        }

        if(recv(A_sfd, buffer, sizeof(buffer), 0) == -1)
        {
            perror("Recv");
            exit(1);
        }

        int decisionA = atoi(buffer);

        B_sfd = accept(sock_2_fd, (struct sockaddr*)&clientB_addr, &clientB_len);

        if (B_sfd == -1) 
        {
            perror("Accept failed");
            continue;
        }

        if(recv(B_sfd, buffer, sizeof(buffer), 0) == -1)
        {
            perror("Recv");
            exit(1);
        }

        int decisionB = atoi(buffer);

        int result;

        if (decisionA == decisionB) 
        {
            result = 0; // Draw
            printf("Draw\n");
        } 
        else if ((decisionA == (decisionB + 2)) || (decisionA == (decisionB - 1))) 
        {
            result = -1; // A wins
            printf("A wins\n");
        } 
        else 
        {
            result = 1; // B wins
            printf("B wins\n");
        }

        sprintf(buffer, "%d", result);
        send(A_sfd, buffer, strlen(buffer), 0);
        send(B_sfd, buffer, strlen(buffer), 0);

        // printf("gonna accept\n");
        // A_sfd = accept(sock_1_fd, (struct sockaddr*)&clientA_addr, &clientA_len);
        // printf("sfd: %d\n", A_sfd);

        // if (A_sfd == -1) 
        // {
        //     perror("Accept failed");
        //     continue;
        // }
        // printf("accepted\n");

        // recv(A_sfd, buffer, sizeof(buffer), 0);             
        // int Aplayagain = atoi(buffer);

        char choice_A, choice_B;

        recv(A_sfd, &choice_A, sizeof(choice_A), 0);
        recv(B_sfd, &choice_B, sizeof(choice_B), 0);


        //printf("Aplayagain: %d\n", Aplayagain);

        // B_sfd = accept(sock_2_fd, (struct sockaddr*)&clientB_addr, &clientB_len);

        // if (B_sfd == -1) 
        // {
        //     perror("Accept failed");
        //     continue;
        // }

        // recv(B_sfd, buffer, sizeof(buffer), 0);
        // int Bplayagain = atoi(buffer);

        //printf("Bplayagain: %d\n", Bplayagain);

        if(choice_A == 'n' || choice_A == 'N' || choice_B == 'n' || choice_B == 'N')
        {
            printf("Done\n");
            break;
        }

        close(A_sfd);
        close(B_sfd);

    }

    close(sock_1_fd);
    close(sock_2_fd);

    return 0;
}
