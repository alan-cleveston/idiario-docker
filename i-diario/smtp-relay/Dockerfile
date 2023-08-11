FROM alpine:3.17

EXPOSE 25
ENTRYPOINT ["/entrypoint.sh"]
COPY entrypoint.sh /

RUN apk --no-cache add ca-certificates libintl postfix tzdata mailx &&\
    chmod +x /entrypoint.sh
