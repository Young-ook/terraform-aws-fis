#!/bin/bash
OUTPUT=${explist}
TEMPLATES=(${jsonlist})

function clean () {
  if [ -e $${OUTPUT} ]; then
    while read id; do
      aws fis delete-experiment-template \
        --region ${region} --output text \
        --id $${id} --query 'experimentTemplate.id' 2>&1 > /dev/null
    done < $${OUTPUT}
    rm $${OUTPUT}
  fi
}

function create () {
  # create new experiment templates
  for template in $${TEMPLATES[@]}; do
    aws fis create-experiment-template \
      --region ${region} --output text \
      --cli-input-json file://$${template} \
      --query 'experimentTemplate.id' 2>&1 | tee -a $${OUTPUT}
  done
}

clean
create
