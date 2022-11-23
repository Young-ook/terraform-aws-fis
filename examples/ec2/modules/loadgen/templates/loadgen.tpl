#!/bin/bash -x

cat <<EOF >> /tmp/locust.yaml
---
execution:
- executor: locust
  concurrency: 10
  ramp-up: 1m
  iterations: 1000
  scenario: loadgen

scenarios:
  loadgen:
    default-address: ${target}
    script: load.py
EOF

cat <<EOF >> /tmp/load.py
from locust import HttpUser, TaskSet, task, between

class WebsiteTasks(TaskSet):
    @task
    def index(self):
        self.client.get("/")

    @task
    def about(self):
        self.client.get("/carts")

class WebsiteUser(HttpUser):
    tasks = [WebsiteTasks]
    wait_time = between(0.100, 1.500)
EOF

### setup taurus
pip3 install bzt zope.event
chmod 644 /tmp/locust.yaml /tmp/load.py

### run load test
# python3 -m bzt /tmp/loadgen.yaml
