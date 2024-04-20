FROM node:lts-alpine
WORKDIR /usr/src/app
COPY . .
RUN npm install
ENV GRPC_TRACE=all
ENV GRPC_VERBOSITY=DEBUG
EXPOSE 4000
CMD /bin/sh