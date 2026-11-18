"""Raw JSON -> Bronze JSONL micro-batches -> Dead letter Routes rows with a blank event_id to dead letter."""
import json, logging, sys
from datetime import datetime, timezone
from pathlib import Path
import yaml

log = logging.getLogger("ingest")

def load_settings() -> dict:
    return yaml.safe_load(Path("config/settings.yaml").read_text())

def chunked(items, size):
    for i in range(0, len(items), size):
        yield items[i:i + size]

def write_jsonl(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r) + "\n")

def main() -> int:
    s = load_settings()
    raw = json.loads(Path(s["paths"]["raw"]).read_text(encoding="utf-8"))
    run_ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    total_good = total_dead = 0

    for n, batch in enumerate(chunked(raw, s["batch_size"])):
        batch_id = f"{run_ts}_{n:04d}"
        good, dead = [], []
        for rec in batch:
            rec = {**rec, "_batch_id": batch_id, "_ingested_at": run_ts}
            # Strict rule: primary identifier must be present AND non-blank.
            if not str(rec.get("event_id") or "").strip():
                dead.append({**rec, "_dl_reason": "missing_event_id"})
            else:
                good.append(rec)
        write_jsonl(Path(s["paths"]["bronze"]) / f"batch_id={batch_id}" / "part.jsonl", good)
        write_jsonl(Path(s["paths"]["dead_letter"]) / "reason=missing_event_id" / f"{batch_id}.jsonl", dead)
        total_good += len(good); total_dead += len(dead)

    log.info("bronze=%d dead_letter=%d", total_good, total_dead)
    return 0

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    try:
        sys.exit(main())
    except (OSError, json.JSONDecodeError) as e:
        log.exception("ingestion failed: %s", e)
        sys.exit(1)