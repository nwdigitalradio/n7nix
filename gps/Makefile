#
# Makefile for gp_testport.c
#
#
VERSION = 0.1

CC	= gcc
CFLAGS	= -O2 -g -gstabs -Wall
LIBS	= -lc

SRC  = gp_testport.c
OBJS = gp_testport.o

HDRS	=

CFLAGS += -I/usr/local/include
CFLAGS += -g -O2 -D_LARGEFILE64_SOURCE -pthread -I/usr/include/gmime-2.6 -I/usr/include/glib-2.0 -I/usr/include/glib-2.0
#CFLAGS += -I/usr/lib/x86_64-linux-gnu/glib-2.0/include

SYSTYPE := $(shell uname -s)

CFLAGS += -DLINUX

# Set LOCK to yes for serial port locking support
LOCK = no
LIBS   =

ifeq ($(LOCK), yes)
  CFLAGS += -DLOCKDEV
  LIBS   += -llockdev
endif

all:	gp_testport

help:
	@echo "  SYSTYPE = $(SYSTYPE)"
	@echo "  CFLAGS = $(CFLAGS)"
	@echo "  LIBS   = $(LIBS)"
	@echo ""
	@echo "  Pick one of the following targets:"
	@echo  "\tmake gp_testport
	@echo  "\tmake help"
	@echo " "


gp_testport:	$(SRC) $(HDRS) $(OBJS) Makefile
		$(CC) $(OBJS) -o gp_testport $(LIBS)

# Clean up the object files for distribution
clean:
		@rm -f $(OBJS)
		@rm -f core *.asc
		@rm -f gp_testport
