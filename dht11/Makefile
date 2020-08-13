#
# Makefile for sunfounder humiture.c
#
#
VERSION = 0.1

CC	= gcc
CFLAGS	= -O2 -g -gstabs -Wall
LIBS	= -lwiringPi

SRC  = humiture.c
OBJS = humiture.o
TEMPSRC  = dht11_temp.c
TEMPOBJS = dht11_temp.o

HDRS	=

CFLAGS += -I/usr/local/include

SYSTYPE := $(shell uname -s)

CFLAGS += -DLINUX

# Set LOCK to yes for serial port locking support
LOCK = no
LIBS   += -L/usr/lib -lz

ifeq ($(LOCK), yes)
  CFLAGS += -DLOCKDEV
  LIBS   += -llockdev
endif

all:	humiture dht11_temp

help:
	@echo "  SYSTYPE = $(SYSTYPE)"
	@echo "  CFLAGS = $(CFLAGS)"
	@echo "  LIBS   = $(LIBS)"
	@echo ""
	@echo "  Pick one of the following targets:"
	@echo  "\tmake humiture"
	@echo  "\tmake help"
	@echo " "


humiture:	$(SRC) $(HDRS) $(OBJS) Makefile
		$(CC) $(OBJS) -o humiture $(LIBS)

dht11_temp:     $(TEMPSRC) $(HDRS) $(TEMPOBJS) Makefile
		$(CC) $(TEMPOBJS) -o dht11_temp $(LIBS)



# Clean up the object files for distribution
clean:
		rm -f $(OBJS)
		rm -f core *.asc
		rm -f humiture
