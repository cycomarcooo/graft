#
# Cookbook Name:: graft
# Recipe:: mailcatcher
#

user_home = node["rvm"]["user"]["home"]

# Dependency for mailcatcher
package "libsqlite3-dev"

# Install init.d script for managing the mailcatcher service
file "/etc/init.d/mailcatcher" do
  owner "root"
  group "root"
  mode "0755"
  content <<-SHELL
    #!/bin/bash

    PID_FILE=/var/run/mailcatcher.pid
    NAME=mailcatcher
    PROG="#{user_home}/.rvm/wrappers/default/mailcatcher"
    USER=root
    GROUP=root

    start() {
      echo "mailcatcher start/running"
      if start-stop-daemon --stop --quiet --pidfile $PID_FILE --signal 0; then
        exit
      fi
      start-stop-daemon \\
        --start \\
        --pidfile $PID_FILE \\
        --make-pidfile \\
        --background \\
        --exec $PROG \\
        --user $USER \\
        --group $GROUP \\
        --chuid $USER \\
        -- \\
        --foreground \\
        --ip=0.0.0.0
      return $?
    }

    stop() {
      echo "mailcatcher stop/waiting"
      start-stop-daemon \\
        --stop \\
        --oknodo \\
        --pidfile $PID_FILE > /dev/null 2>&1
      return $?
    }

    restart() {
      stop
      sleep 1
      start
    }

    case "$1" in
      start)
        start
        ;;
      stop)
        stop
        ;;
      restart)
        restart
        ;;
      *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
    esac
  SHELL
  action :create
end

# Install mailcatcher
script "mailcatcher" do
  interpreter "bash"
  user "vagrant"
  cwd "/tmp"
  code <<-SHELL
    if ! type mailcatcher &> /dev/null; then
      source "#{user_home}/.rvm/scripts/rvm"
      rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
      rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
    fi
  SHELL
end

# Toggle the mailcatcher service
service "mailcatcher" do
  if node["mailcatcher"]["enabled"]
    action :start
  else
    action :stop
  end
end
