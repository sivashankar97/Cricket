#!/usr/bin/env python3
"""Seed ball-by-ball + squad performances for the live NTL match from CricHeroes scorecard.

Match: ntl_ch_28435172 (Ariyalai vs Phoenix)
Re-run after refreshing SCORE below from the live scorecard page.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

PROJECT = "khelo-hexshankar"
MATCH_ID = "ntl_ch_28435172"
INN1 = f"{MATCH_ID}_inn1"
INN2 = f"{MATCH_ID}_inn2"
ARIYALAI = "auction_crickex_6057b0bb_cx1ac710"
PHOENIX = "auction_crickex_6057b0bb_cxd268f5"
OWNER = "E5QscYFSIqT29bRqBtnOFmhx9W33"

# Snapshot from CricHeroes scorecard (runs derived from SR×balls; FOW + bowling from page).
# Update when re-syncing.
SCORE = {
    "team_a_runs": 116,
    "team_a_wkts": 5,
    "team_a_overs": 10.0,
    "team_b_runs": 95,  # 79 bat + 16 extras (need text can lag)
    "team_b_wkts": 4,
    "team_b_overs": 7.1,
    "inn1": {
        "batters": [
            # name, runs, balls, fours, sixes, out?, how, bowler?, fielder?
            ("Ragavan", 1, 3, 0, 0, True, "caught", "Pakeerthithan", "Pirakash"),
            ("Jeevan", 78, 32, 3, 10, True, "caught", "Sathurjan", "Kishok"),
            ("Nirojan", 7, 11, 0, 1, True, "runOut", None, "Sankeethan"),
            ("Vijeevan", 12, 7, 1, 1, True, "bowled", "Sankeethan", None),
            ("Raguwaran", 8, 6, 0, 1, True, "caught", "Inthujan", "Pakeerthithan"),
            ("Raheeshan", 2, 2, 0, 0, False, None, None, None),
            ("Abilash", 0, 1, 0, 0, False, None, None, None),
        ],
        "yet_to_bat": ["Jeyatharsan", "Sathees", "Jenod", "Kayan"],
        "bowlers": [
            # name, overs_balls (legal), maidens, runs, wickets
            ("Pirasanth", 12, 0, 37, 0),
            ("Pakeerthithan", 12, 0, 14, 1),
            ("Sathurjan", 12, 0, 23, 1),
            ("Sankeethan", 12, 0, 19, 1),
            ("Inthujan", 12, 0, 21, 1),
        ],
        "extras": {"wd": 4, "nb": 2, "lb": 2, "b": 0},
        "fow": [
            # runs, wicket_num, batter, over_number (0-based completed), ball in over
            (11, 1, "Ragavan", 1, 1),
            (80, 2, "Nirojan", 6, 4),
            (95, 3, "Jeevan", 7, 3),
            (104, 4, "Raguwaran", 8, 5),
            (116, 5, "Vijeevan", 9, 5),
        ],
    },
    "inn2": {
        "batters": [
            ("Kishok", 0, 2, 0, 0, True, "caught", "Abilash", "Ragavan"),
            ("Pirakash", 51, 19, 0, 8, False, None, None, None),
            ("Nivek", 6, 2, 0, 1, True, "caught", "Abilash", "Jeevan"),
            ("Sathurjan", 15, 13, 0, 2, True, "caught", "Jeevan", "Abilash"),
            ("Sujith", 1, 2, 0, 0, True, "caught", "Jeyatharsan", "Ragavan"),
            ("Pirasanth", 6, 5, 0, 1, False, None, None, None),
        ],
        "yet_to_bat": ["Inthujan", "Siyamalan", "Pakeerthithan", "Sankeethan", "Ramchanthar"],
        "bowlers": [
            ("Abilash", 6, 0, 9, 2),
            ("Jenod", 12, 0, 21, 0),
            ("Jeyatharsan", 12, 0, 27, 1),
            ("Jeevan", 12, 0, 27, 1),
            ("Sathees", 1, 0, 4, 0),
        ],
        "extras": {"wd": 11, "nb": 0, "lb": 0, "b": 5},
        "fow": [
            (1, 1, "Kishok", 0, 2),
            (8, 2, "Nivek", 0, 4),
            (76, 3, "Sathurjan", 5, 5),
            (78, 4, "Sujith", 6, 1),
        ],
    },
}

# Fuzzy CricHeroes / short name → roster name keys used above
NAME_ALIASES = {
    "jeevan": "Jeevan",
    "jeevaraj": "Jeevan",
    "k nirojan": "Nirojan",
    "nirojan": "Nirojan",
    "raheshan yogalingam": "Raheeshan",
    "raheeshan": "Raheeshan",
    "jayatharsan": "Jeyatharsan",
    "jeyatharsan": "Jeyatharsan",
    "n sathees": "Sathees",
    "sathees": "Sathees",
    "n sathurjan": "Sathurjan",
    "sathurjan": "Sathurjan",
    "selvarasa pakeerththan": "Pakeerthithan",
    "pakeerthithan": "Pakeerthithan",
    "pakeerththan": "Pakeerthithan",
    "nivethanan": "Nivek",
    "nivek": "Nivek",
    "pirashanth": "Pirasanth",
    "prashanth": "Pirasanth",
}


def access_token() -> str:
    cfg = Path.home() / ".config/configstore/firebase-tools.json"
    return json.loads(cfg.read_text())["tokens"]["access_token"]


def fs_url(path: str) -> str:
    return (
        f"https://firestore.googleapis.com/v1/projects/{PROJECT}"
        f"/databases/(default)/documents/{path}"
    )


def request(method: str, path: str, body: dict | None = None, query: str = ""):
    url = fs_url(path) + (("?" + query) if query else "")
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {access_token()}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> {e.code} {e.read()[:500]}") from e


def s(v):
    return {"stringValue": v}


def i(v):
    return {"integerValue": str(int(v))}


def d(v):
    return {"doubleValue": float(v)}


def b(v):
    return {"booleanValue": bool(v)}


def ts(iso):
    return {"timestampValue": iso}


def null():
    return {"nullValue": None}


def arr(values):
    return {"arrayValue": {"values": values}} if values else {"arrayValue": {}}


def mmap(fields):
    return {"mapValue": {"fields": fields}}


def load_name_map(team_id: str) -> dict[str, str]:
    """short_key -> user id"""
    doc = request("GET", f"teams/{team_id}")
    ids = [
        p["mapValue"]["fields"]["id"]["stringValue"]
        for p in doc["fields"]["team_players"]["arrayValue"].get("values", [])
        or []
    ]
    out = {}
    for pid in ids:
        u = request("GET", f"users/{pid}")["fields"]
        name = u.get("name", {}).get("stringValue", "")
        key = name.strip()
        out[key.lower()] = pid
        out[key.split()[0].lower()] = pid
    # Force alias keys for known mismatches
    # Jeevan (CH) ↔ Jeevaraj (roster)
    if "jeevaraj" in out:
        out["jeevan"] = out["jeevaraj"]
    if "nivek" in out:
        out["nivethanan"] = out["nivek"]
    if "raheeshan" in out:
        out["raheshan"] = out["raheeshan"]
    if "jeyatharsan" in out:
        out["jayatharsan"] = out["jeyatharsan"]
    if "pakeerthithan" in out:
        out["pakeerththan"] = out["pakeerthithan"]
        out["selvarasa"] = out["pakeerthithan"]
    if "pirasanth" in out:
        out["pirashanth"] = out["pirasanth"]
    elif "prashanth" in out:
        out["pirashanth"] = out["prashanth"]
        out["pirasanth"] = out["prashanth"]
    return out


def resolve(maps: list[dict[str, str]], name: str | None) -> str | None:
    if not name:
        return None
    key = name.strip().lower()
    key = NAME_ALIASES.get(key, name).strip().lower() if False else key
    # normalize via aliases table
    for alias, canon in NAME_ALIASES.items():
        if key == alias or key == canon.lower():
            key = canon.lower()
            break
    for m in maps:
        if key in m:
            return m[key]
        # partial
        for k, vid in m.items():
            if key in k or k in key:
                return vid
    raise KeyError(f"Cannot resolve player {name!r}")


WICKET = {
    "caught": 2,
    "bowled": 1,
    "runOut": 7,
}


def expand_batter_balls(runs: int, balls: int, fours: int, sixes: int) -> list[int]:
    """Return list of runs_scored per ball (length == balls)."""
    if balls == 0:
        return []
    seq = [6] * sixes + [4] * fours
    used = sixes * 6 + fours * 4
    rem_runs = runs - used
    rem_balls = balls - len(seq)
    if rem_balls < 0 or rem_runs < 0:
        # fallback: dump runs on last ball
        seq = [0] * (balls - 1) + [runs]
        return seq
    ones = rem_runs
    dots = rem_balls - ones
    if dots < 0:
        # too many ones — use 2s/3s
        seq += [1] * rem_balls
        overflow = rem_runs - rem_balls
        if overflow > 0:
            seq[-1] += overflow
    else:
        seq += [1] * ones + [0] * dots
    # pad/trim
    if len(seq) < balls:
        seq += [0] * (balls - len(seq))
    return seq[:balls]


def synthesize_innings(
    inn: dict,
    inning_id: str,
    batting_map: dict[str, str],
    bowling_map: dict[str, str],
    both_maps: list[dict[str, str]],
    start: datetime,
) -> tuple[list[dict], dict[str, list]]:
    """Returns (ball docs fields-only list, performance by player id)."""
    balls_out: list[dict] = []
    performance: dict[str, list] = {}
    index = 0

    def mark(pid: str, status: int):
        nonlocal index
        if pid not in performance:
            index += 1
            performance[pid] = [{"inning_id": inning_id, "status": status, "index": index}]
        else:
            performance[pid][0]["status"] = status

    batters = inn["batters"]
    # opening pair
    for bname, *_ in batters[:2]:
        mark(resolve(both_maps, bname), 2)  # playing

    for name in inn["yet_to_bat"]:
        mark(resolve(both_maps, name), 1)  # yetToPlay

    # Pre-build each batter's delivery queue
    batter_queues = {
        name: expand_batter_balls(r, b, f, s6)
        for name, r, b, f, s6, *_ in batters
    }
    out_flags = {name: out for name, *_, out, how, bowl, fld in batters}
    out_meta = {
        name: (how, bowl, fld) for name, *rest in batters for how, bowl, fld in [rest[-3:]]
    }

    # Bowling order: list of bowler names repeating per legal ball in their spell
    bowl_queue: list[str] = []
    for bname, legal, *_ in inn["bowlers"]:
        bowl_queue.extend([bname] * legal)

    extras = dict(inn["extras"])
    fow_by_batter = {name: (runs, wk, ov, bal) for runs, wk, name, ov, bal in inn["fow"]}

    # Crease order
    crease = [batters[0][0], batters[1][0]]
    next_bat_i = 2
    legal_count = 0
    over_number = 0
    ball_in_over = 0
    total_runs = 0
    wickets = 0
    t = start
    bowl_i = 0

    def add_ball(
        *,
        striker: str,
        non: str,
        bowler: str,
        runs_scored: int,
        is_four=False,
        is_six=False,
        extras_type=None,
        extras_awarded=None,
        wicket_type=None,
        player_out=None,
        wicket_taker=None,
        legal=True,
    ):
        nonlocal legal_count, over_number, ball_in_over, total_runs, t, bowl_i
        t += timedelta(seconds=25)
        if legal:
            ball_in_over += 1
        bid = resolve(both_maps, bowler)
        sid = resolve(both_maps, striker)
        nid = resolve(both_maps, non)
        fields = {
            "id": s(""),  # filled later
            "inning_id": s(inning_id),
            "match_id": s(MATCH_ID),
            "over_number": i(over_number),
            "ball_number": i(ball_in_over if legal else max(1, ball_in_over)),
            "bowler_id": s(bid),
            "batsman_id": s(sid),
            "non_striker_id": s(nid),
            "runs_scored": i(runs_scored),
            "is_four": b(is_four),
            "is_six": b(is_six),
            "legal_delivery": b(legal),
            "time": ts(t.isoformat().replace("+00:00", "Z")),
            "score_time": ts(t.isoformat().replace("+00:00", "Z")),
        }
        if extras_type is not None:
            fields["extras_type"] = i(extras_type)
            fields["extras_awarded"] = i(extras_awarded or 0)
        else:
            fields["extras_type"] = null()
            fields["extras_awarded"] = null()
        if wicket_type is not None:
            fields["wicket_type"] = i(wicket_type)
            fields["player_out_id"] = s(resolve(both_maps, player_out))
            if wicket_taker:
                fields["wicket_taker_id"] = s(resolve(both_maps, wicket_taker))
            else:
                fields["wicket_taker_id"] = null()
        else:
            fields["wicket_type"] = null()
            fields["player_out_id"] = null()
            fields["wicket_taker_id"] = null()
        fields["fielding_position"] = null()
        balls_out.append(fields)
        total_runs += runs_scored + (extras_awarded or 0)
        if legal:
            legal_count += 1
            if ball_in_over >= 6:
                over_number += 1
                ball_in_over = 0

    # Inject extras first as wides/no-balls/byes attributed across innings
    # Spread wides at start of spells for simplicity
    extra_events = (
        [("wide", 1)] * extras.get("wd", 0)
        + [("nb", 1)] * extras.get("nb", 0)
        + [("bye", 1)] * extras.get("b", 0)
        + [("lb", 1)] * extras.get("lb", 0)
    )
    extra_i = 0

    # Main loop: consume batter queues until empty / all out quotas met
    safety = 0
    while any(batter_queues[n] for n, *_ in batters) and safety < 500:
        safety += 1
        striker, non = crease[0], crease[1]
        if not batter_queues[striker]:
            # swap if non has balls
            if batter_queues[non]:
                crease[0], crease[1] = non, striker
                striker, non = crease[0], crease[1]
            else:
                break

        # Occasionally insert an extra before a legal ball
        if extra_i < len(extra_events) and safety % 7 == 0:
            et, er = extra_events[extra_i]
            extra_i += 1
            bowler = bowl_queue[min(bowl_i, len(bowl_queue) - 1)]
            etype = {"wide": 1, "nb": 2, "bye": 3, "lb": 4}[et]
            add_ball(
                striker=striker,
                non=non,
                bowler=bowler,
                runs_scored=0,
                extras_type=etype,
                extras_awarded=er,
                legal=et not in ("wide", "nb"),
            )
            if et not in ("wide", "nb"):
                bowl_i += 1
            continue

        run = batter_queues[striker].pop(0)
        bowler = bowl_queue[min(bowl_i, len(bowl_queue) - 1)]
        bowl_i += 1
        is_four = run == 4
        is_six = run == 6
        is_last = not batter_queues[striker]
        wicket = None
        player_out = None
        taker = None
        wtype = None
        if is_last and out_flags[striker]:
            how, bowl_n, fld = out_meta[striker]
            wtype = WICKET[how]
            player_out = striker
            if how == "caught":
                taker = fld
                if bowl_n:
                    bowler = bowl_n
            elif how == "bowled":
                if bowl_n:
                    bowler = bowl_n
            elif how == "runOut":
                taker = fld
            wicket = True
            wickets += 1

        add_ball(
            striker=striker,
            non=non,
            bowler=bowler,
            runs_scored=run,
            is_four=is_four,
            is_six=is_six,
            wicket_type=wtype,
            player_out=player_out,
            wicket_taker=taker,
        )

        if wicket:
            mark(resolve(both_maps, striker), 3)  # played
            # new batter
            if next_bat_i < len(batters):
                new_b = batters[next_bat_i][0]
                next_bat_i += 1
                mark(resolve(both_maps, new_b), 2)
                crease[0] = new_b
            else:
                break
        elif run % 2 == 1:
            crease[0], crease[1] = crease[1], crease[0]

    # Flush remaining extras as wides
    while extra_i < len(extra_events):
        et, er = extra_events[extra_i]
        extra_i += 1
        bowler = bowl_queue[min(bowl_i, len(bowl_queue) - 1)]
        etype = {"wide": 1, "nb": 2, "bye": 3, "lb": 4}[et]
        add_ball(
            striker=crease[0],
            non=crease[1],
            bowler=bowler,
            runs_scored=0,
            extras_type=etype,
            extras_awarded=er,
            legal=et not in ("wide", "nb"),
        )

    # Mark not-outs still playing / played
    for name, *rest, out, how, bowl, fld in batters:
        pid = resolve(both_maps, name)
        if not out:
            # innings 1 finished → played; innings 2 still going → playing
            mark(pid, 2 if inning_id.endswith("inn2") else 3)
        elif pid in performance and performance[pid][0]["status"] == 2:
            mark(pid, 3)

    return balls_out, performance


def delete_existing_balls():
    # query by match_id
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents:runQuery"
    body = {
        "structuredQuery": {
            "from": [{"collectionId": "ball_scores"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "match_id"},
                    "op": "EQUAL",
                    "value": s(MATCH_ID),
                }
            },
            "limit": 500,
        }
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {access_token()}",
            "Content-Type": "application/json",
        },
    )
    res = json.loads(urllib.request.urlopen(req).read())
    n = 0
    for row in res:
        doc = row.get("document")
        if not doc:
            continue
        name = doc["name"].split("/documents/")[-1]
        request("DELETE", name)
        n += 1
    print(f"Deleted {n} old ball_scores")


def commit_balls(ball_fields: list[dict]):
    # Use batch commit (max 500)
    writes = []
    for idx, fields in enumerate(ball_fields):
        doc_id = f"{MATCH_ID}_b{idx:04d}"
        fields["id"] = s(doc_id)
        writes.append(
            {
                "update": {
                    "name": f"projects/{PROJECT}/databases/(default)/documents/ball_scores/{doc_id}",
                    "fields": fields,
                }
            }
        )
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents:commit"
    for i in range(0, len(writes), 400):
        chunk = writes[i : i + 400]
        req = urllib.request.Request(
            url,
            data=json.dumps({"writes": chunk}).encode(),
            method="POST",
            headers={
                "Authorization": f"Bearer {access_token()}",
                "Content-Type": "application/json",
            },
        )
        urllib.request.urlopen(req)
        print(f"Committed balls {i}..{i+len(chunk)-1}")


def upsert_match_squad(perf_a: dict, perf_b: dict, map_a: dict, map_b: dict):
    """Rewrite teams[].squad with performances; update totals."""
    # Build reverse id lists from maps - use team_players order
    def squad_for(team_id: str, perf: dict, name_map: dict):
        doc = request("GET", f"teams/{team_id}")
        ids = [
            p["mapValue"]["fields"]["id"]["stringValue"]
            for p in doc["fields"]["team_players"]["arrayValue"]["values"]
        ]
        # Prefer players who appear in this match first
        ordered = [pid for pid in ids if pid in perf] + [
            pid for pid in ids if pid not in perf
        ]
        # XI = those with performance + yet to bat already in perf
        values = []
        for pid in ordered:
            if pid not in perf:
                continue
            pentries = [
                mmap(
                    {
                        "inning_id": s(p["inning_id"]),
                        "status": i(p["status"]),
                        "index": i(p["index"]),
                    }
                )
                for p in perf[pid]
            ]
            # status on MatchPlayer: playing if any playing else played
            st = 2 if any(p["status"] == 2 for p in perf[pid]) else 3
            if all(p["status"] == 1 for p in perf[pid]):
                st = 1
            values.append(
                mmap(
                    {
                        "id": s(pid),
                        "status": i(st),
                        "performance": arr(pentries),
                    }
                )
            )
        return values, [v["mapValue"]["fields"]["id"]["stringValue"] for v in values]

    sq_a, ids_a = squad_for(ARIYALAI, perf_a, map_a)
    sq_b, ids_b = squad_for(PHOENIX, perf_b, map_b)

    sc = SCORE
    teams = arr(
        [
            mmap(
                {
                    "team_id": s(ARIYALAI),
                    "captain_id": null(),
                    "admin_id": null(),
                    "run": i(sc["team_a_runs"]),
                    "wicket": i(sc["team_a_wkts"]),
                    "over": d(sc["team_a_overs"]),
                    "squad": arr(sq_a),
                }
            ),
            mmap(
                {
                    "team_id": s(PHOENIX),
                    "captain_id": null(),
                    "admin_id": null(),
                    "run": i(sc["team_b_runs"]),
                    "wicket": i(sc["team_b_wkts"]),
                    "over": d(sc["team_b_overs"]),
                    "squad": arr(sq_b),
                }
            ),
        ]
    )
    fields = {
        "teams": teams,
        "players": arr([s(x) for x in ids_a + ids_b]),
        "match_status": i(2),
        "current_playing_team_id": s(PHOENIX),
        "toss_winner_id": s(PHOENIX),
        "toss_decision": i(2),
        "updated_at": ts(datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")),
    }
    request(
        "PATCH",
        f"matches/{MATCH_ID}",
        {"fields": fields},
        query="&".join(f"updateMask.fieldPaths={k}" for k in fields),
    )
    # innings totals
    for iid, runs, wkts, overs, status in (
        (INN1, sc["team_a_runs"], sc["team_a_wkts"], sc["team_a_overs"], 3),
        (INN2, sc["team_b_runs"], sc["team_b_wkts"], sc["team_b_overs"], 2),
    ):
        f = {
            "total_runs": i(runs),
            "total_wickets": i(wkts),
            "overs": d(overs),
            "innings_status": i(status),
        }
        request(
            "PATCH",
            f"innings/{iid}",
            {"fields": f},
            query="&".join(f"updateMask.fieldPaths={k}" for k in f),
        )
    print(f"Updated match squad XI A={len(ids_a)} B={len(ids_b)}")


def main():
    print("Loading name maps…")
    map_a = load_name_map(ARIYALAI)
    map_b = load_name_map(PHOENIX)
    print("  Ariyalai keys", sorted(set(map_a))[:20])
    print("  Phoenix keys", sorted(set(map_b))[:20])

    start1 = datetime(2026, 11, 22, 3, 9, tzinfo=timezone.utc)
    start2 = datetime(2026, 11, 22, 3, 45, tzinfo=timezone.utc)

    print("Synthesizing innings 1…")
    balls1, perf1 = synthesize_innings(
        SCORE["inn1"], INN1, map_a, map_b, [map_a, map_b], start1
    )
    print(f"  {len(balls1)} balls, {len(perf1)} players")

    print("Synthesizing innings 2…")
    balls2, perf2 = synthesize_innings(
        SCORE["inn2"], INN2, map_b, map_a, [map_a, map_b], start2
    )
    print(f"  {len(balls2)} balls, {len(perf2)} players")

    # Merge performances per team
    # Ariyalai: batting inn1 + bowling inn2 appearances already in perf via resolve
    perf_a: dict[str, list] = {}
    perf_b: dict[str, list] = {}
    for pid, plist in {**perf1, **perf2}.items():
        # determine team
        if pid in map_a.values():
            perf_a.setdefault(pid, []).extend(plist)
        if pid in map_b.values():
            perf_b.setdefault(pid, []).extend(plist)

    delete_existing_balls()
    commit_balls(balls1 + balls2)
    upsert_match_squad(perf_a, perf_b, map_a, map_b)
    print("Done — open match ntl_ch_28435172 scorecard tab to verify.")


if __name__ == "__main__":
    main()
