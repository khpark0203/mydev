#include <stdio.h>
#include <unistd.h>
#include <utime.h>

void main(int args, char* argv[])
{
    int i = 0;
    for (i = 1; i < args; i++) {
        char* file = argv[i];
        if (access(file, F_OK) != 0) {
            FILE* fp = fopen(file, "w");
            fclose(fp);
        }
    }
}