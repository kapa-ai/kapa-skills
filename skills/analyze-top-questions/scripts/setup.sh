#!/usr/bin/env bash
set -euo pipefail

csv_file="${1:?Usage: setup.sh <csv_path>}"
output_dir="top_questions"

mkdir -p "$output_dir/to_do" "$output_dir/done"

python3 - "$csv_file" "$output_dir" << 'PYEOF'
import csv, re, sys, os

csv_file = sys.argv[1]
output_dir = sys.argv[2]

def slugify(s):
    s = s.lower()
    s = re.sub(r'[^a-z0-9]+', '-', s)
    return s.strip('-')

clusters = {}
order = []

with open(csv_file) as f:
    reader = csv.DictReader(f)
    for row in reader:
        cid = row['Cluster ID']
        if cid not in clusters:
            clusters[cid] = {
                'title': row['Cluster Title'],
                'summary': row['Cluster Summary'],
                'count': int(row['Cluster Thread Count']),
                'unique_users': int(row.get('Cluster Unique Users', 0)),
                'questions': [],
            }
            order.append(cid)
        clusters[cid]['questions'].append(row['Initial Question'])

order.sort(key=lambda cid: clusters[cid]['count'], reverse=True)

for i, cid in enumerate(order, 1):
    c = clusters[cid]
    slug = slugify(c['title'])
    fname = f"{output_dir}/to_do/{i:02d}-{slug}.md"
    questions = '\n'.join(f"- {q}" for q in c['questions'])
    with open(fname, 'w') as out:
        out.write(f"# {c['title']}\n\n")
        out.write(f"## Cluster Info\n")
        out.write(f"- **Cluster ID:** {cid}\n")
        out.write(f"- **Thread Count:** {c['count']}\n")
        out.write(f"- **Unique Users:** {c['unique_users']}\n\n")
        out.write(f"## Summary\n{c['summary']}\n\n")
        out.write(f"## Questions\n{questions}\n\n")
        out.write(f"## Analysis\n_To be filled in during review._\n\n")
        out.write(f"## Decision\n_To be filled in during review._\n")
    print(f"  Created {fname}")

print(f"\nDone. {len(order)} cluster files created in {output_dir}/to_do/")
PYEOF
