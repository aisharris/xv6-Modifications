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

    if ((sock_1_fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)  //UDP
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

    if ((sock_2_fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)  //UDP
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

    while (1) 
    {

        recvfrom(sock_1_fd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientA_addr, &clientA_len);
        int decisionA = atoi(buffer);
        
        recvfrom(sock_2_fd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientB_addr, &clientB_len);
        int decisionB = atoi(buffer);


        int result;

        if(decisionA == decisionB) 
        { 
            result = 0;
            printf("Draw\n");
        } 
        else if ((decisionA == (decisionB + 2)) || (decisionA == (decisionB - 1))) 
        {
            result = -1; // A wins
            printf("B wins\n");
        } 
        else 
        {
            result = 1; // B wins
            printf("A wins\n");
        }

        sprintf(buffer, "%d", result);
        sendto(sock_1_fd, buffer, strlen(buffer), 0, (struct sockaddr*)&clientA_addr, clientA_len);
        sendto(sock_2_fd, buffer, strlen(buffer), 0, (struct sockaddr*)&clientB_addr, clientB_len);

        recvfrom(sock_1_fd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientA_addr, &clientA_len);
        int Aplayagain = atoi(buffer);

        recvfrom(sock_2_fd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientB_addr, &clientB_len);
        int Bplayagain = atoi(buffer);

        if(!(Aplayagain && Bplayagain))
        {
            break;
        }
    }

    close(sock_1_fd);
    close(sock_2_fd);

    return 0;
}
