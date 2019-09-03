docker run --rm --name envoy -p 8001:8001 -p 50052:50052 -v `pwd`/envoy/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:latest
