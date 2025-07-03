TARGET = xdp_lb
# TARGET = packetdrop
# TARGET = xdp_liz

# Get target architecture for BPF programs
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    ARCH_HDR_DEFINE = -D__TARGET_ARCH_x86
else ifeq ($(ARCH),aarch64)
    ARCH_HDR_DEFINE = -D__TARGET_ARCH_arm64
else
    $(error Unsupported architecture $(ARCH) for BPF compilation. Please add __TARGET_ARCH_xxx manually to BPF_CFLAGS.)
endif

ARCH_INCLUDE_PATH := /usr/include/$(shell dpkg-architecture -qDEB_HOST_MULTIARCH)

# For xdp_liz, make and also make user. The others don't have userspace programs

USER_TARGET = ${TARGET:=_user}
BPF_TARGET = ${TARGET:=_kern}
BPF_C = ${BPF_TARGET:=.c}
BPF_OBJ = ${BPF_C:.c=.o}

xdp: $(BPF_OBJ)
	bpftool net detach xdpgeneric dev enp1s0
	rm -f /sys/fs/bpf/$(TARGET)
	bpftool prog load $(BPF_OBJ) /sys/fs/bpf/$(TARGET)
	bpftool net attach xdpgeneric pinned /sys/fs/bpf/$(TARGET) dev enp1s0 

user: $(USER_TARGET)

$(USER_TARGET): %: %.c  
	gcc -Wall $(CFLAGS) -Ilibbpf/src -Ilibbpf/src/include/uapi -Llibbpf/src -o $@  \
	 $< -l:libbpf.a -lelf -lz

$(BPF_OBJ): %.o: %.c
	clang -S \
	    -target bpf \
	    -D __BPF_TRACING__ \
	    -I/usr/include/bpf \
	    -I$(ARCH_INCLUDE_PATH) \
	    -Wall \
	    -Wno-unused-value \
	    -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -Werror \
	    -O2 -emit-llvm -c -o ${@:.o=.ll} $<
	llc -march=bpf -filetype=obj -o $@ ${@:.o=.ll}

clean:
	bpftool net detach xdpgeneric dev enp1s0
	rm -f /sys/fs/bpf/$(TARGET)
	rm $(BPF_OBJ)
	rm ${BPF_OBJ:.o=.ll}




