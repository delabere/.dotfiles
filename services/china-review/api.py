"""Tiny comments API for the video review page (stdlib only, low memory).

GET    /api/comments              -> all comments
POST   /api/comments              {version, t, text}            -> new comment (shot looked up from the version's manifest)
PATCH  /api/comments/<id>         {status: "open"|"done"|"wontfix", reply?}
DELETE /api/comments/<id>
Comments live in $STATE_DIR/comments.json; manifests in $REVIEW_DIR/<version>/manifest.json.
"""
import json, os, threading, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = os.environ.get("STATE_DIR", "/var/lib/china-review")
REVIEW = os.environ.get("REVIEW_DIR", "/mnt/bigboi/share/China2026Edit/Review")
DB = os.path.join(STATE, "comments.json")
LOCK = threading.Lock()


def load():
    try:
        with open(DB) as f: return json.load(f)
    except FileNotFoundError:
        return []


def store(items):
    tmp = DB + ".tmp"
    with open(tmp, "w") as f: json.dump(items, f, indent=1, ensure_ascii=False)
    os.replace(tmp, DB)


def shot_at(version, t):
    try:
        with open(os.path.join(REVIEW, version, "manifest.json")) as f: m = json.load(f)
    except (FileNotFoundError, ValueError):
        return None
    for s in m.get("shots", []):
        if s["start"] <= t < s["end"]:
            return {k: s.get(k) for k in ("name", "src_in", "chapter", "kind")}
    return None


class H(BaseHTTPRequestHandler):
    def _send(self, code, body=None):
        data = json.dumps(body if body is not None else {}).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _json(self):
        n = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}

    def _id(self):
        parts = self.path.rstrip("/").split("/")
        return parts[3] if len(parts) > 3 else None

    def do_GET(self):
        if self.path.startswith("/api/comments"):
            with LOCK: return self._send(200, load())
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if not self.path.startswith("/api/comments"): return self._send(404)
        b = self._json()
        text = (b.get("text") or "").strip()
        if not text: return self._send(400, {"error": "empty"})
        c = {"id": uuid.uuid4().hex[:10], "version": b.get("version", ""), "t": float(b.get("t") or 0),
             "text": text[:2000], "status": "open", "created": time.strftime("%Y-%m-%d %H:%M"),
             "shot": shot_at(b.get("version", ""), float(b.get("t") or 0)), "reply": ""}
        with LOCK:
            items = load(); items.append(c); store(items)
        self._send(201, c)

    def do_PATCH(self):
        cid = self._id(); b = self._json()
        with LOCK:
            items = load()
            for c in items:
                if c["id"] == cid:
                    for k in ("status", "reply", "text"):
                        if k in b: c[k] = str(b[k])[:2000]
                    store(items); return self._send(200, c)
        self._send(404, {"error": "no such comment"})

    def do_DELETE(self):
        cid = self._id()
        with LOCK:
            items = load(); keep = [c for c in items if c["id"] != cid]
            if len(keep) == len(items): return self._send(404, {"error": "no such comment"})
            store(keep)
        self._send(200, {"deleted": cid})

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    os.makedirs(STATE, exist_ok=True)
    ThreadingHTTPServer(("127.0.0.1", int(os.environ.get("PORT", "3031"))), H).serve_forever()
