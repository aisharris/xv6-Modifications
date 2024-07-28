# REPORT

## Part A
Initialize structs for server and client addresses, create buffer array for data transmission.
Use socket syscall to get a socket file descriptor (ipv4 and tcp/udp specified). Bind to ports to link file descriptors to specific ports.

For TCP, use listen to listen for incoming connections

In a while loop:
Tcp: accept from both ports to establish file descriptors for clients
receive decisions from A and B clients, getting client info 

compute results and send the result to the clients throught their respective ports.
Receive request to play again and break while loop if no by either client.

# Report - Part B

Was unable to implement due to lack of time, but the implementation can be done as follows

## DataSequencing in TCP
Data is transmitted in chunks in TCP. Each chunk needs to be referenced by sequence numbers in order to ensure proper reception without error..

Chunk structure can be created, with sequence number and a data array. Data to be sent must be divided into chunks of fixed size. Server must receieve chunks and store in the right order, then message can be displayed in order.


### Retransmissions in TCP
When ack is not received from server within timeout, unacknowledged data is retransmitted. The timer can be incremented for successive transmissions. The last unreceived package may be sent continuously until an acknowledgement is received from the server. Server knows number of chunks and waits until all chunks are received. once received it can be printed in order.

## Flow control
For controlling flow, a window size is specified in each tcp segment. this allows receiver to specify how much data it can receive at a time.
