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
int look_speed(void);

typedef struct {char *name; int flag; } speed_spec;

char devicename[256];
int speed;
char config_file[256] = {0};
int no_log = 0;

FILE* l_fp;
int log_save = 0;
char log_file[1024] = {0};

typedef enum {
	ALL,
	PORT,
	SPEED,
} FLAG;

int flag = 0;

int get_key(int is_echo)
{
	int ch;
	struct termios old;
	struct termios current; /* 현재 설정된 terminal i/o 값을 backup함 */
	tcgetattr(0, &old); /* 현재의 설정된 terminal i/o에 일부 속성만 변경하기 위해 복사함 */
	current = old; /* buffer i/o를 중단함 */
	current.c_lflag &= ~ICANON;
	if (is_echo) { // 입력값을 화면에 표시할 경우
		current.c_lflag |= ECHO;
	}
	else { // 입력값을 화면에 표시하지 않을 경우
		current.c_lflag &= ~ECHO;
	} /* 변경된 설정값으로 설정합니다.*/
	tcsetattr(0, TCSANOW, &current);
	ch = getchar();
	tcsetattr(0, TCSANOW, &old);
	return ch;
}


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
	fprintf(stderr, "Current port : %s\r\n", devicename);
	fprintf(stderr, "Current speed : %d\r\n", look_speed());
}

void set_speed(int n)
{
	switch(n) {
	case 1:
		speed = B115200;
		break;
	case 2:
		speed = B57600;
		break;
	case 3:
		speed = B38400;
		break;
	case 4:
		speed = B19200;
		break;
	case 5:
		speed = B9600;
		break;
	case 6:
		speed = B4800;
		break;
	case 7:
		speed = B2400;
		break;
	case 8:
		speed = B1200;
		break;
	}
}

void scale_speed(void)
{
	switch(speed) {
	case 115200:
		speed = B115200;
		break;
	case 57600:
		speed = B57600;
		break;
	case 38400:
		speed = B38400;
		break;
	case 19200:
		speed = B19200;
		break;
	case 9600:
		speed = B9600;
		break;
	case 4800:
		speed = B4800;
		break;
	case 2400:
		speed = B2400;
		break;
	case 1200:
		speed = B1200;
		break;
	}
}

int look_speed(void)
{
	int ret = 115200;
	switch(speed) {
	case B115200:
		ret = 115200;
		break;
	case B57600:
		ret = 57600;
		break;
	case B38400:
		ret = 38400;
		break;
	case B19200:
		ret = 19200;
		break;
	case B9600:
		ret = 9600;
		break;
	case B4800:
		ret = 4800;
		break;
	case B2400:
		ret = 2400;
		break;
	case B1200:
		ret = 1200;
		break;
	}
	return ret;
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
					scale_speed();
				}
			}
			fclose(fp);
			return 1;
		}
	}
	return 0;
}

void set_log_path(void)
{
	char cmd[2048] = {0};
	fprintf(stderr, "Input log path : ");
	scanf("%s", log_file);
	if(access(log_file, F_OK) == 0) {
		fprintf(stderr, "Log file : '%s' Already exist!\r\n", log_file);
		fprintf(stderr, "Do you want overwrite? 'y' or 'n'\r\n");
		char c = 0;
		c = get_key(0);
		while(!(c == 'n' || c == 'y'))
		{
			// fprintf(stderr, "Do you want overwrite? 'y' or 'n'\r\n");
			c = get_key(0);
		}
		if(c == 'n') {
			fprintf(stderr, "Log don't save!!\r\n");
			return;
		}
	}
	
	l_fp = fopen(log_file, "w");
	log_save = 1;
	if(!l_fp) {
		fprintf(stderr, "No Directory!!! : '%s'\r\n", log_file);
		log_save = 0;
		memset(log_file, 0, sizeof(log_file));
		return;
	}
	fprintf(stderr, "Log save start : '%s'\r\n", log_file);
}

