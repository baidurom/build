# autopatch.mk
#
# patchall: Patch all the modifications.
# upgrade:  Patch upgrade modifications.
#



AUTOPATCH_DIR   := ${PORT_TOOLS}/autopatch
AUTOPATCH_TOOL  := ${AUTOPATCH_DIR}/autopatch.py


#hide :=

.PHONY: patchall upgrade porting

patchall:
	@echo ""
	@echo ">>> auto patch all ..."
	$(hide) $(AUTOPATCH_TOOL) --patchall

upgrade:
	@echo ""
	@echo ">>> upgrade ..."
	$(hide) $(AUTOPATCH_TOOL) --upgrade


PORTING_USAGE="\n  Usage: porting MASTER=XX [COMMIT1=XX] [COMMIT2=XX]              " \
              "\n                                                                       " \
              "\n  - MASTER  the source device you porting from, it is like a master    " \
              "\n                                                                       " \
              "\n  - COMMIT1 the 1st 7 bits SHA1 commit ID on MASTER                    " \
              "\n                                                                       " \
              "\n  - COMMIT2 the 2nd 7 bits SHA1 commit ID on MASTER                    " \
              "\n                                                                       " \
              "\n    e.g. porting MASTER=base                                           " \
              "\n         Porting commits from base interactively                       " \
              "\n                                                                       " \
              "\n    e.g. porting MASTER=base COMMIT1=643a312                           " \
              "\n         Porting commits from COMMIT1 to the latest                    " \
              "\n                                                                       " \
              "\n   Skill: Define MASTER in your Makefile, next time you could          " \
              "\n          use [make porting] directly, it is more effective.           " \
              "\n                                                                       " \

# Porting commits from reference device
porting:
	$(hide) if [ -z $(MASTER) ]; then echo $(PORTING_USAGE); exit 1; fi
	@echo ">>> Porting ..."
	$(hide) $(AUTOPATCH_TOOL) --porting ${MASTER} ${COMMIT1} ${COMMIT2}

