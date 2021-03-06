###### Standard Makefile template (replace this part with copyrights
###### or other nonsense).
######
###### I got sick of always having to copy and paste makefiles and
###### compiler flags between projects, and I'm slowly but surely
###### learning more about GNU Make.  
######
###### Matthew Peddie <peddie@alum.mit.edu>

# TODO: 
#
#   - options to build shared and static libraries
#   - dependency tracking

###### This section should be all you need to configure a basic
###### project; obviously for more complex projects, you'll need to
###### edit the bottom section as well.

# What's the executable called?
PROJ = leitshow

# What C files must we compile?
SRC ?= leitshow.c util.c

HDR ?= config.h arraymath.h

# What directories must we include?
INCLUDES ?= 

# With what libraries should we link?
LIBS ?= -lpulse-simple -lpulse -lfftw3f -lm 

###### Shouldn't have to configure this section ######

C_SRC = $(filter %.c,$(SRC))
CXX_SRC = $(filter %.cc,$(SRC))

ASMNAME ?= lst

# Default setting for object files is just .c -> .o
C_ASM ?= $(C_SRC:%.c=%.$(ASMNAME))
C_OBJ ?= $(C_SRC:%.c=%.o)
C_DEPS ?= $(C_SRC:%.c=%.d)

CXX_ASM ?= $(CXX_SRC:%.c=%.$(ASMNAME))
CXX_OBJ ?= $(CXX_SRC:%.c=%.o)
CXX_DEPS ?= $(CXX_SRC:%.c=%.d)

ASM ?= $(C_ASM) $(CXX_ASM)
OBJ ?= $(C_OBJ) $(CXX_OBJ)
DEPS ?= $(C_DEPS) $(CXX_DEPS)

# Here we remove all paths from the given object and source file
# names; you can echo these in commands and get slightly tidier output.
SRC_SHORT = $(notdir $(SRC))
ASM_SHORT = $(notdir $(ASM))
OBJ_SHORT = $(notdir $(OBJ))

# GCC by default (easy to override from outside the makefile)
CC ?= gcc 

# Quiet commands unless overridden
Q ?= @

# Generate sweet mixed assembly/C listing files
ASMFLAGS ?= -fverbose-asm -Wa,-L,-alhsn=

# Second-level optimizations that don't increase binary size (O2 or
# above required for -D_FORTIFY_SOURCE=2 below); optimize for this
# machine architecture, including sse4.1; try using the vectorizer to
# speed up array code (gcc 4.5+, I think?); build object files for use
# by the link-time optimizer (gcc 4.5+, I think, but only really works
# in 4.6)
OPTFLAGS ?= -Os -march=native -ftree-vectorize -flto

# Mega-warnings by default.  For many explanations, see
# http://stackoverflow.com/questions/3375697/useful-gcc-flags-for-c

# We prefer C99 with GNU extensions
WARNFLAGS ?= -Wall -Wextra -std=gnu99 -pedantic-errors \
             -Wshadow -Wswitch-default -Wswitch-enum -Wundef \
             -Wuninitialized -Wpointer-arith -Wstrict-prototypes \
             -Wmissing-prototypes -Wcast-align -Wformat=2 \
             -Wimplicit-function-declaration -Wredundant-decls \
             -Wformat-security -Werror

# Include debug symbols; trap on signed integer overflows; install
# mudflaps for runtime checks on arrays (including malloced ones)
DBGFLAGS ?= -g # -ftrapv -fmudflap 

# Build position-independent executables; fortify with array checks;
# protect stack
SECFLAGS ?= -fPIE -D_FORTIFY_SOURCE=2 -fstack-protector

# Run the link-time optimizer
LDOPTFLAGS ?= -flto
LDWARNFLAGS ?=
# Use the mudflaps library for runtime checks
LDDBGFLAGS ?= -g # -lmudflap 
# Link as a position-independent executable; mark ELF sections
# read-only where applicable; resolve all dynamic symbols at initial
# load of program and (in combination with relro) mark PLT read-only
LDSECFLAGS ?= -pie -Wl,-z,relro -Wl,-z,now

CFLAGS = $(WARNFLAGS) $(OPTFLAGS) $(SECFLAGS) $(INCLUDES) $(DBGFLAGS)
LDFLAGS = $(LDWARNFLAGS) $(LDOPTFLAGS) $(LDSECFLAGS) $(LIBS) $(LDDBGFLAGS) 

ifdef DEBUG
CFLAGS += -DDEBUG=$(DEBUG)
endif  # DEBUG

.PHONY: clean

# Build the project
$(PROJ): $(OBJ)  
	@echo LD $@
	$(Q)$(CC) $+ $(LDFLAGS) -o $@

# Generate object files; output assembly listings alongside.  
%.o : %.c
	@echo CC $(notdir $<)
	$(Q)$(CC) $(CFLAGS) $(ASMFLAGS)$(<:%.c=%.$(ASMNAME)) -c $< -o $@

$(OBJ) : $(HDR)

# Remove executable, object and assembly files
clean:
	@echo CLEAN $(PROJ) $(OBJ_SHORT:%.o=%)
	$(Q)rm -f $(PROJ) $(OBJ) $(ASM)

.PHONY: check-syntax-c check-syntax-cc check-syntax 

check-syntax: check-syntax-c check-syntax-cc

check-syntax-c:
ifneq (,$(findstring .c,$(C_SRC)))
	@echo SYNTAX_CHECK $(CHK_SOURCES)
	$(Q)$(CC) -fsyntax-only $(WARNFLAGS) $(INCLUDES) $(CHK_SOURCES)
	$(Q)cpplint $(CHK_SOURCES)
endif

check-syntax-cc:
ifneq (,$(findstring .cc,$(CXX_SRC)))
	@echo SYNTAX_CHECK $(CXX_SRC)
	$(Q)$(CXX) -fsyntax-only $(WARNFLAGS) $(INCLUDES) $(CXX_SRC)
endif
