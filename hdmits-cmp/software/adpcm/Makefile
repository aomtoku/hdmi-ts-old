#Makefile for FrameSend send.c

CC = gcc
CFLAGS = -O -Wall -g
OBJS = main.o
INCLUDES = -I/usr/local/include
TARGET = recvframe


scaleout:	$(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS)

encode: $(encode)
	$(CC) $(CFLAGS) $(INCLUDES) -o encoder encoder.c

decode: $(decode)
	$(CC) $(CFLAGS) $(INCLUDES) -o decoder decoder.c

clean:
	-rm -f $(TARGET) $(OBJS) 

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) -c $<
