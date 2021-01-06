ARG jruby_version=9.2

FROM jruby:${jruby_version} AS build
MAINTAINER Wade Rossmann <wrossmann@gmail.com>

ARG norikra_version
RUN gem install norikra --version ${norikra_version}

FROM jruby:${jruby_version} AS deploy
COPY --from=build /usr/local/bundle/ /usr/local/bundle/

EXPOSE 26571 26578

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

CMD ["/usr/local/bundle/bin/norikra", "start"]

