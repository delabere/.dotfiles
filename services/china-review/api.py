"""Tiny comments API for the video review page (stdlib only, low memory).

GET    /api/comments              -> all comments
GET    /api/ideas, POST /api/ideas/<id> {status open|approved|rejected, selected [photo names], note}  (photo insert ideas)
GET    /api/photos, POST /api/photos/<name> {rating 0-5, film, note}   (phone photo grading)
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


PHONE_DB = os.path.join(STATE, "phone.json")


def phone_overrides():
    try:
        with open(PHONE_DB) as f: return json.load(f)
    except FileNotFoundError:
        return {}


def store_phone(d):
    tmp = PHONE_DB + ".tmp"
    with open(tmp, "w") as f: json.dump(d, f, indent=1, ensure_ascii=False)
    os.replace(tmp, PHONE_DB)


def phone_list():
    """Base list (Review/phone.json, written by Claude: name, date, chapter, claude_status, reason)
    merged with the viewer's choices (status, note)."""
    try:
        with open(os.path.join(REVIEW, "phone.json")) as f: base = json.load(f)
    except (FileNotFoundError, ValueError):
        base = []
    ov = phone_overrides()
    return [{**p, **ov.get(p["name"], {})} for p in base]


PHOTO_DB = os.path.join(STATE, "photos.json")


def photo_overrides():
    try:
        with open(PHOTO_DB) as f: return json.load(f)
    except FileNotFoundError:
        return {}


def photo_list():
    """Review/photos.json (name, date, chapter; written by the thumbnail job) + the viewer's rating/film/note."""
    try:
        with open(os.path.join(REVIEW, "photos.json")) as f: base = json.load(f)
    except (FileNotFoundError, ValueError):
        base = []
    ov = photo_overrides()
    return [{**p, **ov.get(p["name"], {})} for p in base]


IDEA_DB = os.path.join(STATE, "ideas.json")


def idea_overrides():
    try:
        with open(IDEA_DB) as f: return json.load(f)
    except FileNotFoundError:
        return {}


def idea_list():
    """Review/photo_ideas.json (Claude's suggested photo inserts) + the viewer's decision, selected photos and note."""
    try:
        with open(os.path.join(REVIEW, "photo_ideas.json")) as f: base = json.load(f)
    except (FileNotFoundError, ValueError):
        base = []
    ov = idea_overrides()
    return [{**{"status": "open", "selected": [p["photo"]], "note": ""}, **p, **ov.get(p["id"], {})} for p in base]


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
        if self.path.startswith("/api/phone"):
            with LOCK: return self._send(200, phone_list())
        if self.path.startswith("/api/photos"):
            with LOCK: return self._send(200, photo_list())
        if self.path.startswith("/api/ideas"):
            with LOCK: return self._send(200, idea_list())
        self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path.startswith("/api/ideas/"):
            iid = self._id(); b = self._json()
            with LOCK:
                ov = idea_overrides(); cur = ov.get(iid, {})
                if b.get("status") in ("open", "approved", "rejected"): cur["status"] = b["status"]
                if isinstance(b.get("selected"), list): cur["selected"] = [str(x)[:100] for x in b["selected"]][:12]
                if "note" in b: cur["note"] = str(b["note"])[:1000]
                ov[iid] = cur
                tmp = IDEA_DB + ".tmp"
                with open(tmp, "w") as f: json.dump(ov, f, indent=1, ensure_ascii=False)
                os.replace(tmp, IDEA_DB)
            return self._send(200, {"id": iid, **cur})
        if self.path.startswith("/api/photos/"):
            name = self._id(); b = self._json()
            with LOCK:
                ov = photo_overrides(); cur = ov.get(name, {})
                if "rating" in b: cur["rating"] = max(0, min(5, int(b["rating"] or 0)))
                if "film" in b: cur["film"] = bool(b["film"])
                if "note" in b: cur["note"] = str(b["note"])[:1000]
                ov[name] = cur
                tmp = PHOTO_DB + ".tmp"
                with open(tmp, "w") as f: json.dump(ov, f, indent=1, ensure_ascii=False)
                os.replace(tmp, PHOTO_DB)
            return self._send(200, {"name": name, **cur})
        if self.path.startswith("/api/phone/"):
            name = self._id(); b = self._json()
            with LOCK:
                ov = phone_overrides(); cur = ov.get(name, {})
                for k in ("status", "note"):
                    if k in b: cur[k] = str(b[k])[:1000]
                ov[name] = cur; store_phone(ov)
            return self._send(200, {"name": name, **cur})
        if not self.path.startswith("/api/comments"): return self._send(404)
        b = self._json()
        text = (b.get("text") or "").strip()
        if not text: return self._send(400, {"error": "empty"})
        t = float(b.get("t") or 0); t_end = b.get("t_end")
        c = {"id": uuid.uuid4().hex[:10], "version": b.get("version", ""), "t": t,
             "text": text[:2000], "status": "open", "created": time.strftime("%Y-%m-%d %H:%M"),
             "shot": shot_at(b.get("version", ""), t), "reply": ""}
        if t_end is not None and float(t_end) > t:
            c["t_end"] = float(t_end); c["shot_end"] = shot_at(b.get("version", ""), float(t_end) - 0.01)
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
