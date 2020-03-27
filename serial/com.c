/*
 * Building: cc -o com com.c
 * Usage   : ./com /dev/device [speed]
 * Example : ./com /dev/ttyS0 [115200]
 * Keys    : Ctrl-A - exit, Ctrl-X - display control lines status
 * Darcs   : darcs get http://tinyserial.sf.net/
 * Homepage: http://tinyserial.sourceforge.net
 * Version : 2009-03-05
 *
 * Ivan Tikhonov, http://www.brokestream.com, kefeer@brokestream.com
 * Patches by Jim Kou, Henry Nestler, Jon Miner, Alan Horstmann
 *
 */


/* Copyright (C) 2007 Ivan Tikhonov

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Ivan Tikhonov, kefeer@brokestream.com

*/

#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <errno.h>

#define CONFIG_FILE ".comrc"

int transfer_byte(int from, int to, int is_control);

typedef struct {char *name; int flag; } speed_spec;

char devicename[256];
int speed;
char config_file[256] = {0};

void print_speed(void)
{
	fprintf(stderr, "*****Speed*****\n\r");
	fprintf(stderr, "1 : 115200\n\r");
	fprintf(stderr, "2 : 57600\n\r");
	fprintf(stderr, "3 : 38400\n\r");
	fprintf(stderr, "4 : 19200\n\r");
	fprintf(stderr, "5 : 9600\n\r");
	fprintf(stderr, "6 : 4800\n\r");
	fprintf(stderr, "7 : 2400\n\r");
	fprintf(stderr, "8 : 1200\n\r");
	fprintf(stderr, "***************\n\r");
}
void print_status(int fd) {
	int status;
	unsigned int arg;
	status = ioctl(fd, TIOCMGET, &arg);
	fprintf(stderr, "[STATUS]: ");
	if(arg & TIOCM_RTS) fprintf(stderr, "RTS ");
	if(arg & TIOCM_CTS) fprintf(stderr, "CTS ");
	if(arg & TIOCM_DSR) fprintf(stderr, "DSR ");
	if(arg & TIOCM_CAR) fprintf(stderr, "DCD ");
	if(arg & TIOCM_DTR) fprintf(stderr, "DTR ");
	if(arg & TIOCM_RNG) fprintf(stderr, "RI ");
	fprintf(stderr, "\r\n");
}

void set_speed(int n)
{
	switch(n) {
	case 1:
		speed = 115200;
		break;
	case 2:
		speed = 57600;
		break;
	case 3:
		speed = 38400;
		break;
	case 4:
		speed = 19200;
		break;
	case 5:
		speed = 9600;
		break;
	case 6:
		speed = 4800;
		break;
	case 7:
		speed = 2400;
		break;
	case 8:
		speed = 1200;
		break;
	}
}

int get_config(void)
{
	if(access(config_file, F_OK) == 0) {
		FILE* fp = fopen(config_file, "r");
		char buf[256] = {0};
		if(fp) {
			while(!feof(fp))
			{
				fgets(buf, sizeof(buf), fp);
				if(strchr(buf, '\n'))
					*strchr(buf, '\n') = '\0';
				
				if(strstr(buf, "port=")) {
					strncpy(devicename, strchr(buf, '=') + 1, sizeof(devicename));
				}
				else if(strstr(buf, "speed=")) {
					speed = atoi(strchr(buf, '=') + 1);
				}
			}
			fclose(fp);
			return 1;
		}
	}
	return 0;
}

int set_default_config(void)
{
	FILE* fp = fopen(config_file, "w");
	if(fp) {
		int n = 0;
		int s = 0;
		char w[100] = {0};
		fprintf(stderr, "Default Setting!\n\r");
		fprintf(stderr, "/dev/ttyUSB[Number], Number = ?\n\r");
		scanf("%d", &n);
		fprintf(stderr, "Setting!!!! /dev/ttyUSB%d\n\r\n\r", n);
		fprintf(stderr, "Select speed\n\r");
		print_speed();
		scanf("%d", &s);
		set_speed(s);
		fprintf(stderr, "Setting!!!! Speed = %d\n\r\n\r", speed);
		snprintf(w, sizeof(w), "port=/dev/ttyUSB%d\nspeed=%d", n, speed);
		fputs(w, fp);
		fclose(fp);
		get_config();
		return 1;
	}
	return 0;
}

