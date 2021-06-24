ARG PYTHON_VERSION=3.7.9
FROM python:${PYTHON_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ENV TZ=Asia/Tokyo

ARG WORKDIR=/recommend_sparkFM
ARG SPARK_VERSION=3.0.0
ARG HADOOP_VERSION=2.7
ARG SPARK_VERSION_STRING=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME=/spark
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH
ENV PATH=$SPARK_HOME/bin:$SPARK_HOME/python:$PATH
ENV JAVA_HOME /usr/lib/jvm/adoptopenjdk-8-hotspot-jre-amd64/

# Or your actual UID, GID on Linux if not the default 1000
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# change default shell
SHELL ["/bin/bash", "-c"]
RUN chsh -s /bin/bash

# Increase timeout for apt-get to 300 seconds
RUN /bin/echo -e "\n\
    Acquire::http::Timeout \"300\";\n\
    Acquire::ftp::Timeout \"300\";" >> /etc/apt/apt.conf.d/99timeout

# Configure apt and install packages
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get update \
    && apt-get -y install wget git sudo vim tzdata make software-properties-common \
    && wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add - \
    && add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ \
    && apt-get update \
    && apt-get -y install adoptopenjdk-8-hotspot-jre \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN pip install -U pip

# Spark setting
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_VERSION_STRING}.tgz \
    && tar -xvzf ${SPARK_VERSION_STRING}.tgz \
    && mv ${SPARK_VERSION_STRING} ${SPARK_HOME} \
    && rm ${SPARK_VERSION_STRING}.tgz


# pyright install
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && npm install --global pyright

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add sudo support for non-root user
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# terminal setting
RUN wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O /home/$USERNAME/.git-completion.bash \
    && wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O /home/$USERNAME/.git-prompt.sh \
    && chmod a+x /home/$USERNAME/.git-completion.bash \
    && chmod a+x /home/$USERNAME/.git-prompt.sh \
    && echo -e "\n\
    source ~/.git-completion.bash\n\
    source ~/.git-prompt.sh\n\
    export PS1='\\[\\e]0;\\u@\\h: \\w\\a\\]\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\[\\033[1;30m\\]\$(__git_ps1)\\[\\033[0m\\] \\$ '\n\
    " >>  /home/$USERNAME/.bashrc

ENV PATH=/home/$USERNAME/.local/bin:$PATH

WORKDIR ${WORKDIR}

CMD ["/bin/bash"]
