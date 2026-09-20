from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        service="devsecops-sample-api",
        environment=os.getenv("APP_ENV", "local"),
        version=os.getenv("APP_VERSION", "dev"),
        status="running",
    )


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
