from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Docker and Kubernetes! how are you doing today?"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
