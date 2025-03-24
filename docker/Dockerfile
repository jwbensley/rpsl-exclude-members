FROM ubuntu:24.04

RUN apt-get update

RUN apt-get install --no-install-recommends -y \
ca-certificates inotify-tools python3 python3-pip ruby

RUN pip install --break-system-packages xml2rfc

RUN gem install kramdown-rfc2629