int start(void)
{
	char cmd[512] = {0};
	snprintf(cmd, sizeof(cmd), "fuser %s", devicename);
	if(system(cmd)) {
		
	}
	else {
		fprintf(stderr, "%s is already running\n\r", devicename);
		return -3;
	}
	int comfd;
	struct termios oldtio, newtio;       //place for old and new port settings for serial port
	struct termios oldkey, newkey;       //place tor old and new port settings for keyboard teletype
	int need_exit = 0;
	
	comfd = open(devicename, O_RDWR | O_NOCTTY | O_NONBLOCK);
	if (comfd < 0) {
		perror(devicename);
		exit(-1);
	}
	
	fprintf(stderr, "port = %s\n\r", devicename);
	fprintf(stderr, "speed = %d\n\r", speed);
	fprintf(stderr, "Ctrl+a : menu\n\r");

	tcgetattr(STDIN_FILENO,&oldkey);
	newkey.c_cflag = B115200 | CRTSCTS | CS8 | CLOCAL | CREAD;
	newkey.c_iflag = IGNPAR;
	newkey.c_oflag = 0;
	newkey.c_lflag = 0;
	newkey.c_cc[VMIN]=1;
	newkey.c_cc[VTIME]=0;
	tcflush(STDIN_FILENO, TCIFLUSH);
	tcsetattr(STDIN_FILENO,TCSANOW,&newkey);


	tcgetattr(comfd,&oldtio); // save current port settings 
	newtio.c_cflag = speed | CS8 | CLOCAL | CREAD;
	newtio.c_iflag = IGNPAR;
	newtio.c_oflag = 0;
	newtio.c_lflag = 0;
	newtio.c_cc[VMIN]=1;
	newtio.c_cc[VTIME]=0;
	tcflush(comfd, TCIFLUSH);
	tcsetattr(comfd,TCSANOW,&newtio);

	print_status(comfd);

	while(!need_exit)
	{
		fd_set fds;
		int ret;
		
		FD_ZERO(&fds);
		FD_SET(STDIN_FILENO, &fds);
		FD_SET(comfd, &fds);


		ret = select(comfd+1, &fds, NULL, NULL, NULL);
		if(ret == -1) {
			perror("select");
		}
		else if (ret > 0) {
			if(FD_ISSET(STDIN_FILENO, &fds)) {
				need_exit = transfer_byte(STDIN_FILENO, comfd, 1);
			}
			if(FD_ISSET(comfd, &fds)) {
				need_exit = transfer_byte(comfd, STDIN_FILENO, 0);
			}
		}
	}

	tcsetattr(comfd,TCSANOW,&oldtio);
	tcsetattr(STDIN_FILENO,TCSANOW,&oldkey);
	close(comfd);
	return need_exit;
}

