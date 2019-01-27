#
# STAGE 1
# - Install and build necessary dependencies
#
FROM node:10.15.0-alpine as build
RUN echo -e "http://ftp.halifax.rwth-aachen.de/alpine/v3.8/main/\nhttp://ftp.halifax.rwth-aachen.de/alpine/v3.8/community/" > /etc/apk/repositories && \
    apk add --no-cache python build-base openjdk8
COPY admin/src /app/admin/src
COPY admin/package.json /app/admin/package.json
COPY admin/package-lock.json /app/admin/package-lock.json
COPY admin/webpack.config.js /app/admin/webpack.config.js
COPY gradle /app/gradle
COPY public /app/public
COPY src /app/src
COPY tests /app/tests
COPY build.gradle.kts /app/build.gradle.kts
COPY env.test /app/env.test
COPY gradlew /app/gradlew
COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json
COPY settings.gradle /app/settings.gradle
WORKDIR /app
RUN npm ci && npm ci --prefix admin && npm cache clean --force
RUN npm run build
RUN mkdir data && npm test

#
# STAGE 2
# - Keep Only runtime libraries: no build tool is allowed in production.
#
FROM node:10.15.0-alpine
LABEL maintainer="Jan-Lukas Else (https://about.jlelse.de)"

ENV NODE_ENV=production

# Copy just needed directories
COPY --from=build /app/admin/dist /app/admin/dist
COPY --from=build /app/app /app/app
COPY --from=build /app/public /app/public
COPY --from=build /app/package.json /app/package.json
COPY --from=build /app/package-lock.json /app/package-lock.json
COPY --from=build /app/node_modules /app/node_modules

WORKDIR /app
RUN mkdir data && npm prune
VOLUME ["/app/data"]

EXPOSE 8080
CMD ["npm", "start"]
