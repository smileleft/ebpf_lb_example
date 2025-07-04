# ebpf_lb_example
load balancer sample repo wiht eBPF 

```
docker buildx create --name mybuilder --bootstrap --use
docker run --rm -it -v ./lb-from-scratch:/lb-from-scratch --privileged -h lb --name lb --env TERM=xterm-color smileleft/jammy-ebpf-lb:0.1
```
