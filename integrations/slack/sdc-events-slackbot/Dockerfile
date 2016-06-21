FROM python:alpine
MAINTAINER Sysdig <support@sysdig.com>

WORKDIR /app
ADD requirements.txt /app/
RUN pip install -r requirements.txt

ADD docker-entrypoint.sh /
ADD bot.py /app
ENV SLACK_TOKEN yourslacktoken
ENV SYSDIG_API_TOKEN yoursysdigapitoken
ENTRYPOINT [ "/docker-entrypoint.sh" ]
