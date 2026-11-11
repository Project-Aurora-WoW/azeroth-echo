# Azeroth: Echo of the Void

A custom **AzerothCore 3.3.5a** realm (build 12340) with its own storyline, four campaigns, challenge modes, a PvP zone, a store and a unique custom map.

*Русская версия: [Home](Home)*

---

## Quick start

| I want to | Page |
|---|---|
| Install patches and log in | **[Client installation](Client-Install-EN)** |
| Run a server from scratch | **[Server installation](Server-Install-EN)** |
| See what the realm contains | **[Realm content](Realm-Content-EN)** |
| Build the core myself | **[Core build](Core-Build-EN)** |
| Fix a broken setup | **[Troubleshooting](Troubleshooting-EN)** |

---

## Repositories

The project is split into two repositories that complement each other.

| Repository | Contents | Link |
|---|---|---|
| **azeroth-echo** | Content: SQL migrations, Lua scripts, modules, addon, client patches, tools | [Project-Aurora-WoW/azeroth-echo](https://github.com/Project-Aurora-WoW/azeroth-echo) |
| **azeroth-echo-core** | AzerothCore 3.3.5a fork with project modules compiled in | [Project-Aurora-WoW/azeroth-echo-core](https://github.com/Project-Aurora-WoW/azeroth-echo-core) |

How they connect: **[Repositories relation](Repositories-EN)**.

**Releases with ready patches:** [v1.0.0](https://github.com/Project-Aurora-WoW/azeroth-echo/releases/tag/v1.0.0)

---

## Project state

As of 2026-11-11 the server is built, running and verified.

| Component | Status |
|---|---|
| `worldserver.exe` | running, port 8085, `World Initialized` |
| `authserver.exe` | running, port 3724 |
| Databases | `echo_world` (348 tables), `echo_characters` (123), `echo_auth` (22) |
| SOAP | enabled on `127.0.0.1:7878` |
| Modules | 5 active: campaign, archivist, echoes-architecture, stranniki, challenge-modes |
| Client | `patch-x.mpq`, `patch-Z.mpq`, addon `AzerothEcho` |
| In-game login | **not verified** — needs a live client |

---

## Numbers

| Metric | Value |
|---|---|
| Project NPCs | 18 |
| Project items | 14 |
| Campaigns | 4 |
| Lua scripts | 38 |
| C++ modules | 6 |
| `creature_template` rows | 29 991 |
| `item_template` rows | 46 132 |
| Spawns | 150 228 |
| Quests | 9 472 |

---

## Story

The world is fractured by the **Void** — not a force but a state: rifts leave
behind an "echo" that repeats other people's thoughts and deeds. The Order of
Dawn tries to hold order, the Cult of the Abyssal Grin considers the echo a
divine voice, and the Wanderers — those who came from another world — belong
to no one.

Full lore: [`docs/lore/universe.md`](https://github.com/Project-Aurora-WoW/azeroth-echo/blob/main/docs/lore/universe.md).

---

## License

Realm content — by the author's decision. AzerothCore is licensed under GPL-2.0; third-party modules keep their own licenses.
