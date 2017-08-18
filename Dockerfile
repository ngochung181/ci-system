FROM gitlab/gitlab-ce:9.4.3-ce.0 
MAINTAINER R&D <rnd@runsystem.net>


# Add config file
ADD /root /
RUN chmod +x /shell/*.sh
# update & upgrade
RUN apt-get update && apt-get upgrade -y
RUN apt-get -y install supervisor curl unzip 
RUN echo 'root:runsystem' | chpasswd
    #Config start ssh daemon using supervisord

RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
# Install common tools
#-------------------------------------------------------------------------------
RUN echo "mysql-server mysql-server/root_password password runsystem" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password runsystem" | debconf-set-selections
############ install mysql

RUN apt-get -y install mysql-server-5.7 && \
        mkdir -p /var/lib/mysql && \
        mkdir -p /var/run/mysqld && \
        mkdir -p /var/log/mysql && \
        chown -R mysql:mysql /var/lib/mysql && \
        chown -R mysql:mysql /var/run/mysqld && \
        chown -R mysql:mysql /var/log/mysql

# UTF-8 and bind-address
RUN sed -i -e "$ a [client]\n\n[mysql]\n\n[mysqld]"  /etc/mysql/my.cnf && \
        sed -i -e "s/\(\[client\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
        sed -i -e "s/\(\[mysql\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
        sed -i -e "s/\(\[mysqld\]\)/\1\ninit_connect='SET NAMES utf8'\ncharacter-set-server = utf8\ncollation-server=utf8_unicode_ci\nbind-address = 0.0.0.0/g" /etc/mysql/my.cnf
#Install Jenkins ==========================
#RUN apt-get update 
RUN apt-get install -y default-jdk
RUN wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | apt-key add -
#RUN sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
RUN sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
RUN apt-get update && apt-get install -y zip jenkins && rm -rf /var/lib/apt/lists/*
ENV JENKINS_HOME /var/lib/jenkins
VOLUME /var/lib/jenkins
####Install Sonarqube###########
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
ENV PATH ${PATH}:${JAVA_HOME}/bin
### Installation and configuration of SonarQube
ENV SONAR_VERSION 6.4
RUN wget https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip
RUN unzip sonarqube-$SONAR_VERSION.zip -d /opt
RUN     rm sonarqube-$SONAR_VERSION.zip
RUN mv /opt/sonarqube-$SONAR_VERSION /opt/sonarqube
RUN wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.0.3.778-linux.zip
RUN unzip sonar-scanner-cli-3.0.3.778-linux.zip -d /opt/sonarqube
RUN     rm sonar-scanner-cli-3.0.3.778-linux.zip
RUN mv /opt/sonarqube/sonar-scanner-3.0.3.778-linux /opt/sonarqube/sonar-scanner
#### install mavebn
ARG MAVEN_VERSION=3.3.9
ENV MAVEN_URL http://ftp.halifax.rwth-aachen.de
ENV MAVEN_PKG ${MAVEN_URL}/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
ENV MAVEN_HOME /opt/apache-maven-${MAVEN_VERSION}
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${MAVEN_HOME}/bin

WORKDIR /opt

RUN curl ${MAVEN_PKG} | tar xz
#RUN rm /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz



#RUN wget http://apache.mirrors.lucidnetworks.net/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
#	mkdir -p /usr/local/apache-maven && \
#	mv apache-maven-3.3.9-bin.tar.gz /usr/local/apache-maven && \
#	cd /usr/local/apache-maven && \
#	tar -xzvf apache-maven-3.3.9-bin.tar.gz
#ENV MAVEN_HOME=/usr/local/apache-maven/apache-maven-3.3.9
#ENV MAVEN_OPTS="-Xms256m -Xmx512m"
#ADD dbsonar.sh /opt/dbsonar.sh
#RUN chmod +x /opt/dbsonar.sh

#RUN sed -e 's/^#sonar.jdbc.url=jdbc:mysql/sonar.jdbc.url=jdbc:mysql/' -e 's/^#sonar.jdbc.username/sonar.jdbc.username/' -e 's/^#sonar.jdbc.password/sonar.jdbc.password/' /opt/sonarqube/conf/sonar.properties > /opt/sonarqube/conf/sonar.properties.new
#RUN mv /opt/sonarqube/conf/sonar.properties /opt/sonarqube/conf/sonar.properties.bak
#RUN mv /opt/sonarqube/conf/sonar.properties.new /opt/sonarqube/conf/sonar.properties
VOLUME ["/opt/sonarqube"]

# Label
LABEL  "service_ssh"="22"
LABEL  "service_jenkins"="8080"
LABEL  "service_sonarqube"="9000"
LABEL  "service_mysql"="3306"
LABEL  "service_gitlab"="80"
EXPOSE 8080 9000 8000 9002

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]

