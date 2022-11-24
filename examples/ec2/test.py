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
