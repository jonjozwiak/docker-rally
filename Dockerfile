FROM rhel7:latest
MAINTAINER Jon Jozwiak <jjozwiak@redhat.com>

# If local repos: COPY <source on host> <dest in container>
#COPY rhelosp7.repo /etc/yum.repos.d/rhelosp7.repo

# install prereqs
RUN yum clean all && yum -y update && yum -y install https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && yum -y install which bc git ansible


# create rally user
RUN useradd -u 65500 -m rally && \
  ln -s /opt/rally/doc /home/rally/rally-docs

# install rally. the COPY command below frequently invalidates
# subsequent cache
COPY . /tmp/rally
WORKDIR /tmp/rally
RUN ./install_rally.sh --system --verbose --yes \
    --db-name /home/rally/.rally.sqlite && \
  mkdir /opt/rally/ && \
  # TODO(andreykurilin): build docs to rst before move, since we have several
  # extensions.
  mv certification/ samples/ doc/ /opt/rally/ && \
  chmod -R u=rwX,go=rX /opt/rally /etc/rally && \
  rm -rf /tmp/* 

RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/motd' \
            >> /etc/bash.bashrc; echo -e 'Welcome to Rally Docker container!\n\
    Rally certification tasks, samples and docs are located at /opt/rally/\n\
    Rally at readthedocs - http://rally.readthedocs.org\n\
    How to contribute - http://rally.readthedocs.org/en/latest/contribute.html\n\
    If you have any questions, you can reach the Rally team by:\n\
      * e-mail - openstack-dev@lists.openstack.org with tag [Rally] in subject\n\
      * irc - "#openstack-rally" channel at freenode.net' > /etc/motd

VOLUME ["/home/rally"]

WORKDIR /home/rally/
USER rally
ENV HOME /home/rally/
CMD ["bash", "--login"]

RUN rally-manage db recreate

# TODO(stpierre): Find a way to use `rally` as the
# entrypoint. Currently this is complicated by the need to run
# rally-manage to create the database.
