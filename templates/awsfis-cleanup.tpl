#!/bin/bash
OUTPUT=${explist}

function clean () {
  while read id; do
    aws fis delete-experiment-template \
      --region ${region} --output text \
      --id $${id} --query 'experimentTemplate.id' 2>&1 > /dev/null
  done < $${OUTPUT}
  rm $${OUTPUT}
}

clean
