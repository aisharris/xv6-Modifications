#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc , char * argv[]){
    printf("Old %d New %d\n", setpriority(atoi(argv[1]), atoi(argv[2])), atoi(argv[2]));
    return 0;
}