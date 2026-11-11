import subprocess, os, re

BIN=r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
env=dict(os.environ); env["MYSQL_PWD"]="root"

def q(sql, db=None):
    a=[BIN,"-u","root","-h","127.0.0.1","-N","--default-character-set=utf8mb4"]
    if db: a+=[db]
    a+=["-e",sql]
    r=subprocess.run(a,capture_output=True,text=True,encoding="utf-8",errors="replace",env=env)
    return r.stdout.strip(), r.stderr.strip()

def cols(tbl):
    o,_=q(f"SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema='echo_world' AND table_name='{tbl}' ORDER BY ORDINAL_POSITION;")
    return [c.strip() for c in o.splitlines() if c.strip()]

def split_fields(inner):
    parts, cur, instr, quote, depth, i = [], "", False, None, 0, 0
    while i < len(inner):
        ch = inner[i]
        if instr:
            cur += ch
            if ch == "\\" and i+1 < len(inner): cur += inner[i+1]; i += 2; continue
            if ch == quote: instr = False
        else:
            if ch in ("'", '"'): instr, quote = True, ch; cur += ch
            elif ch == "(": depth += 1; cur += ch
            elif ch == ")": depth -= 1; cur += ch
            elif ch == "," and depth == 0: parts.append(cur.strip()); cur = ""
            else: cur += ch
        i += 1
    if cur.strip(): parts.append(cur.strip())
    return parts

def split_tuples(blob):
    out, depth, start, instr, quote, i = [], 0, None, False, None, 0
    while i < len(blob):
        ch = blob[i]
        if instr:
            if ch == "\\": i += 2; continue
            if ch == quote: instr = False
        else:
            if ch in ("'", '"'): instr, quote = True, ch
            elif ch == "(":
                if depth == 0: start = i
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0: out.append(blob[start:i+1])
        i += 1
    return out

def find_end(text, start):
    depth, instr, quote, i = 0, False, None, start
    while i < len(text):
        ch = text[i]
        if instr:
            if ch == "\\": i += 2; continue
            if ch == quote: instr = False
        else:
            if ch in ("'", '"'): instr, quote = True, ch
            elif ch == "(": depth += 1
            elif ch == ")": depth -= 1
            elif ch == ";" and depth == 0: return i
        i += 1
    return None

IT = {c.lower(): c for c in cols("item_template")}
print("item_template:", len(IT), "| bonding:", "bonding" in IT, "| description:", "description" in IT)

SRC = r"C:\Users\Orel\Downloads\m-orlovrus59-azeroth-custom-realm-main (1)\m-orlovrus59-azeroth-custom-realm-e052691\sql\world"
INS = re.compile(r"INSERT INTO\s+`item_template`\s*\((.*?)\)\s*VALUES", re.S|re.I)

values = {}
for fn in ("0004_campaign_reward_item.sql","0005_campaign2_content.sql","0006_campaign3_rewards.sql",
           "0008_npc_displayid.sql","0009_event_pvp.sql","0012_campaign4_content.sql",
           "0014_waloria_rewards.sql","0018_eluna_scripts_tier_a.sql"):
    p = os.path.join(SRC, fn)
    if not os.path.exists(p): continue
    t = re.sub(r"(?m)^\s*--[^\n]*\n", "\n", open(p, encoding="utf-8").read())
    for m in INS.finditer(t):
        old = [c.strip().strip("`") for c in m.group(1).split(",") if c.strip()]
        ve = find_end(t, m.end())
        if ve is None: continue
        for tup in split_tuples(t[m.end():ve]):
            f = split_fields(tup[1:-1])
            if len(f) != len(old): continue
            rec = dict(zip(old, f))
            values[rec["entry"]] = rec

print("собрано предметов:", len(values), sorted(values))
targets = [e for e in values if 70000 <= int(e) <= 70110]
for e in sorted(targets, key=int):
    r = values[e]
    print(f"  {e} {r.get('name')} | bonding={r.get('bonding')} desc={'да' if r.get('description','').strip() else 'нет'}")
import json
json.dump({k:v for k,v in values.items() if 70000<=int(k)<=70110}, open(r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\items.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)
