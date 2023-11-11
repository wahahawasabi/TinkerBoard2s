FROM ubuntu:jammy

COPY entrypoint.sh ./

RUN apt-get update && apt-get upgrade && \
    apt-get install debootstrap qemu-user-static

ENTRYPOINT ["./entrypoint.sh"]
