#!/bin/sh
ANSIBLE_STABLE_BRANCH=devel

if [ "$(id -u)" != "0" ]; then
  echo "Sorry, this script must be run as root."
  exit 1
fi

while getopts ":b:c:d" opt; do
  case $opt in
    b)
      branch=$OPTARG
      ;;
    c)
      checkout=$OPTARG
      ;;
    d)
      ANSIBLE_DEBUG=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

which ansible > /dev/null 2>&1
if [ $? -eq 1 ]; then

  echo "Installing Ansible build dependencies."
  if [ -z $ANSIBLE_DEBUG ]; then
    apt-get -qq --force-yes update > /dev/null 2>&1
    apt-get -qq --force-yes install git python-pip python-setuptools python-pycurl python-dev python-paramiko build-essential > /dev/null 2>&1
  else
    apt-get --force-yes update
    apt-get --force-yes install git python-pip python-setuptools python-pycurl python-dev python-paramiko build-essentia
  fi

  if [ -z $branch ] && [ ! -z $ANSIBLE_BRANCH ]; then
    echo "Setting branch from environment."
    branch=$ANSIBLE_BRANCH
  fi

  if [ -z $branch ]; then
    echo "Using default stable branch: $ANSIBLE_STABLE_BRANCH."
    branch="--branch $ANSIBLE_STABLE_BRANCH"
  else
    echo "Using $branch branch."
    branch="--branch $branch"
  fi

  ansible_dir=/usr/local/lib/ansible/
  if [ ! -d $ansible_dir ]; then
    echo "Cloning Ansible."
    if [ -z $ANSIBLE_DEBUG ]; then
      git clone --quiet --recursive git://github.com/ansible/ansible.git $branch $ansible_dir > /dev/null 2>&1
    else
      git clone --recursive git://github.com/ansible/ansible.git $branch $ansible_dir
    fi
  fi

  if [ -z $checkout ] && [ ! -z $ANSIBLE_CHECKOUT ]; then
    echo "Setting checkout target from environment."
    checkout=$ANSIBLE_CHECKOUT
  fi

  if [ ! -z $checkout ]; then
    echo "Checking out '$checkout'."
    cd $ansible_dir
    if [ -z $ANSIBLE_DEBUG ]; then
      git checkout $checkout --quiet
    else
      git checkout $checkout
    fi
  fi

  echo "Running setups tasks for Ansible."
  cd $ansible_dir
  if [ -z $ANSIBLE_DEBUG ]; then
    python ./setup.py install > /dev/null 2>&1
  else
    python ./setup.py install
  fi

fi
