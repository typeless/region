OBJ = _myrrt.o
ASMSRC = start.s common.s abort.s

all: _region_myrrt.o

_region_myrrt.o: region_main.o _myrrt.o
	ld -r -o _region_myrrt.o _myrrt.o region_main.o -L../obj/layer -llayer -L../obj -lregion -L/home/mural/src/myrlang.org/mc/out/lib/myr -lsys

include ./config.mk

_myrrt.o: _myrrt.s
	as -o $@ $^

_myrrt.s: $(ASMSRC)
	cat $(ASMSRC) > $@

region_main.o : region_main.myr
	6m -o $(@) -I ../obj/layer -I ../obj region_main.myr

%.s: %-$(SYS).s
	cp $< $@

install: all
	mkdir -p  $(abspath $(DESTDIR)/$(INST_ROOT)/lib/myr)
	install _myrrt.o $(abspath $(DESTDIR)/$(INST_ROOT)/lib/myr)

uninstall:
	rm -f $(abspath $(DESTDIR)/$(INST_ROOT)/lib/myr/_myrrt.o)

clean:
	rm -f  _region_myrrt.o _myrrt.o region_main.o region_main.use  _myrrt.s start.s abort.s
