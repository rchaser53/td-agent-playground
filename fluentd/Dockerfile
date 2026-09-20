FROM ubuntu:22.04

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl \
  && curl -fsSL "https://packages.treasuredata.com/4/ubuntu/jammy/pool/contrib/t/td-agent/td-agent_4.5.2-1_${TARGETARCH}.deb" -o /tmp/td-agent.deb \
  && apt-get install -y /tmp/td-agent.deb \
  && rm -f /tmp/td-agent.deb \
  && rm -rf /var/lib/apt/lists/*

RUN rm -rf \
    /opt/td-agent/lib/ruby/gems/3.1.0/gems/elasticsearch-8.8.0 \
    /opt/td-agent/lib/ruby/gems/3.1.0/gems/elasticsearch-api-8.8.0 \
    /opt/td-agent/lib/ruby/gems/3.1.0/gems/fluent-plugin-elasticsearch-5.3.0 \
    /opt/td-agent/lib/ruby/gems/3.1.0/specifications/elasticsearch-8.8.0.gemspec \
    /opt/td-agent/lib/ruby/gems/3.1.0/specifications/elasticsearch-api-8.8.0.gemspec \
    /opt/td-agent/lib/ruby/gems/3.1.0/specifications/fluent-plugin-elasticsearch-5.3.0.gemspec \
    /opt/td-agent/bin/elastic_ruby_console \
    /opt/td-agent/lib/ruby/gems/3.1.0/bin/elastic_ruby_console \
  && /opt/td-agent/bin/fluent-gem install elasticsearch --version 7.17.9 --no-document \
  && /opt/td-agent/bin/fluent-gem install fluent-plugin-elasticsearch --version 4.3.3 --no-document --ignore-dependencies

COPY fluent.conf /etc/td-agent/td-agent.conf

EXPOSE 24224 24224/udp

USER td-agent

ENTRYPOINT ["/opt/td-agent/bin/fluentd"]
CMD ["-c", "/etc/td-agent/td-agent.conf"]
