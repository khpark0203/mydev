CC = gcc
TARGET = com
SRC = com.c
PREFIX = /usr/bin

all:
	rm -f $(TARGET)
	$(CC) $(SRC) -o $(TARGET)
install:
	sudo cp $(TARGET) $(PREFIX)
clean:
	rm -f $(TARGET)