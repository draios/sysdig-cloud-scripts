FROM python:alpine
MAINTAINER Sysdig <support@sysdig.com>

WORKDIR /app
ADD requirements.txt /app/
RUN pip install -r requirements.txt

ADD bot.py /app
ENTRYPOINT [ "python", "bot.py" ]
