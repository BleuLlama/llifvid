# vlc on mac
VLC := /Applications/VLC.app/Contents/MacOS/VLC

MOVIEFILE := HHGTTG_E01.m4v
Z3FILE := hhgttg.z3

all:
	@echo "There is nothing you can hear, see, smell, or feel."
.phony: all


# Video/Server side

server:
	nc -l -p 8888 | perl player.pl | $(VLC) 
.phony: server

serverdbg:
	nc -l -p 8888 | perl player.pl 
.phony: serverdbg

vlc:
	$(VLC) $(MOVIEFILE)
.phony: vlc

# Game/Client side

client:
	/bin/bash -c 'frotz $(Z3FILE) | tee >( nc localhost 8888 )'
.phony: client

game:
	frotz $(Z3FILE) 
.phony: game

################################################################################
# utility

INFODUMP := ztools731_osx/infodump
objtree:
	$(INFODUMP) -t $(Z3FILE) > dat.objtree.txt
.phony: objtree
