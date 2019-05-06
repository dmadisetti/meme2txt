FROM python:3

ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt -y install toilet
RUN pip install img2txt.py
VOLUME .:/opt/meme2txt

WORKDIR /opt/meme2txt
