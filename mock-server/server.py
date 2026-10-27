"""A tiny MOCK backend for the app (not a real server, nothing is saved to disk).

GET  /transactions  -> returns the list from transactions.json
POST /transactions  -> adds the JSON body to the in-memory list and returns it with a new id

Run it with:  python3 mock-server/server.py
It listens on http://localhost:3000 (the iOS simulator can reach it there).
"""
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

DATA_FILE = Path(__file__).parent / "transactions.json"
transactions = json.loads(DATA_FILE.read_text())


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/transactions":
            self.send_json(200, transactions)
        else:
            self.send_json(404, {"error": "Not found"})

    def do_POST(self):
        if self.path != "/transactions":
            self.send_json(404, {"error": "Not found"})
            return
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length))
        new_id = max((t["id"] for t in transactions), default=0) + 1
        created = {"id": new_id, **body}
        transactions.append(created)
        self.send_json(201, created)

    def send_json(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    print("Mock server running on http://localhost:3000")
    HTTPServer(("127.0.0.1", 3000), Handler).serve_forever()
