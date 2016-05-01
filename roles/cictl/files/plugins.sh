#!/bin/bash

# Parse a support-core plugin -style txt file as specification for jenkins plugins to be installed
# in the reference directory, so user can define a derived Docker image with just :
#
# # Delete cloudbees-folder.jpi
# cloudbees-folder:#:-
# # Create timestamper.jpi
# timestamper:1.7.2:+
# # Disable cvs.jpi
# cvs:#:/
#

TARGET_D=${2:-.}
CLEAN_F=${3:-false}
JENKINS_UC=https://updates.jenkins-ci.org
REF=~/tmp/plugins
mkdir -p ${REF}

while read spec || [ -n "$spec" ]; do
    plugin=(${spec//:/ });
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"

    if [ -z "$JENKINS_UC_DOWNLOAD" ]; then
      JENKINS_UC_DOWNLOAD=${JENKINS_UC}/download
    fi
    if [ ${plugin[2]} = '+' ]; then
      if [ ${CLEAN_F} == true ]; then
        if [ -s ${TARGET_D}/${plugin[0]}.jpi ]; then
          echo "Cleaning ${TARGET_D}/${plugin[0]}.jpi"
          rm -f ${TARGET_D}/${plugin[0]}.jpi
        fi
        if [ -s ${REF}/${plugin[0]}.${plugin[1]}.jpi ]; then
          echo "Cleaning ${REF}/${plugin[0]}.${plugin[1]}.jpi"
          rm -f ${REF}/${plugin[0]}.${plugin[1]}.jpi
        fi
      fi
      if [ ! -s ${TARGET_D}/${plugin[0]}.jpi ]; then
        if [ ! -s ${REF}/${plugin[0]}.${plugin[1]}.jpi ]; then
          echo "Downloading ${plugin[0]}:${plugin[1]}"
          curl -sSL -f ${JENKINS_UC_DOWNLOAD}/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi -o ${REF}/${plugin[0]}.${plugin[1]}.jpi
          # gunzip -qqt ${REF}/${plugin[0]}.jpi
        fi
        echo "Copying ${REF}/${plugin[0]}.${plugin[1]}.jpi ${TARGET_D}/${plugin[0]}.jpi"
        cp ${REF}/${plugin[0]}.${plugin[1]}.jpi ${TARGET_D}/${plugin[0]}.jpi
      elif [ -s ${TARGET_D}/${plugin[0]}.jpi ]; then
        echo "Already present: ${TARGET_D}/${plugin[0]}.jpi"
      fi

    elif [ ${plugin[2]} = '-' ]; then
      if [ -s ${TARGET_D}/${plugin[0]}.jpi ] || [ -d ${TARGET_D}/${plugin[0]}/ ]; then
        echo "Removing ${TARGET_D}/${plugin[0]}.jpi* ${TARGET_D}/${plugin[0]}/"
        rm -rf ${TARGET_D}/${plugin[0]}.jpi* ${TARGET_D}/${plugin[0]}/
      elif [ ! -s ${TARGET_D}/${plugin[0]}.jpi.disabled ] || [ ! -d ${TARGET_D}/${plugin[0]}/ ]; then
        echo "Already removed: ${TARGET_D}/${plugin[0]}.jpi* ${TARGET_D}/${plugin[0]}/"
      fi

    elif [ ${plugin[2]} = '/' ]; then
      if [ ! -f ${TARGET_D}/${plugin[0]}.jpi.disabled ]; then
        echo "Disabling ${TARGET_D}/${plugin[0]}.jpi"
        touch ${TARGET_D}/${plugin[0]}.jpi.disabled
      elif [ -f ${TARGET_D}/${plugin[0]}.jpi.disabled ]; then
        echo "Already disabled: ${TARGET_D}/${plugin[0]}.jpi"
      fi

    fi
done  < $1
