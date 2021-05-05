PWD=$(shell pwd)

# Start local NGINX Load Balancer docker container for control plane.
start-lb:
	@docker run \
		-d -v ${PWD}/load-balancer/nginx.conf:/etc/nginx/nginx.conf \
		-p 8000:6443 \
		--name k3s-load-balancer \
		--restart=unless-stopped \
		nginx:1.20

# Shut down the NGINX Load Balancer docker container.
stop-lb:
	@docker stop k3s-load-balancer && \
		docker rm k3s-load-balancer