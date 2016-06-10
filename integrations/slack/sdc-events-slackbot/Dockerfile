FROM python:alpine
WORKDIR /app
ADD bot.py requirements.txt /app/
ADD docker-entrypoint.sh /
RUN pip install -r requirements.txt
ENV SLACK_TOKEN yourslacktoken
ENV SYSDIG_API_TOKEN yoursysdigapitoken
ENTRYPOINT [ "/docker-entrypoint.sh" ]
