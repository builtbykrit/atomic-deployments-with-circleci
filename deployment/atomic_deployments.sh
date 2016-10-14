#!/bin/bash
# This is a script to automate atomic deployments using
# a releases folder and a symbolic link to the "current"
# release.

# Get current the hash of the most recent commit, we'll
# use it as our version number when we make a new folder under releases
cd /var/www/example/current && git remote update
HEAD=$(cd /var/www/example/current && git rev-parse @{u})
if [ -d "/var/www/example/releases/$HEAD" ]; then
	echo "Commit $HEAD is already deployed."
    exit 1
fi

# If the most recent commit isn't already deployed, pull it down
# and create a new virtualenv for it.
git clone git@github.com:builtbykrit/atomic-deployments-with-circleci.git /var/www/example/releases/$HEAD
cd /var/www/example/releases && virtualenv -p python3 $HEAD

# Install dependencies
CURRENT=$(echo /var/www/example/releases/$HEAD)
cd $CURRENT && \
   source $CURRENT/bin/activate && \
   pip install -r $CURRENT/requirements.txt

# Before we update the current symlink, run tests just
# to make sure everything works on the production environment
source $CURRENT/bin/activate
python $CURRENT/manager.py test
if [ "$?" -eq "1" ]
then
  # Tests failed
  rm -rf $CURRENT
  echo "Fatal: Tests failed"
  exit 1
fi

# Tests worked, update the current symlink and restart supervisor
rm /var/www/example/current && ln -s $CURRENT /var/www/example/current
supervisorctl reload
echo "Restarting API"
sleep 5
supervisorctl stop example
supervisorctl start example

# Only keep last 5 releases
NUM_RELEASES=$(cd /var/www/example/releases && (ls -t)|wc -l)
if [ $NUM_RELEASES -gt 5 ]; then
	cd /var/www/example/releases && (ls -t|head -n 5;ls)|sort|uniq -u|xargs rm -rf
fi

echo "COMMIT $HEAD DEPLOYED SUCCESFULLY!"
