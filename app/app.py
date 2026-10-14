import os
import time

import psycopg2
from flask import Flask, redirect, render_template_string, request, url_for

app = Flask(__name__)

# DB settings come from environment variables, never hardcoded
DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "port": os.environ.get("DB_PORT", "5432"),
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
}

PAGE = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Messages</title>
<style>
  body { font-family: system-ui, sans-serif; background: #f4f5f7; margin: 0; padding: 40px 16px; color: #1f2933; }
  .card { max-width: 560px; margin: 0 auto; background: #fff; border-radius: 12px; padding: 24px; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
  h2, h3 { margin: 0 0 12px; }
  form { display: flex; flex-direction: column; gap: 10px; margin-bottom: 24px; }
  input { padding: 10px; border: 1px solid #cbd2d9; border-radius: 8px; font-size: 15px; }
  button { padding: 10px; border: 0; border-radius: 8px; background: #2563eb; color: #fff; font-size: 15px; cursor: pointer; }
  button:hover { background: #1d4ed8; }
  ul { list-style: none; padding: 0; margin: 0; }
  li { padding: 10px 0; border-top: 1px solid #e4e7eb; }
  .empty { color: #7b8794; }
</style>
</head>
<body>
<div class="card">
  <h2>Leave a message</h2>
  <form method="post" action="{{ url_for('add') }}">
    <input name="name" placeholder="Your name" maxlength="50" required>
    <input name="message" placeholder="Say something" maxlength="200" required>
    <button type="submit">Save</button>
  </form>
  <h3>Latest messages</h3>
  <ul>
  {% for name, message in rows %}
    <li><b>{{ name }}</b>: {{ message }}</li>
  {% else %}
    <li class="empty">No messages yet.</li>
  {% endfor %}
  </ul>
</div>
</body>
</html>
"""


def get_conn():
    return psycopg2.connect(**DB_CONFIG)


def init_db():
    # Retry so the app survives starting before the DB is ready
    for _ in range(15):
        try:
            with get_conn() as conn, conn.cursor() as cur:
                cur.execute(
                    """CREATE TABLE IF NOT EXISTS messages (
                           id SERIAL PRIMARY KEY,
                           name VARCHAR(50) NOT NULL,
                           message VARCHAR(200) NOT NULL,
                           created_at TIMESTAMP DEFAULT now()
                       )"""
                )
            return
        except psycopg2.OperationalError:
            time.sleep(2)
    raise RuntimeError("Database not reachable")


init_db()


@app.route("/")
def index():
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT name, message FROM messages ORDER BY id DESC LIMIT 10")
        rows = cur.fetchall()
    return render_template_string(PAGE, rows=rows)


@app.route("/add", methods=["POST"])
def add():
    name = request.form.get("name", "").strip()[:50]
    message = request.form.get("message", "").strip()[:200]
    if name and message:
        with get_conn() as conn, conn.cursor() as cur:
            # Parameterized query, so no SQL injection
            cur.execute(
                "INSERT INTO messages (name, message) VALUES (%s, %s)",
                (name, message),
            )
    return redirect(url_for("index"))


@app.route("/health")
def health():
    return "ok", 200