from locust import FastHttpUser, task, constant_pacing

class EcappUser(FastHttpUser):
    wait_time = constant_pacing(1)
    @task(500) #task weight
    def index_page(self): #Simulate user traffic to home page
        response = self.client.get("/index.php")

    @task(200) 
    def view_products(self): #Request to view products
        response = self.client.get("/products.php")

    @task(100) 
    def view_item(self): #Request to view a specific item
        response = self.client.get("/products.php", params={
            "product_id": "1"
        })

    @task(5)
    def add_to_cart(self): #Request to add a product to the cart
        response = self.client.get("/cart.php", params={
            "add_to_cart": "3"
        })