int set_default_config(int flag)
{
	get_config();
	int s = 0;
	char w[512] = {0};
	fprintf(stderr, "Default Setting!\n\r");
	if(flag == ALL || flag == PORT) {
		fprintf(stderr, "Port = ? (current = %s)\n\r", devicename);
		fprintf(stderr, "Chagne => /dev/tty");
		scanf("%s", &devicename[8]);
	}
	
	if(flag == ALL || flag == SPEED) {
		fprintf(stderr, "\r\nSelect speed\n\r");
		print_speed();
		scanf("%d", &s);
		set_speed(s);
		fprintf(stderr, "Setting!!!! Speed = %d\n\r\n\r", look_speed());
	}
	
	FILE* fp = fopen(config_file, "w");
	if(fp) {
		snprintf(w, sizeof(w), "port=%s\nspeed=%d", devicename, look_speed());
		fputs(w, fp);
		fclose(fp);
		fprintf(stderr, "\r\n********Default config********\r\n%s\n\r******************************\n\r", w);
		get_config();
		return 1;
	}
	return 0;
}

int start(void)
{
	if(!strlen(devicename) || !speed) {
		fprintf(stderr, "Config file strange...\r\n");
		set_default_config(ALL);
	}
	char cmd[512] = {0};
	snprintf(cmd, sizeof(cmd), "fuser %s", devicename);
	if(!WEXITSTATUS(system(cmd))) {
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
	
	if(!no_log) {
		fprintf(stderr, "port = %s\n\r", devicename);
		fprintf(stderr, "speed = %d\n\r", look_speed());
		fprintf(stderr, "Ctrl+a : menu\n\r");
	}
	no_log = 0;

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
			get_config();
			set_default_config(ALL);
		}
		else if(strcmp(argv[1], "ls-config") == 0) {
			get_config();
			fprintf(stderr, "port : %s\r\nspeed : %d\r\n", devicename, look_speed());
		}
		else {
			fprintf(stderr, "argv : help, ls-config, config\r\n");
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
			if(!set_default_config(ALL)) {
				exit(1);
			}
		}
	}
	

	if(argc > 2) {	
		speed_spec *s;
		for(s = speeds; s->name; s++) {
			if(strcmp(s->name, argv[2]) == 0) {
				speed = atoi(s->name);
				scale_speed();
				break;
			}
		}
		strncpy(devicename, argv[1], sizeof(devicename));
	}
	
	int ret = 0;
	while(1)
	{
		ret = start();
		if(ret <= 0)
			break;
		if(ret == 3) {
			int cur_speed = speed;
			char dev[256] = {0};
			strncpy(dev, devicename, sizeof(dev));
			set_default_config(flag);
			strncpy(devicename, dev, sizeof(devicename));
			speed = cur_speed;
		}
		else if(ret == 4) {
			get_config();		
		}
		else if(ret == 5) {
			set_log_path();
		}
	}
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
				fprintf(stderr, "Press button!\n\r");
				fprintf(stderr, "Quit : 'q', Speed : 's', Port : 'p', Restart : 'r', Change default : 'd', Log save : 'l'\r\n");
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
					fprintf(stderr, "speed = %d\n\r", look_speed());
					return 1;
				}
				else if(c == 'p' || c == 'P') {
					fprintf(stderr, "port => /dev/ttyUSB[Number] number ?\n\r");
					read(from, &c, 1);
					if(c >= 0x30 && c <= 0x39) {
						c -= 0x30;
						snprintf(devicename, sizeof(devicename), "/dev/ttyUSB%d", c);
					}
					return 1;
				}
				else if(c == 'd' || c == 'D') {
					no_log = 1;
					fprintf(stderr, "\r\nSelect config!\n\r");
					fprintf(stderr, "All : 'a', Port : 't', Speed : 's'\n\r");
					read(from, &c, 1);
					switch(c) {
					case 'a':
						flag = ALL;
						break;
					case 't':
						flag = PORT;
						break;
					case 's':
						flag = SPEED;
						break;
					default:
						return 1;
					}
					return 3;
				}
				else if(c == 'r' || c == 'R') {
					fprintf(stderr, "\r\nRestart!!!!!\n\r");
					return 4;
				}
				else if(c == 'l' || c == 'L') {
					no_log = 1;
					if(log_save) {
						fprintf(stderr, "\r\nDo you want to stop log?? 'y' or 'n'\r\n");
						fprintf(stderr, "Log is saving : '%s'\r\n", log_file);
						read(from, &c, 1);
						if(c == 'y' || c == 'Y' || c == 13) {
							fprintf(stderr, "Saving log stopeed!! : '%s'\r\n", log_file);
							log_save = 0;
							memset(log_file, 0, sizeof(log_file));
							fclose(l_fp);
						}
						return 1;
					}
					return 5;
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
		while(1)
		{
			if(log_save) {
				fwrite(&c, 1, 1, l_fp);
			}
			if(write(to, &c, 1) != -1) {
				break;
			}
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
