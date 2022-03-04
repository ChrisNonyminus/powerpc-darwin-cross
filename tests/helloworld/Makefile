#make sure the cross compiler's g++ is calling the right executables and not those in /usr/bin
PATH:=/opt/powerpc-darwin-cross/bin
#use /usr/bin since the above line seems to temporarily negate /usr/bin from the path as a side effect??? I think???
SSH=/usr/bin/ssh
MKDIR=/usr/bin/mkdir
SCP=/usr/bin/scp
#set MAC_SSH_SERVER to the ssh server of your mac, following the format user@server, with user being your username on your mac, and server being your mac's local ip
#for example, to properly make this would be to run "make MAC_SSH_SERVER=chris@[insert mac ip here]"
#(Note! PowerPC Macs use an outdated version of ssh that has an outdated key exchange method, but you can set it on your linux pc. See https://unix.stackexchange.com/a/340853)
#your mac must have remote login on and must have xcode (preferrably 2.5) installed
#Also, you will have to enter your mac user's password all the time when running ssh. Sorry, nothing I can do about that.
MAC_TMP_LD_PATH=~/compiler_projects/tests/helloworld

ifndef MAC_SSH_SERVER
$(error "Set MAC_SSH_SERVER to the ssh server of your mac, following the format user@server, with user being your username on your mac, and server being your mac's local ip. For example, to properly make this would be to run "make MAC_SSH_SERVER=chris@X.X.X.X". (Your mac must have remote login on and must have xcode (preferrably 2.5) installed.) Note! PowerPC Macs use an outdated version of ssh that has an outdated key exchange method, but you can set it on your linux pc. See https://unix.stackexchange.com/a/340853. Also, you will have to enter your mac user's password all the time when running ssh. Sorry, nothing I can do about that.")
endif

CC=/opt/powerpc-darwin-cross/bin/g++
CFLAGS=--verbose
#only execute ld from your mac (via ssh)
LD=cc
LFLAGS=-L/usr/lib -L/usr/lib/gcc/powerpc-apple-darwin8/4.0.1 -lstdc++ -lsystem -lgcc -lgcc_s.10.4 -lc -o test
AS=/opt/powerpc-darwin-cross/bin/as -arch ppc
OBJS=main.o

%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@

all: stepone steptwo

stepone: $(OBJS)
	$(CC) $(CFLAGS) -c $< -o test
	$(SSH) $(MAC_SSH_SERVER) "mkdir -p $(MAC_TMP_LD_PATH)"
	$(SCP) $< $(MAC_SSH_SERVER):$(MAC_TMP_LD_PATH)/$<

steptwo:
	$(SSH) $(MAC_SSH_SERVER) "cd $(MAC_TMP_LD_PATH);$(LD) $(OBJS) $(LFLAGS)"
	$(MKDIR) -p build
	$(SCP) $(MAC_SSH_SERVER):$(MAC_TMP_LD_PATH)/test ./build/test.o
#have to add .o as an extension; this is because I need to make sure the git commits ignore this file
clean:
	/usr/bin/rm -f $(OBJS)
	/usr/bin/rm -rf build

run: all
	$(SSH) $(MAC_SSH_SERVER) "cd $(MAC_TMP_LD_PATH);./test"