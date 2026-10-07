from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return """
    <html>
    <head>
        <title>Banking DevOps Platform</title>
    </head>
    <body>

        <h1>🏦 Banking DevOps Platform</h1>

        <h2>Project 2 - Amazon EKS Platform</h2>

        <p>Successfully deployed using:</p>

        <ul>
            <li>Terraform</li>
            <li>Amazon EKS</li>
            <li>Kubernetes</li>
            <li>Amazon ECR</li>
            <li>AWS Load Balancer Controller</li>
            <li>Application Load Balancer</li>
        </ul>

        <h3>Environment: DEV</h3>

    </body>
    </html>
    """


@app.route("/health")
def health():
    return {"status": "healthy"}, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
