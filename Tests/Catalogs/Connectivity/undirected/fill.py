"""Fills each catalog row's Expected code span with the reference's canonical values (keeping
the values the source states, which ref.py then checks). Run once while writing the catalog."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref  # noqa: E402
CASES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cases.md")

def fmt(v):
    if v is True: return "T"
    if v is False: return "F"
    return str(v).replace(" ", "").replace("'", "")

def keys_for(vs, es, r):
    m = len(es)
    if m <= 40 and len(vs) <= 40:
        return ["cc", "conn", "br", "ap", "bcc", "bccv", "bic", "becc", "bec", "bct"]
    ks = ["ncc", "conn", "nbr", "nap", "nbcc", "nbecc", "bic", "bec"]
    if r["nap"] <= 20: ks.append("ap")
    if r["nbr"] <= 20: ks.append("br")
    if r["nbcc"] <= 12 and len(vs) <= 120: ks.append("bccv")
    if r["nbecc"] <= 12 and len(vs) <= 120: ks.append("becc")
    return ks

out = []
for line in open(CASES).read().splitlines():
    m = re.match(r"\|\s*(CN-\d+[a-z]?)\s*\|", line)
    if m:
        cells = line.strip().strip("|").split("|")
        g = re.search(r"`([^`]*)`", cells[2]) if len(cells) >= 4 else None
        e = re.search(r"`([^`]*)`", cells[3]) if g else None
        if g and e is not None:
            vs, es = ref.parse_graph(g.group(1))
            r = ref.compute(vs, es)
            claims = ref.parse_expected(e.group(1))
            for k, v in claims.items():
                if r[k] != v:
                    sys.exit(f"{m.group(1)}: claim {k}={v} but reference {r[k]}")
            ks = list(dict.fromkeys(list(claims) + keys_for(vs, es, r)))
            order = ["cc","ncc","conn","br","nbr","hasbr","ap","nap","bcc","nbcc","bccv","bic","becc","nbecc","bec","bct"]
            ks.sort(key=order.index)
            span = " ".join(f"{k}={fmt(r[k])}" for k in ks)
            cells[3] = cells[3].replace(e.group(0), f"`{span}`", 1)
            line = "|" + "|".join(cells) + "|"
    out.append(line)
open(CASES, "w").write("\n".join(out) + "\n")
print("filled")
