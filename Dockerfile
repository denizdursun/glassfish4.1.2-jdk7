FROM        java:7-jdk

LABEL maintainer "Deniz Dursun denizdursun@gmail.com"


ENV         JAVA_HOME         /usr/lib/jvm/java-7-openjdk-amd64
ENV         GLASSFISH_HOME    /usr/local/glassfish4
ENV         PATH              $PATH:$JAVA_HOME/bin:$GLASSFISH_HOME/bin

ARG         DB_NAME
ARG         DB_PASSWORD
ARG         DB_PORT
ARG         DB_USER
ARG         DB_SERVER
ARG         XMX
ARG         XMS
ARG         MAX_PERM
ARG         ADMIN_PASS

RUN         apt-get update && \
            apt-get install -y curl wget expect pwgen unzip zip inotify-tools && \
            rm -rf /var/lib/apt/lists/*

RUN         curl -L -o /tmp/glassfish-4.1.2.zip http://download.java.net/glassfish/4.1.2/release/glassfish-4.1.2.zip && \
            unzip /tmp/glassfish-4.1.2.zip -d /usr/local && \
            rm -f /tmp/glassfish-4.1.2.zip
			

RUN 		mkdir -p /usr/local/bin
RUN 		mkdir -p /usr/local/deploy

#RUN         curl http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.16/mysql-connector-java-5.1.16.jar -o /usr/local/glassfish4/glassfish/lib/mysql-connector-java-5.1.16.jar
RUN         curl https://jdbc.postgresql.org/download/postgresql-42.2.14.jre7.jar -o /usr/local/glassfish4/glassfish/lib/postgresql-42.2.14.jre7.jar


COPY        appRepo /home/appService/appRepo
COPY        appRepo2 /home/appService/appRepo

ADD 		run.sh /usr/local/bin/run.sh
ADD 		change_admin_pass.expect /usr/local/bin/change_admin_pass.expect
ADD 		asadmin_cmd.expect /usr/local/bin/asadmin_cmd.expect

RUN 		chmod +x /usr/local/bin/run.sh && \
			chmod +x /usr/local/bin/*.expect

RUN			/usr/local/bin/run.sh
			
ADD 		app.war /usr/local/glassfish4/glassfish/domains/domain1/autodeploy/app.war

EXPOSE      8080 4848 8181

WORKDIR     /usr/local/glassfish4/bin

# verbose causes the process to remain in the foreground so that docker can track it
CMD asadmin start-domain --verbose
HEALTHCHECK --start-period=120s --interval=5s --timeout=2s --retries=10 CMD curl --silent --fail http://localhost:8080/app/ || exit 1