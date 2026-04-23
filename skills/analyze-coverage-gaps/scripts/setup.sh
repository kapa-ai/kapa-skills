#!/usr/bin/env bash
set -euo pipefail

csv_file="${1:?Usage: setup.sh <csv_path>}"

mkdir -p coverage_gaps/to_do coverage_gaps/done

awk '
function parse_csv(line, fields,    i, c, in_q, field, n) {
    n = 0; field = ""; in_q = 0
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "\"") {
            if (in_q && substr(line, i+1, 1) == "\"") { field = field "\""; i++ }
            else in_q = !in_q
        } else if (c == "," && !in_q) {
            fields[n++] = field; field = ""
        } else {
            field = field c
        }
    }
    fields[n++] = field
    return n
}

function slugify(s,    slug) {
    slug = tolower(s)
    gsub(/[^a-z0-9]+/, "-", slug)
    gsub(/^-|-$/, "", slug)
    return slug
}

NR > 1 {
    delete f
    parse_csv($0, f)
    cid = f[3]
    if (!(cid in title)) {
        title[cid] = f[4]
        summary[cid] = f[5]
        suggestion[cid] = f[6]
        count[cid] = f[7] + 0
        questions[cid] = ""
        order[++num_clusters] = cid
    }
    if (questions[cid] != "") questions[cid] = questions[cid] "\n"
    questions[cid] = questions[cid] "- " f[1]
}

END {
    for (i = 1; i <= num_clusters; i++) {
        for (j = i + 1; j <= num_clusters; j++) {
            if (count[order[j]] > count[order[i]]) {
                tmp = order[i]; order[i] = order[j]; order[j] = tmp
            }
        }
    }

    for (i = 1; i <= num_clusters; i++) {
        cid = order[i]
        slug = slugify(title[cid])
        fname = sprintf("coverage_gaps/to_do/%02d-%s.md", i, slug)
        printf "# %s\n\n", title[cid] > fname
        printf "## Cluster Info\n" >> fname
        printf "- **Cluster ID:** %s\n", cid >> fname
        printf "- **Thread Count:** %d\n\n", count[cid] >> fname
        printf "## Summary\n%s\n\n", summary[cid] >> fname
        printf "## Suggestion\n%s\n\n", suggestion[cid] >> fname
        printf "## Questions\n%s\n\n", questions[cid] >> fname
        printf "## Analysis\n_To be filled in during review._\n\n" >> fname
        printf "## Decision\n_To be filled in during review._\n" >> fname
        close(fname)
        printf "  Created %s\n", fname
    }
    printf "\nDone. %d cluster files created in coverage_gaps/to_do/\n", num_clusters
}
' "$csv_file"