int main(int argc, char *argv[])
{
	int comfd;
	struct termios oldtio, newtio;       //place for old and new port settings for serial port
	struct termios oldkey, newkey;       //place tor old and new port settings for keyboard teletype
	int need_exit = 0;
	speed_spec speeds[] =
	{
		{"1200", B1200},
		{"2400", B2400},
		{"4800", B4800},
		{"9600", B9600},
		{"19200", B19200},
		{"38400", B38400},
		{"57600", B57600},
		{"115200", B115200},
		{NULL, 0}
	};
	
	snprintf(config_file, sizeof(config_file), "%s/%s", getenv("HOME"), CONFIG_FILE);
	// fprintf(stderr, "If want chnage config file -> '%s'\n\r", config_file);
	// fprintf(stderr, "or example: '%s /dev/ttyUSB0 115200'\n", argv[0]);

	if(argc == 2) {
		if(strcmp(argv[1], "help") == 0) {
			fprintf(stderr, "example: 'com /dev/ttyUSB0 115200'\r\n");
		}
		else if(strcmp(argv[1], "config") == 0) {
			set_default_config();
		}
		else {
			fprintf(stderr, "argv : help, config\r\n");
		}
		return 0;
	}

	if(argc < 2) {
		if(access(config_file, F_OK) == 0) {
			if(!get_config()) {
				exit(1);
			}
		}
		else {
			if(!set_default_config()) {
				exit(1);
			}
		}
	}
	

	if(argc > 2) {	
		speed_spec *s;
		for(s = speeds; s->name; s++) {
			if(strcmp(s->name, argv[2]) == 0) {
				speed = atoi(s->name);
				break;
			}
		}
		strncpy(devicename, argv[1], sizeof(devicename));
	}
	
	while(start() > 0);
	return 0;
}


int transfer_byte(int from, int to, int is_control) {
	char c;
	int ret;
	do {
		ret = read(from, &c, 1);
	} while (ret < 0 && errno == EINTR);
	if(ret == 1) {
		if(is_control) {
			if(c == '\x01') { // C-a
				fprintf(stderr, "Quit = press 'q' // ");
				fprintf(stderr, "Speed = press 's' // ");
				fprintf(stderr, "Port = press 't' // ");
				fprintf(stderr, "Restart = press 'r' // ");
				fprintf(stderr, "Default = press 'd'\n\r");
				read(from, &c, 1);
				if(c == 'q' || c == 'Q') {
					return -1;
				}
				else if(c == 's' || c == 'S') {
					print_speed();
					read(from, &c, 1);
					if(c >= 0x31 && c <= 0x38)
						c -= 0x30;
					set_speed(c);
					fprintf(stderr, "speed = %d\n\r", speed);
					return 1;
				}
				else if(c == 't' || c == 'T') {
					print_speed();
					read(from, &c, 1);
					if(c >= 0x30 && c <= 0x39) {
						c -= 0x30;
						snprintf(devicename, sizeof(devicename), "/dev/ttyUSB%d", c);
					}
					fprintf(stderr, "port = %s\n\r", devicename);
					return 1;
				}
				else if(c == 'd' || c == 'D') {
					FILE* fp = fopen(config_file, "w");
					if(fp) {
						char n = 0;
						char s = 0;
						char w[100] = {0};
						fprintf(stderr, "Default Setting!\n\r");
						fprintf(stderr, "/dev/ttyUSB[Number], Number = ?\n\r");
						while(1)
						{
							read(from, &n, 1);
							if(n >= 0x30 && n <= 0x39)
								break;
						}
						n -= 0x30;
						fprintf(stderr, "Setting!!!! /dev/ttyUSB%d\n\r\n\r", n);
						fprintf(stderr, "Select speed\n\r");
						print_speed();
						while(1)
						{
							read(from, &s, 1);
							if(s >= 0x30 && s <= 0x39)
								break;
						}
						s -= 0x30;
						set_speed(s);
						fprintf(stderr, "Setting!!!! Speed = %d\n\r\n\r", speed);
						snprintf(w, sizeof(w), "port=/dev/ttyUSB%d\nspeed=%d", n, speed);
						fputs(w, fp);
						fclose(fp);
						get_config();
					}
					return 0;
				}
				else if(c == 'r' || c == 'R') {
					fprintf(stderr, "\r\nRestart!!!!!\n\r");
					return 1;
				}
				else {
					c = '\n';
				}	
			}
			else if(c == '\x18') { // C-x
				print_status(to);
				return 0;
			}
		}
		while(write(to, &c, 1) == -1)
		{
			if(errno != EAGAIN && errno != EINTR) {
				perror("write failed");
				break;
			}
		}
	}
	else {
		fprintf(stderr, "\nnothing to read. probably port disconnected.\n");
		return -2;
	}
	return 0;
}