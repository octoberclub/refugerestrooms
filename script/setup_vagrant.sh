#!/bin/bash
# This script is run from vagrant to setup packages
# It's only tested with ubuntu 14.04
set -e

REFUGE_PATH=$HOME/refugerestrooms

# required packages
declare -A packages
packages=( 
  ["git"]="1:1.9.1-1"
  ["nodejs"]="0.10.25~dfsg2-2ubuntu1"
  ["phantomjs"]="1.9.0-1"
  ["postgresql-server-dev-9.3"]="9.3.5-0ubuntu0.14.04.1"
  ["postgresql-contrib-9.3"]="9.3.5-0ubuntu0.14.04.1" 
)

for package in "${!packages[@]}"
do
  version=${packages["$package"]}
  if dpkg -s $package | grep -q $version; then
    echo $package' installed, skipping'
  else
    echo 'installing '$i', version '$version'...'
    sudo apt-get install -y -q $package=$version
  fi
done

# Install rbenv and ruby-build
echo 'installing rbenv...'
cd
if ! [ -d .rbenv ]; then
  git clone git://github.com/sstephenson/rbenv.git .rbenv
fi
if ! grep -q '.rbenv/bin' $HOME/.bashrc; then
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
fi
if ! grep -q 'rbenv init' $HOME/.bashrc; then
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
fi
if ! [ -d ~/.rbenv/plugins/ruby-build ]; then
  git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
fi
if ! grep -q ruby-build $HOME/.bashrc; then
  echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
fi

# source .bashrc doesn't appear to be setting the path
# adding the following for now:
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

# Install ruby
ruby_version=`cat $REFUGE_PATH/.ruby-version`
if rbenv versions | grep $ruby_version; then
  echo 'ruby '$ruby_version' installed, skipping...'
else
  echo 'install ruby '$ruby_version
  rbenv install $ruby_version
fi

# Install bundle reqs
cd $REFUGE_PATH
if which bundle; then
  echo 'bundler installed, skipping'
else
  echo 'Installing bundler...'
  gem install bundler --no-rdoc --no-ri -q
fi
echo 'Running bundle install...'
bundle install

# Creating postres user
echo 'Creating vagrant postgres user...'
sudo -u postgres createuser vagrant --createdb  --superuser

# Seed db
echo 'Seeding db...'
rake db:setup
