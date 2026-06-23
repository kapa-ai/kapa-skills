#!/usr/bin/env bash
set -euo pipefail

csv_file="${1:?Usage: setup.sh <csv_path>}"
out_dir="source_analytics"

mkdir -p "$out_dir/to_do" "$out_dir/to_review" "$out_dir/done"

python3 - "$csv_file" "$out_dir" << 'PYEOF'
import csv, json, os, re, sys
from collections import defaultdict

csv_file = sys.argv[1]
out_dir = sys.argv[2]

def slugify(url):
    if "/" not in url:
        return "root"
    path = url.split("/", 1)[1]
    if not path:
        return "root"
    return re.sub(r"[^a-zA-Z0-9._-]+", "_", path)

bundles = defaultdict(lambda: {"qa_ids_seen": set(), "threads": {}})

with open(csv_file, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        url = row["Referenced URL"]
        qid = row["Question/Answer ID"]
        tid = row["Thread ID"]
        b = bundles[url]
        if qid in b["qa_ids_seen"]:
            continue
        b["qa_ids_seen"].add(qid)
        thread = b["threads"].setdefault(tid, {
            "thread_id": tid,
            "integration": row["Integration"],
            "custom_tags": row["Custom Tags"],
            "qas": [],
        })
        thread["qas"].append({
            "qa_id": qid,
            "asked_at": row["Question Asked At (UTC)"],
            "is_uncertain": row["Is Uncertain"] == "True",
            "upvotes": int(row["Answer Upvotes"] or 0),
            "downvotes": int(row["Answer Downvotes"] or 0),
            "feedback_comments": row["Feedback Comments"],
            "question": row["Question"],
            "answer": row["Answer"],
            "support_form_deflection_status": row.get("Support Form Deflection Status", ""),
        })

url_stats = []
for url, b in bundles.items():
    threads = list(b["threads"].values())
    for t in threads:
        t["qas"].sort(key=lambda q: q["asked_at"])

    # Deduplicate threads by question-text sequence (order matters). Keep the first occurrence, drop the rest.
    seen = set()
    kept = []
    for t in threads:
        key = tuple(q["question"] for q in t["qas"])
        if key in seen:
            continue
        seen.add(key)
        kept.append(t)
    kept.sort(key=lambda t: t["qas"][0]["asked_at"] if t["qas"] else "")

    all_qas = [q for t in kept for q in t["qas"]]
    uncertain = sum(1 for q in all_qas if q["is_uncertain"])
    upvotes = sum(q["upvotes"] for q in all_qas)
    downvotes = sum(q["downvotes"] for q in all_qas)
    url_stats.append({
        "url": url,
        "cites": len(all_qas),
        "threads_count": len(kept),
        "uncertain": uncertain,
        "upvotes": upvotes,
        "downvotes": downvotes,
        "slug": slugify(url),
        "threads": kept,
    })

url_stats.sort(key=lambda r: -r["cites"])

# Width of the citation-count prefix (zero-padded to the max count so files sort numerically when listed)
max_cites = url_stats[0]["cites"] if url_stats else 0
count_width = max(2, len(str(max_cites)))

for i, r in enumerate(url_stats, 1):
    count_prefix = str(r["cites"]).zfill(count_width)
    fname = f"{count_prefix}-{r['slug']}.json"
    path = os.path.join(out_dir, "to_do", fname)
    payload = {
        "url": r["url"],
        "rank": i,
        "stats": {
            "cites": r["cites"],
            "threads": r["threads_count"],
            "uncertain": r["uncertain"],
            "upvotes": r["upvotes"],
            "downvotes": r["downvotes"],
        },
        "threads": r["threads"],
    }
    with open(path, "w") as out:
        json.dump(payload, out, indent=2, ensure_ascii=False)

print(f"\nParsed {sum(r['cites'] for r in url_stats)} citation events across {len(url_stats)} URLs.\n")
print(f"{'Rank':>4}  {'Cites':>5}  {'Thr':>4}  {'Unc':>4}  {'Up':>3}  {'Dn':>3}  URL")
for i, r in enumerate(url_stats[:25], 1):
    print(f"{i:>4}  {r['cites']:>5}  {r['threads_count']:>4}  {r['uncertain']:>4}  {r['upvotes']:>3}  {r['downvotes']:>3}  {r['url']}")
if len(url_stats) > 25:
    print(f"\n... and {len(url_stats) - 25} more URLs (total {len(url_stats)}).")

print(f"\nBundles written to {out_dir}/to_do/")
print(f"Subagent reports will be written to {out_dir}/to_review/")
print(f"User-reviewed reports will be moved to {out_dir}/done/")
PYEOF
