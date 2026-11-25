#!/usr/bin/env python3
"""Seed Nelliady Titans League (NTL) fixtures/results from CricHeroes into Firestore.

Tournament: tournaments/auction_crickex_6057b0bb
Source: https://cricheroes.com/tournament/2284788/nelliyady-titans-league-ntl

Uses the firebase-tools OAuth access token (same pattern as the SMPL upload).
Idempotent: match docs use stable ids ntl_ch_<cricheroesMatchId>.

Usage:
  python3 khelo/tool/seed_ntl/seed_ntl_from_cricheroes.py
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT = "khelo-hexshankar"
TOURNAMENT_ID = "auction_crickex_6057b0bb"
OWNER = "E5QscYFSIqT29bRqBtnOFmhx9W33"
GROUND = "Colins Sports Ground"
CITY = "Jaffna"
OVERS = 10

# CricHeroes name fragment -> Firestore team id
TEAMS = {
    "VALARMATHY": "auction_crickex_6057b0bb_cx1c2aee",
    "ULTRON": "auction_crickex_6057b0bb_cx4521af",
    "KINGS 11": "auction_crickex_6057b0bb_cx682489",
    "PUTTALAI": "auction_crickex_6057b0bb_cx5eb723",
    "PHOENIX": "auction_crickex_6057b0bb_cxd268f5",
    "PHONIX": "auction_crickex_6057b0bb_cxd268f5",
    "VALLUVAN": "auction_crickex_6057b0bb_cx93fa52",
    "ARIYALAI": "auction_crickex_6057b0bb_cx1ac710",
    "RANGE KINGS": "auction_crickex_6057b0bb_cx5e1a94",
}

# Extracted 22 Nov 2026 from CricHeroes (scores + schedule).
# status: finish=3, running=2, yetToStart=1
MATCHES = [
    # Completed 21 Nov
    {
        "ch_id": "28403919",
        "number": 1,
        "status": 3,
        "start": "2026-11-21T10:27:00Z",
        "a": "VALLUVAN",
        "b": "ARIYALAI",
        "inn": [
            {"side": "a", "runs": 78, "wkts": 9, "overs": 10.0},
            {"side": "b", "runs": 84, "wkts": 2, "overs": 9.2},
        ],
        "winner": "b",
        "margin": "8 wickets",
    },
    {
        "ch_id": "28403904",
        "number": 2,
        "status": 3,
        "start": "2026-11-21T11:30:00Z",
        "a": "ULTRON",
        "b": "KINGS 11",
        "inn": [
            {"side": "a", "runs": 99, "wkts": 6, "overs": 10.0},
            {"side": "b", "runs": 52, "wkts": 10, "overs": 8.2},
        ],
        "winner": "a",
        "margin": "47 runs",
    },
    {
        "ch_id": "28403888",
        "number": 3,
        "status": 3,
        "start": "2026-11-21T12:30:00Z",
        "a": "VALARMATHY",
        "b": "RANGE KINGS",
        "inn": [
            {"side": "a", "runs": 84, "wkts": 8, "overs": 10.0},
            {"side": "b", "runs": 65, "wkts": 9, "overs": 10.0},
        ],
        "winner": "a",
        "margin": "19 runs",
    },
    {
        "ch_id": "28403870",
        "number": 4,
        "status": 3,
        "start": "2026-11-21T13:30:00Z",
        "a": "VALLUVAN",
        "b": "PUTTALAI",
        "inn": [
            {"side": "a", "runs": 56, "wkts": 9, "overs": 10.0},
            {"side": "b", "runs": 58, "wkts": 8, "overs": 9.5},
        ],
        "winner": "b",
        "margin": "2 wickets",
    },
    {
        "ch_id": "28403856",
        "number": 5,
        "status": 3,
        "start": "2026-11-21T14:30:00Z",
        "a": "PHOENIX",
        "b": "ULTRON",
        "inn": [
            {"side": "a", "runs": 38, "wkts": 8, "overs": 10.0},
            {"side": "b", "runs": 41, "wkts": 1, "overs": 4.0},
        ],
        "winner": "b",
        "margin": "9 wickets",
    },
    {
        "ch_id": "28403845",
        "number": 6,
        "status": 3,
        "start": "2026-11-21T15:30:00Z",
        "a": "ARIYALAI",
        "b": "VALARMATHY",
        "inn": [
            {"side": "a", "runs": 106, "wkts": 6, "overs": 10.0},
            {"side": "b", "runs": 85, "wkts": 8, "overs": 10.0},
        ],
        "winner": "a",
        "margin": "21 runs",
    },
    {
        "ch_id": "28403828",
        "number": 7,
        "status": 3,
        "start": "2026-11-21T16:30:00Z",
        "a": "KINGS 11",
        "b": "RANGE KINGS",
        "inn": [
            {"side": "a", "runs": 67, "wkts": 8, "overs": 10.0},
            {"side": "b", "runs": 73, "wkts": 1, "overs": 8.1},
        ],
        "winner": "b",
        "margin": "9 wickets",
    },
    # Live 22 Nov (snapshot at seed time)
    {
        "ch_id": "28435172",
        "number": 8,
        "status": 2,
        "start": "2026-11-22T03:09:00Z",
        "a": "ARIYALAI",
        "b": "PHOENIX",
        "inn": [
            {"side": "a", "runs": 116, "wkts": 5, "overs": 10.0},
            {"side": "b", "runs": 57, "wkts": 2, "overs": 5.0},
        ],
        "winner": None,
        "margin": None,
        "toss_field": True,  # Phoenix won toss and elected to field
    },
    # Upcoming 22 Nov (IST times → UTC)
    {
        "ch_id": "28419481",
        "number": 9,
        "status": 1,
        "start": "2026-11-22T03:00:00Z",
        "a": "PHOENIX",
        "b": "ARIYALAI",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419498",
        "number": 10,
        "status": 1,
        "start": "2026-11-22T04:00:00Z",
        "a": "VALLUVAN",
        "b": "RANGE KINGS",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419510",
        "number": 11,
        "status": 1,
        "start": "2026-11-22T05:10:00Z",
        "a": "PHOENIX",
        "b": "PUTTALAI",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419537",
        "number": 12,
        "status": 1,
        "start": "2026-11-22T06:20:00Z",
        "a": "KINGS 11",
        "b": "VALLUVAN",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419578",
        "number": 13,
        "status": 1,
        "start": "2026-11-22T07:50:00Z",
        "a": "RANGE KINGS",
        "b": "ARIYALAI",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419599",
        "number": 14,
        "status": 1,
        "start": "2026-11-22T08:50:00Z",
        "a": "KINGS 11",
        "b": "PUTTALAI",
        "inn": [],
        "winner": None,
        "margin": None,
    },
    {
        "ch_id": "28419613",
        "number": 15,
        "status": 1,
        "start": "2026-11-22T10:00:00Z",
        "a": "VALARMATHY",
        "b": "ULTRON",
        "inn": [],
        "winner": None,
        "margin": None,
    },
]


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
        raise SystemExit(f"{method} {path} -> {e.code} {e.read()[:400]}") from e


def s(v: str):
    return {"stringValue": v}


def i(v: int):
    return {"integerValue": str(int(v))}


def d(v: float):
    return {"doubleValue": float(v)}


def b(v: bool):
    return {"booleanValue": bool(v)}


def ts(iso: str):
    return {"timestampValue": iso}


def null():
    return {"nullValue": None}


def arr(values: list):
    return {"arrayValue": {"values": values}} if values else {"arrayValue": {}}


def mmap(fields: dict):
    return {"mapValue": {"fields": fields}}


def cricket_overs_to_balls(overs: float) -> int:
    whole = int(overs)
    balls = int(round((overs - whole) * 10))
    return whole * 6 + balls


def balls_to_decimal_overs(balls: int) -> float:
    return balls / 6.0 if balls else 0.0


def load_rosters() -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for tid in set(TEAMS.values()):
        doc = request("GET", f"teams/{tid}")
        players = []
        for p in (
            doc.get("fields", {})
            .get("team_players", {})
            .get("arrayValue", {})
            .get("values", [])
            or []
        ):
            players.append(p["mapValue"]["fields"]["id"]["stringValue"])
        out[tid] = players
    return out


def squad_values(player_ids: list[str]):
    return [
        mmap({"id": s(pid), "status": i(3), "performance": arr([])})
        for pid in player_ids
    ]


def team_entry(team_id: str, players: list[str], runs=0, wkts=0, overs=0.0):
    return mmap(
        {
            "team_id": s(team_id),
            "captain_id": null(),
            "admin_id": null(),
            "run": i(runs),
            "wicket": i(wkts),
            "over": d(overs),
            "squad": arr(squad_values(players)),
        }
    )


def rules_field():
    return mmap(
        {
            "balls_per_over": i(6),
            "wide_runs": i(1),
            "wide_rebowl": b(True),
            "no_ball_runs": i(1),
            "free_hit": b(True),
            "last_man_standing": b(False),
        }
    )


def build_match(m: dict, rosters: dict[str, list[str]]) -> tuple[str, dict]:
    mid = f"ntl_ch_{m['ch_id']}"
    tid_a = TEAMS[m["a"]]
    tid_b = TEAMS[m["b"]]
    pa = rosters[tid_a]
    pb = rosters[tid_b]
    score = {x["side"]: x for x in m["inn"]}
    sa = score.get("a", {"runs": 0, "wkts": 0, "overs": 0.0})
    sb = score.get("b", {"runs": 0, "wkts": 0, "overs": 0.0})

    first_bat = tid_a
    second_bat = tid_b
    toss_winner = first_bat
    toss_decision = 1  # bat
    if m.get("toss_field"):
        toss_winner = tid_b
        toss_decision = 2  # bowl

    current = None
    if m["status"] == 2:
        # chasing side batting
        current = second_bat if len(m["inn"]) >= 2 else first_bat
    elif m["status"] == 3:
        current = second_bat

    fields = {
        "id": s(mid),
        "tournament_id": s(TOURNAMENT_ID),
        "created_by": s(OWNER),
        "city": s(CITY),
        "ground": s(GROUND),
        "match_type": i(1),
        "ball_type": i(1),
        "pitch_type": i(3),
        "number_of_over": i(OVERS),
        "over_per_bowler": i(2),
        "match_status": i(m["status"]),
        "match_group": i(1),
        "match_group_number": i(1),
        "match_number": i(m["number"]),
        "stage": s("League"),
        "team_ids": arr([s(tid_a), s(tid_b)]),
        "team_creator_ids": arr([s(OWNER)]),
        "players": arr([s(p) for p in pa + pb]),
        "teams": arr(
            [
                team_entry(tid_a, pa, sa["runs"], sa["wkts"], sa["overs"]),
                team_entry(tid_b, pb, sb["runs"], sb["wkts"], sb["overs"]),
            ]
        ),
        "start_at": ts(m["start"]),
        "start_time": s(m["start"].replace("Z", ".000Z")),
        "updated_at": ts(datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")),
        "power_play_overs1": arr([]),
        "power_play_overs2": arr([]),
        "power_play_overs3": arr([]),
        "umpire_ids": null(),
        "scorer_ids": null(),
        "commentator_ids": null(),
        "referee_id": null(),
        "revised_target": null(),
        "rules": rules_field(),
    }
    if m["status"] in (2, 3):
        fields["toss_winner_id"] = s(toss_winner)
        fields["toss_decision"] = i(toss_decision)
        fields["current_playing_team_id"] = s(current or second_bat)
    if m.get("margin"):
        winner_key = m["winner"]
        winner_name = m["a"] if winner_key == "a" else m["b"]
        # Store as "N wickets" / "N runs" like SMPL ("2 runs")
        fields["result_margin"] = s(m["margin"])

    return mid, {"fields": fields}


def build_innings(mid: str, m: dict) -> list[tuple[str, dict]]:
    if not m["inn"]:
        return []
    tid_a = TEAMS[m["a"]]
    tid_b = TEAMS[m["b"]]
    out = []
    for idx, inn in enumerate(m["inn"], start=1):
        team_id = tid_a if inn["side"] == "a" else tid_b
        iid = f"{mid}_inn{idx}"
        # For live match, innings 1 finished, innings 2 running
        if m["status"] == 3:
            status = 3
        elif m["status"] == 2:
            status = 3 if idx == 1 else 2
        else:
            status = 1
        fields = {
            "id": s(iid),
            "match_id": s(mid),
            "team_id": s(team_id),
            "index": i(idx),
            "total_runs": i(inn["runs"]),
            "total_wickets": i(inn["wkts"]),
            "overs": d(inn["overs"]),
            "innings_status": i(status),
        }
        out.append((iid, {"fields": fields}))
    return out


def compute_team_stats(rosters_keys: list[str]) -> dict[str, dict]:
    stats = {
        tid: {
            "team_id": tid,
            "played_matches": 0,
            "wins": 0,
            "losses": 0,
            "points": 0,
            "runs_for": 0,
            "balls_for": 0,
            "runs_against": 0,
            "balls_against": 0,
        }
        for tid in rosters_keys
    }
    for m in MATCHES:
        if m["status"] != 3:
            continue
        tid_a = TEAMS[m["a"]]
        tid_b = TEAMS[m["b"]]
        sa = next(x for x in m["inn"] if x["side"] == "a")
        sb = next(x for x in m["inn"] if x["side"] == "b")
        for tid, mine, opp in (
            (tid_a, sa, sb),
            (tid_b, sb, sa),
        ):
            st = stats[tid]
            st["played_matches"] += 1
            st["runs_for"] += mine["runs"]
            st["balls_for"] += cricket_overs_to_balls(mine["overs"])
            st["runs_against"] += opp["runs"]
            st["balls_against"] += cricket_overs_to_balls(opp["overs"])
        winner = tid_a if m["winner"] == "a" else tid_b
        loser = tid_b if winner == tid_a else tid_a
        stats[winner]["wins"] += 1
        stats[winner]["points"] += 2
        stats[loser]["losses"] += 1

    for st in stats.values():
        rf = st["runs_for"] / balls_to_decimal_overs(st["balls_for"]) if st["balls_for"] else 0
        ra = (
            st["runs_against"] / balls_to_decimal_overs(st["balls_against"])
            if st["balls_against"]
            else 0
        )
        st["nrr"] = round(rf - ra, 6)
        for k in ("runs_for", "balls_for", "runs_against", "balls_against"):
            del st[k]
    return stats


def upsert(path: str, doc: dict):
    # PATCH creates if missing when using updateMask? Use PATCH with all fields via commit-style:
    # documents:commit with update + exists false / true. Simpler: PATCH without mask replaces? 
    # Firestore PATCH with updateMask only updates listed fields. Use write via :documents
    # with currentDocument exists optional via create then patch.
    # Easiest reliable: DELETE not needed — use PATCH with updateMask listing all field paths
    fields = doc["fields"]
    mask = "&".join(f"updateMask.fieldPaths={k}" for k in fields.keys())
    request("PATCH", path, doc, query=mask)


def main():
    print("Loading rosters…")
    rosters = load_rosters()
    for tid, ps in rosters.items():
        print(f"  {tid}: {len(ps)} players")

    match_ids = []
    print("Writing matches + innings…")
    for m in MATCHES:
        mid, mdoc = build_match(m, rosters)
        upsert(f"matches/{mid}", mdoc)
        match_ids.append(mid)
        for iid, idoc in build_innings(mid, m):
            upsert(f"innings/{iid}", idoc)
        print(f"  {mid} status={m['status']} #{m['number']}")

    print("Updating tournament…")
    now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    tdoc = {
        "fields": {
            "match_ids": arr([s(x) for x in match_ids]),
            "schedule_status": s("scheduled"),
            "start_date": ts("2026-11-21T03:00:00Z"),
            "end_date": ts("2026-12-21T14:30:00Z"),
            "name": s("Nelliady Titans League"),
        }
    }
    request(
        "PATCH",
        f"tournaments/{TOURNAMENT_ID}",
        tdoc,
        query="&".join(
            f"updateMask.fieldPaths={k}"
            for k in ("match_ids", "schedule_status", "start_date", "end_date", "name")
        ),
    )

    print("Writing team_stats…")
    stats = compute_team_stats(list(set(TEAMS.values())))
    for tid, st in stats.items():
        upsert(
            f"tournaments/{TOURNAMENT_ID}/team_stats/{tid}",
            {
                "fields": {
                    "team_id": s(st["team_id"]),
                    "played_matches": i(st["played_matches"]),
                    "wins": i(st["wins"]),
                    "losses": i(st["losses"]),
                    "points": i(st["points"]),
                    "nrr": d(st["nrr"]),
                }
            },
        )
        print(
            f"  {tid[-8:]} P{st['played_matches']} W{st['wins']} "
            f"L{st['losses']} Pts{st['points']} NRR{st['nrr']:+.3f}"
        )

    print(f"Done. {len(match_ids)} matches seeded into {TOURNAMENT_ID}")
    Path("/tmp/ntl_seed_result.json").write_text(
        json.dumps({"match_ids": match_ids, "team_stats": stats}, indent=2)
    )


if __name__ == "__main__":
    main()
