from locust import HttpUser, task, between
import random
import string

def generate_random_string(length=100):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

class PastebinUser(HttpUser):
    wait_time = between(0.1, 2)
    
    def on_start(self):
        # We start by creating a paste so we have something to read
        self.known_pastes = []
        self.create_paste()
        
    def create_paste(self):
        payload = {
            "content": generate_random_string(500),
            "language": random.choice(["python", "javascript", "plaintext"]),
            "ttl_days": 7
        }
        with self.client.post("/api/pastes", json=payload, catch_response=True) as response:
            if response.status_code == 201:
                data = response.json()
                self.known_pastes.append(data["paste_id"])
                response.success()
            else:
                response.failure(f"Failed to create: {response.text}")

    @task(1)
    def task_create(self):
        self.create_paste()

    @task(9)
    def task_read(self):
        if not self.known_pastes:
            return
            
        paste_id = random.choice(self.known_pastes)
        with self.client.get(f"/api/pastes/{paste_id}", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                # Might have expired or wrong ID
                response.failure("Paste not found")
            else:
                response.failure(f"Error reading: {response.text}")
