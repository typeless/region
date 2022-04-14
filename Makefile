all: bootstrap

bootstrap:
	rm -rf obj
	MYR_RT=/dev/null mbld layer:layer
	$(MAKE) -C rt clean all
	MYR_RT=rt/_region_myrrt.o mbld layer:layer
	MYR_RT=rt/_region_myrrt.o mbld

test bench: bootstrap
	MYR_RT=rt/_region_myrrt.o mbld -j1 $@


clean:
	@$(MAKE) -C rt clean
	rm -rf obj

.PHONY: all clean bootstrap test bench
