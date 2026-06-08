"""Cinephile MCP — movie discovery, fan club, wishlist, seenlist, custom lists.

Bundle ID: ``com.iosworld.benchmark.cinephile``.

ID conventions used by tools below:
* Tabs: ``cinephile_tab_movies``, ``cinephile_tab_discover``,
  ``cinephile_tab_fan_club``, ``cinephile_tab_my_lists`` (display names
  ``Movies``, ``Discover``, ``Fan Club``, ``My Lists`` also work).
* Movie list rows: ``cinephile_movie_row_<tmdb_id>`` where ``<tmdb_id>``
  is the integer TMDB id (e.g. ``238`` for The Godfather).
* Detail-view buttons appear by label: ``Wishlist`` / ``In wishlist``,
  ``Seen`` (already seen) / ``Seenlist`` (not yet seen).

Cinephile uses SwiftUIFlux (Redux-style); some state mutations go through
action dispatch and UI reflects them only after the next render.
"""

import os, sys, pathlib, re, json, subprocess
from typing import Optional
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from fastmcp import FastMCP
from simulator_base import SimulatorBridge
import tool_support as ts
import _data_layer as dl

mcp = FastMCP("Cinephile")

BUNDLE_ID = "com.iosworld.benchmark.cinephile"

# Canonical title->TMDB-id catalog. Sourced from the app's
# discoverSeedMovies (MoviesState.swift) plus the IDs referenced by the
# seeded wishlist/seenlist so title lookups resolve every movie the app
# can actually display. Keys are case-insensitive titles; aliases included
# for common shorthand. Cinephile persists MoviesState (incl. seenlist)
# as JSON at Documents/userData inside the app container — NOT in
# UserDefaults — so resolving title->id here lets mark_seen/search operate
# against the real store.
CATALOG = {
    238: "The Godfather",
    27205: "Inception",
    155: "The Dark Knight",
    278: "The Shawshank Redemption",
    680: "Pulp Fiction",
    157336: "Interstellar",
    496243: "Parasite",
    438631: "Dune",
    313369: "La La Land",
    244786: "Whiplash",
    666277: "Past Lives",
    419430: "Get Out",
}

# Default seenlist/wishlist shipped in MoviesState() — used to seed the
# persisted-state file when it does not yet exist (fresh app, never
# archived), so a mark_seen write starts from the real baseline.
_SEED_SEENLIST = [238, 27205, 155, 313369, 244786, 278]
_SEED_WISHLIST = [438631, 666277, 496243]

# Full Movie metadata for every catalog id. The app's My Lists screen only
# RENDERS a wishlist/seenlist entry when its id is present (with complete,
# Codable-decodable metadata) in moviesState.movies — see
# Collection.sortedMoviesIds which filters by `movies.contains(id)`. A
# partial movie object fails to decode (Movie has several non-optional
# fields), so a mark_seen/wishlist write that only stores {id,title} would
# persist but NOT appear in the UI. We therefore write the COMPLETE record
# here so the change is observable. Values mirror discoverSeedMovies
# (MoviesState.swift) plus real TMDB data for the four ids that ship only
# in the seeded wishlist/seenlist (313369, 244786, 666277, 419430).
_MOVIE_META = {
    238: dict(id=238, original_title="The Godfather", title="The Godfather",
              overview="Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family.",
              poster_path="/3bhkrj58Vtu7enYsLMdL73KsPyd.jpg", backdrop_path="/tmU7GeKVPlXMVvEOKGAKX1HfAzp.jpg",
              popularity=110.9, vote_average=8.7, vote_count=18300, release_date="1972-03-14",
              genres=[{"id": 18, "name": "Drama"}, {"id": 80, "name": "Crime"}], runtime=175, status="Released", video=False),
    27205: dict(id=27205, original_title="Inception", title="Inception",
                overview="A thief who steals corporate secrets through the use of dream-sharing technology.",
                poster_path="/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg", backdrop_path="/s3TBrRGB1iav7gFOCNx3H31MoES.jpg",
                popularity=95.0, vote_average=8.4, vote_count=34000, release_date="2010-07-15",
                genres=[{"id": 28, "name": "Action"}, {"id": 878, "name": "Science Fiction"}], runtime=148, status="Released", video=False),
    155: dict(id=155, original_title="The Dark Knight", title="The Dark Knight",
              overview="Batman raises the stakes in his war on crime by pursuing the Joker.",
              poster_path="/qJ2tW6WMUDux911r6m7haRef0WH.jpg", backdrop_path="/hqkIcbrOHL86UncnHIsHVcVmzue.jpg",
              popularity=112.0, vote_average=8.5, vote_count=29000, release_date="2008-07-18",
              genres=[{"id": 28, "name": "Action"}, {"id": 80, "name": "Crime"}], runtime=152, status="Released", video=False),
    278: dict(id=278, original_title="The Shawshank Redemption", title="The Shawshank Redemption",
              overview="Framed in the 1940s for the double murder of his wife and her lover, upstanding banker Andy Dufresne begins a new life at the Shawshank prison.",
              poster_path="/lyQBXzOQSuE59IsHyhrp0qIiPAz.jpg", backdrop_path="/j9XKiZrVeViAixVRzCta7h1VU9W.jpg",
              popularity=90.0, vote_average=8.7, vote_count=23000, release_date="1994-09-23",
              genres=[{"id": 18, "name": "Drama"}, {"id": 80, "name": "Crime"}], runtime=142, status="Released", video=False),
    680: dict(id=680, original_title="Pulp Fiction", title="Pulp Fiction",
              overview="A burger-loving hit man, his philosophical partner, a drug-addled gangster's moll and a washed-up boxer converge in this sprawling, comedic crime caper.",
              poster_path="/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg", backdrop_path="/4cDFJr4HnXN5AdPw4AKrmLlMWdO.jpg",
              popularity=88.0, vote_average=8.5, vote_count=24000, release_date="1994-09-10",
              genres=[{"id": 18, "name": "Drama"}, {"id": 80, "name": "Crime"}], runtime=154, status="Released", video=False),
    157336: dict(id=157336, original_title="Interstellar", title="Interstellar",
                 overview="A team of explorers travel through a wormhole in space in an attempt to ensure humanity's survival.",
                 poster_path="/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg", backdrop_path="/xu9zaAevzQ5nnrsXN6JcahLnG4i.jpg",
                 popularity=105.0, vote_average=8.4, vote_count=31000, release_date="2014-11-05",
                 genres=[{"id": 12, "name": "Adventure"}, {"id": 878, "name": "Science Fiction"}], runtime=169, status="Released", video=False),
    496243: dict(id=496243, original_title="기생충", title="Parasite",
                 overview="All unemployed, Ki-taek's family takes peculiar interest in the wealthy and glamorous Parks.",
                 poster_path="/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg", backdrop_path="/TU9NIjwzjoKPwQHoHshkFcQUCG.jpg",
                 popularity=92.0, vote_average=8.5, vote_count=15000, release_date="2019-05-30",
                 genres=[{"id": 35, "name": "Comedy"}, {"id": 18, "name": "Drama"}], runtime=132, status="Released", video=False),
    438631: dict(id=438631, original_title="Dune", title="Dune",
                 overview="Paul Atreides, a brilliant and gifted young man born into a great destiny beyond his understanding, must travel to the most dangerous planet in the universe.",
                 poster_path="/d5NXSklpcvkCgnJQ3kYAtAR9lgu.jpg", backdrop_path="/jYEW5xZkZk2WTrdbMGAPFuBqbDc.jpg",
                 popularity=98.0, vote_average=7.8, vote_count=11000, release_date="2021-09-15",
                 genres=[{"id": 878, "name": "Science Fiction"}, {"id": 12, "name": "Adventure"}], runtime=155, status="Released", video=False),
    313369: dict(id=313369, original_title="La La Land", title="La La Land",
                 overview="Mia, an aspiring actress, and Sebastian, a dedicated jazz musician, struggle to make ends meet while pursuing their dreams in a city known for crushing hopes and breaking hearts.",
                 poster_path="/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg", backdrop_path="/nlPCdZlHtRNcF6C9hzUH4ngbFimg.jpg",
                 popularity=80.0, vote_average=7.9, vote_count=15000, release_date="2016-11-29",
                 genres=[{"id": 35, "name": "Comedy"}, {"id": 18, "name": "Drama"}, {"id": 10402, "name": "Music"}], runtime=129, status="Released", video=False),
    244786: dict(id=244786, original_title="Whiplash", title="Whiplash",
                 overview="Under the direction of a ruthless instructor, a talented young drummer begins to pursue perfection at any cost, even his humanity.",
                 poster_path="/7fn624j5lj3xTme2SgiLCeuedmO.jpg", backdrop_path="/6bbZ6XyvgfjhQwbplnUh1LSj1ky.jpg",
                 popularity=70.0, vote_average=8.4, vote_count=14000, release_date="2014-10-10",
                 genres=[{"id": 18, "name": "Drama"}, {"id": 10402, "name": "Music"}], runtime=107, status="Released", video=False),
    666277: dict(id=666277, original_title="Past Lives", title="Past Lives",
                 overview="Nora and Hae Sung, two deeply connected childhood friends, are wrested apart after Nora's family emigrates from South Korea.",
                 poster_path="/k3waqVXSnvCZWfJYNtdamTgTtTm.jpg", backdrop_path="/yMVPyM4qNLLuvkGFv0pX9Ml6JVU.jpg",
                 popularity=60.0, vote_average=7.8, vote_count=5000, release_date="2023-06-02",
                 genres=[{"id": 18, "name": "Drama"}, {"id": 10749, "name": "Romance"}], runtime=106, status="Released", video=False),
    419430: dict(id=419430, original_title="Get Out", title="Get Out",
                 overview="Chris and his girlfriend Rose go upstate to visit her parents for the weekend. At first, Chris reads the family's overly accommodating behavior as nervous attempts to deal with their daughter's interracial relationship, but as the weekend progresses, a series of increasingly disturbing discoveries lead him to a truth he never could have imagined.",
                 poster_path="/tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg", backdrop_path="/upQqAGyParg5b9gMP1ad5IVbZqu.jpg",
                 popularity=65.0, vote_average=7.6, vote_count=18000, release_date="2017-02-24",
                 genres=[{"id": 27, "name": "Horror"}, {"id": 9648, "name": "Mystery"}, {"id": 53, "name": "Thriller"}], runtime=104, status="Released", video=False),
}


def _movie_record(movie_id: int) -> dict:
    """Full Codable Movie dict for *movie_id* (falls back to a minimal-but-valid record)."""
    if movie_id in _MOVIE_META:
        return dict(_MOVIE_META[movie_id])
    title = CATALOG.get(movie_id, f"Movie {movie_id}")
    return {"id": movie_id, "original_title": title, "title": title,
            "overview": "", "poster_path": None, "backdrop_path": None,
            "popularity": 0.0, "vote_average": 0.0, "vote_count": 0,
            "release_date": None, "genres": [], "runtime": None,
            "status": None, "video": False}

# Extra title aliases -> id for substring/shorthand matching.
_TITLE_ALIASES = {
    "godfather": 238,
    "dark knight": 155,
    "shawshank": 278,
    "the shawshank redemption": 278,
    "기생충": 496243,
}

# Legacy name retained for the ablation flag below.
_SEARCH_FALLBACK_IDS = {t.lower(): [mid] for mid, t in CATALOG.items()}
_SEARCH_FALLBACK_IDS.update({a: [mid] for a, mid in _TITLE_ALIASES.items()})


def title_to_id(query: str) -> Optional[int]:
    """Resolve a free-text title to a TMDB id via CATALOG (case-insensitive).

    Exact title match wins; otherwise the first catalog title that contains
    the query (or that the query contains) is returned. Aliases are also
    consulted. Returns None when nothing matches.
    """
    q = (query or "").strip().lower()
    if not q:
        return None
    for mid, t in CATALOG.items():
        if t.lower() == q:
            return mid
    if q in _TITLE_ALIASES:
        return _TITLE_ALIASES[q]
    for mid, t in CATALOG.items():
        tl = t.lower()
        if q in tl or tl in q:
            return mid
    for a, mid in _TITLE_ALIASES.items():
        if q in a or a in q:
            return mid
    return None


def search_catalog(query: str) -> list:
    """Return all catalog (id, title) pairs whose title contains the query.

    Case-insensitive substring match over CATALOG titles + aliases. Empty
    query returns []. Aliases that hit fold into their canonical id.
    """
    q = (query or "").strip().lower()
    if not q:
        return []
    hits = {}
    for mid, t in CATALOG.items():
        if q in t.lower():
            hits[mid] = t
    for a, mid in _TITLE_ALIASES.items():
        if q in a:
            hits.setdefault(mid, CATALOG.get(mid, a))
    return [{"movie_id": mid, "title": t} for mid, t in sorted(hits.items())]


def _userdata_path() -> Optional[pathlib.Path]:
    """Locate the app's persisted-state JSON file (Documents/userData).

    Cinephile (SwiftUIFlux) archives AppState — including
    moviesState.seenlist/wishlist — to ``Documents/userData`` as JSON.
    Returns the path (which may not yet exist) or None if the data
    container can't be resolved.
    """
    udid = dl._udid()
    try:
        cont = subprocess.run(
            ["xcrun", "simctl", "get_app_container", udid, BUNDLE_ID, "data"],
            capture_output=True, text=True, timeout=15,
        )
        if cont.returncode != 0:
            return None
        return pathlib.Path(cont.stdout.strip()) / "Documents" / "userData"
    except Exception:
        return None


def _default_state() -> dict:
    """Build a fresh persisted AppState matching the app's seed defaults.

    Used when Documents/userData does not exist yet (the app hasn't
    archived). Mirrors the Codable shape the app decodes: moviesState with
    seenlist/wishlist/movies (only the keys in AppState.CodingKeys matter).
    """
    movies = {}
    for mid in set(_SEED_SEENLIST) | set(_SEED_WISHLIST):
        movies[str(mid)] = _movie_record(mid)
    return {
        "moviesState": {
            "movies": movies,
            "seenlist": sorted(set(_SEED_SEENLIST)),
            "wishlist": sorted(set(_SEED_WISHLIST)),
            "customLists": {},
            "moviesUserMeta": {},
            "savedDiscoverFilters": [],
        },
        "peoplesState": {"peoples": {}, "fanClub": []},
    }


def _read_state() -> tuple[Optional[dict], Optional[pathlib.Path]]:
    """Read the persisted AppState JSON, seeding defaults if absent.

    Returns (state, path). If the file is missing we synthesize the seed
    state (so a write begins from the real baseline). Returns (None, path)
    only if the container itself can't be resolved.
    """
    path = _userdata_path()
    if path is None:
        return None, None
    if not path.exists():
        return _default_state(), path
    try:
        return json.loads(path.read_bytes()), path
    except Exception:
        return _default_state(), path


def _seenlist_set(query: str, add: bool) -> dict:
    """Add/remove a movie (by title or id) in the persisted seenlist.

    Resolves *query* to a TMDB id via the catalog, mutates
    moviesState.seenlist in the on-disk userData JSON, ensures the movie
    metadata exists in moviesState.movies (so the archived state stays
    self-consistent and the app keeps the row), writes it back, and reloads
    the app so the UI re-renders from the new state.
    """
    qs = str(query).strip()
    movie_id = int(qs) if qs.isdigit() else title_to_id(qs)
    if movie_id is None:
        return {"ok": False, "action": "mark_seen",
                "message": f"Could not resolve '{query}' to a movie. Known titles: "
                           + ", ".join(sorted(CATALOG.values()))}
    state, path = _read_state()
    if state is None:
        return {"ok": False, "action": "mark_seen",
                "message": "Could not resolve the cinephile data container."}
    ms = state.setdefault("moviesState", {})
    seen = ms.get("seenlist")
    seen_set = set(seen) if isinstance(seen, list) else set()
    changed = False
    if add and movie_id not in seen_set:
        seen_set.add(movie_id); changed = True
    elif not add and movie_id in seen_set:
        seen_set.discard(movie_id); changed = True
    ms["seenlist"] = sorted(seen_set)
    movies = ms.setdefault("movies", {})
    # Ensure COMPLETE metadata exists so the My Lists row actually renders
    # (the app filters list entries by movies.contains(id) and force-unwraps
    # the Movie, so a partial record is invisible / unsafe).
    if str(movie_id) not in movies:
        movies[str(movie_id)] = _movie_record(movie_id)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(state))
    except Exception as e:
        return {"ok": False, "action": "mark_seen",
                "message": f"Failed to write persisted state: {e}"}
    try:
        dl.reload_app(BUNDLE_ID)
    except Exception:
        pass
    return {
        "ok": True,
        "action": "mark_seen",
        "movie_id": movie_id,
        "title": CATALOG.get(movie_id),
        "in_seenlist": movie_id in seen_set,
        "changed": changed,
        "seenlist": ms["seenlist"],
    }


def _wishlist_set(query: str, add: bool) -> dict:
    """Add/remove a movie (by title or id) in the persisted wishlist.

    Mirror of ``_seenlist_set`` for ``moviesState.wishlist``. SwiftUIFlux
    dispatches the wishlist toggle in-memory and only archives to
    ``Documents/userData`` on its own schedule, so a UI tap alone is not a
    durable state change. This writes ``moviesState.wishlist`` directly to
    the archived JSON (ensuring the movie metadata exists) and reloads the
    app so the change is real and observable. Returns a normal envelope.
    """
    qs = str(query).strip()
    movie_id = int(qs) if qs.isdigit() else title_to_id(qs)
    if movie_id is None:
        return {"ok": False, "action": "wishlist",
                "message": f"Could not resolve '{query}' to a movie. Known titles: "
                           + ", ".join(sorted(CATALOG.values()))}
    state, path = _read_state()
    if state is None:
        return {"ok": False, "action": "wishlist",
                "message": "Could not resolve the cinephile data container."}
    ms = state.setdefault("moviesState", {})
    wish = ms.get("wishlist")
    wish_set = set(wish) if isinstance(wish, list) else set()
    changed = False
    if add and movie_id not in wish_set:
        wish_set.add(movie_id); changed = True
    elif not add and movie_id in wish_set:
        wish_set.discard(movie_id); changed = True
    ms["wishlist"] = sorted(wish_set)
    movies = ms.setdefault("movies", {})
    if str(movie_id) not in movies:
        movies[str(movie_id)] = _movie_record(movie_id)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(state))
    except Exception as e:
        return {"ok": False, "action": "wishlist",
                "message": f"Failed to write persisted state: {e}"}
    try:
        dl.reload_app(BUNDLE_ID)
    except Exception:
        pass
    return {
        "ok": True,
        "action": "wishlist",
        "movie_id": movie_id,
        "title": CATALOG.get(movie_id),
        "in_wishlist": movie_id in wish_set,
        "changed": changed,
        "wishlist": ms["wishlist"],
    }

_TAB_MAP = {
    # SwiftUI TabView: try the explicit accessibility id, then fall back
    # to the tabItem's Text label (for older builds where the id didn't
    # propagate to the tab bar button).
    "movies":   ["cinephile_tab_movies", "Movies"],
    "discover": ["cinephile_tab_discover", "Discover"],
    "fan club": ["cinephile_tab_fan_club", "Fan Club"],
    "fanclub":  ["cinephile_tab_fan_club", "Fan Club"],
    "fan_club": ["cinephile_tab_fan_club", "Fan Club"],
    "my lists": ["cinephile_tab_my_lists", "My Lists"],
    "lists":    ["cinephile_tab_my_lists", "My Lists"],
    "my_lists": ["cinephile_tab_my_lists", "My Lists"],
}


@mcp.tool()
def launch() -> str:
    """Launch Cinephile and return the post-launch accessibility tree."""
    sim = SimulatorBridge.get()
    ui = sim.launch_and_observe(BUNDLE_ID)
    return f"Launched Cinephile.\n\n{ui}"


@mcp.tool()
def observe() -> str:
    """Return the current UI accessibility tree as text (no navigation)."""
    return ts.observe_app_scoped(
        SimulatorBridge.get(),
        bundle_id=BUNDLE_ID,
        app_name="Cinephile",
        markers=("cinephile_", "movie_row_", "seenlist", "wishlist"),
    )


@mcp.tool()
def navigate_to_tab(tab: str) -> str:
    """Switch to one of the four bottom-bar tabs. Works from any screen —
    self-navigates by first popping any pushed detail/editor overlay (which
    would otherwise cover the tab bar) before tapping, then verifies the tab
    actually became selected.

    Args:
        tab: Tab slug, case-insensitive. Valid: ``movies``, ``discover``,
            ``fan_club`` (also ``fan club``/``fanclub``), ``my_lists`` (also
            ``my lists``/``lists``). The display names ``Movies``/``Discover``/
            ``Fan Club``/``My Lists`` also resolve. Any other value returns an
            error string (ok:false) and does not navigate.

    Returns a confirmation string only after the target tab is confirmed
    selected; returns an error string if the tab never became selected.
    """
    candidates = _TAB_MAP.get(tab.strip().lower())
    if candidates is None:
        # Failure-prefix-compatible so the wrapper marks ok:false (no false
        # positive on a typo'd tab name).
        return f"Could not switch tabs: unknown tab '{tab}'. Use: movies, discover, fan_club, my_lists."
    sim = SimulatorBridge.get()
    # The canonical accessibility id is the reliable verification anchor; the
    # selected tab button carries value="1" in the tree.
    canonical = candidates[0]
    # Bug-class 2: a pushed detail/editor overlay can cover the tab bar; pop
    # it first so the tap actually lands and the tab switches.
    _dismiss_overlays(sim)
    last_err = None
    for aid in candidates:
        try:
            sim.tap_id(aid); sim.wait(0.5)
        except Exception as e:
            last_err = e
            continue
        # Verify against a marker that ACTUALLY renders: the selected tab
        # button gains value="1". Confirm the effect before reporting ok.
        tree = sim.observe_text() or ""
        if re.search(
            r'<XCUIElementTypeButton[^>]*\bvalue="1"[^>]*\bname="'
            + re.escape(canonical) + r'"'
            r'|<XCUIElementTypeButton[^>]*\bname="' + re.escape(canonical)
            + r'"[^>]*\bvalue="1"',
            tree,
        ):
            return f"Switched to '{tab}' (via {aid}, confirmed selected)."
        # Tap landed but selection not confirmed yet; retry settle once.
        sim.wait(0.4)
        tree = sim.observe_text() or ""
        if re.search(
            r'<XCUIElementTypeButton[^>]*\bname="' + re.escape(canonical)
            + r'"[^>]*\bvalue="1"'
            r'|<XCUIElementTypeButton[^>]*\bvalue="1"[^>]*\bname="'
            + re.escape(canonical) + r'"',
            tree,
        ):
            return f"Switched to '{tab}' (via {aid}, confirmed selected)."
    return (f"Could not switch to '{tab}'. Tried {candidates}; tab did not "
            f"become selected. Last error: {str(last_err)[:120]}")


@mcp.tool()
def search(query: str) -> dict:
    """Search the movie catalog by title (case-insensitive substring).

    Args:
        query: Free-text title (e.g. ``"Inception"``, ``"dark"``,
            ``"Parasite"``). Empty strings produce no matches.

    Returns ``{ok, action, query, results: [{movie_id, title}...],
    movie_ids: [...], count, source}``. Matching is done authoritatively
    against the app catalog so it works regardless of whether the on-screen
    search field can be focused; a best-effort UI type is still attempted so
    the visible list filters when possible.

    Each resolved ``movie_id`` (or the title itself) is a valid argument for
    ``open_movie``, ``mark_seen``/``prepare_mark_seen``, and
    ``wishlist_movie`` — all of those accept either a numeric TMDB id or the
    human-readable title, so you do NOT need to pass the id specifically.
    ``open_movie`` self-navigates and scrolls to the row, so the row does NOT
    need to be on-screen first.
    """
    sim = SimulatorBridge.get()
    # Best-effort: focus the in-UI search field and type so the visible list
    # filters when the field is reachable. Never gates the catalog result.
    for aid in ("cinephile_tab_movies", "Movies"):
        try: sim.tap_id(aid); break
        except Exception: continue
    sim.wait(0.2)
    for aid in ("Search", "search_field", "movie_search_field"):
        try:
            sim.tap_id(aid); break
        except Exception:
            continue
    try:
        sim.type_text(query); sim.wait(0.3)
    except Exception:
        pass
    # Authoritative match over the catalog (title substring, case-insensitive).
    # Ablation: MCP_DISABLE_CINEPHILE_FALLBACK=1 forces the honest
    # visible-only path (no catalog lookup).
    if os.environ.get("MCP_DISABLE_CINEPHILE_FALLBACK", "0") == "1":
        visible = list_visible_movies()
        visible["source"] = "visible movies (catalog fallback disabled)"
        visible["ok"] = True
        visible["action"] = "search"
        visible["query"] = query
        return visible
    results = search_catalog(query)
    return {
        "ok": True,
        "action": "search",
        "query": query,
        "results": results,
        "movie_ids": [r["movie_id"] for r in results],
        "count": len(results),
        "source": "catalog title match",
    }


@mcp.tool()
def list_visible_movies() -> dict:
    """Scan the current UI tree for movie rows and return their TMDB ids.

    Returns ``{movie_ids: [int, ...], count: int}`` extracted from every
    ``cinephile_movie_row_<id>`` element currently in the tree (sorted,
    de-duplicated). Empty list if no rows are visible.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text()
    ids = sorted(set(int(x) for x in re.findall(r'cinephile_movie_row_(\d+)', tree)))
    return {"movie_ids": ids, "count": len(ids)}


def _visible_row_ids(tree: Optional[str] = None) -> set:
    """Return the set of TMDB ids whose movie rows are in the current tree."""
    if tree is None:
        tree = SimulatorBridge.get().observe_text() or ""
    return set(int(x) for x in re.findall(r'cinephile_movie_row_(\d+)', tree))


def _list_membership(movie_id: int) -> Optional[str]:
    """Which My Lists segment (if any) contains *movie_id*.

    Reads the persisted AppState (or its seed default) and returns
    ``"wishlist"`` or ``"seenlist"`` when the id lives in that list, else
    None. Used to self-navigate ``open_movie`` to the correct screen.
    """
    state, _ = _read_state()
    if not state:
        # Fall back to the known seed lists.
        if movie_id in set(_SEED_SEENLIST):
            return "seenlist"
        if movie_id in set(_SEED_WISHLIST):
            return "wishlist"
        return None
    ms = state.get("moviesState", {}) or {}
    if movie_id in set(ms.get("seenlist") or []):
        return "seenlist"
    if movie_id in set(ms.get("wishlist") or []):
        return "wishlist"
    return None


def _tap_first(sim, ids) -> bool:
    """Tap the first reachable accessibility id in *ids*; return success."""
    for aid in ids:
        try:
            sim.tap_id(aid); sim.wait(0.4)
            return True
        except Exception:
            continue
    return False


def _select_my_lists_segment(sim, segment: str) -> bool:
    """Open My Lists and select ``wishlist`` or ``seenlist``."""
    wanted = (segment or "").strip().lower()
    if wanted not in {"wishlist", "seenlist"}:
        return False
    _dismiss_overlays(sim)
    if not _tap_first(sim, ["cinephile_tab_my_lists", "My Lists"]):
        return False
    sim.wait(0.5)
    _dismiss_overlays(sim)
    _tap_first(sim, ["cinephile_tab_my_lists", "My Lists"])
    sim.wait(0.2)
    label = "Seenlist" if wanted == "seenlist" else "Wishlist"
    _tap_first(sim, [label])
    sim.wait(0.3)
    tree = sim.observe_text() or ""
    marker = "movies in seenlist" if wanted == "seenlist" else "movies in wishlist"
    return label in tree or marker in tree


# Generic shell/list titles that are NOT a pushed movie-detail view.
_NON_DETAIL_NAVBAR = {
    "cinephile", "movies", "discover", "fan club", "my lists",
    "now playing", "popular", "top rated", "upcoming", "wishlist",
    "seenlist", "search",
}


def _detail_view_open(tree: Optional[str] = None) -> bool:
    """True if a pushed movie-detail view (or any Back-able overlay) is up.

    Cinephile pushes movie detail / list-editor screens onto the active
    tab's navigation stack; while pushed, the segment control and movie
    rows of the underlying list are NOT in the tree, so a blind
    tab/segment tap can't reach the target row. We detect this by the
    presence of a pop affordance (``BackButton``) or a navigation-bar
    title that is a movie name rather than a generic shell title.
    """
    if tree is None:
        tree = SimulatorBridge.get().observe_text() or ""
    if 'name="BackButton"' in tree or '"Back"' in tree:
        return True
    m = re.search(r'<XCUIElementTypeNavigationBar\b[^>]*\bname="([^"]+)"', tree)
    if m and m.group(1).strip().lower() not in _NON_DETAIL_NAVBAR:
        return True
    return False


def _dismiss_overlays(sim, max_pops: int = 4) -> None:
    """Pop any open detail/editor overlay so list navigation is reachable.

    Taps ``BackButton``/``Close`` repeatedly until the tree no longer looks
    like a pushed detail view (bug-class 2: a tab/segment button present in
    the tree but covered by a detail overlay no-ops on tap). Safe to call
    from any state — it's a no-op when nothing is pushed.
    """
    for _ in range(max_pops):
        tree = sim.observe_text() or ""
        if not _detail_view_open(tree):
            return
        if not _tap_first(sim, ["BackButton", "Close"]):
            return
        sim.wait(0.4)


def _scroll_find_row(sim, movie_id: int, max_swipes: int = 8) -> bool:
    """Scroll the current list looking for ``cinephile_movie_row_<id>``.

    Tries the row first as-is, then swipes up repeatedly (and finally back
    down) so an off-screen row is brought into view. Returns True once the
    row id appears in the tree.
    """
    if movie_id in _visible_row_ids():
        return True
    for _ in range(max_swipes):
        try:
            sim.swipe("up"); sim.wait(0.4)
        except Exception:
            break
        if movie_id in _visible_row_ids():
            return True
    # Try scrolling back the other way in case we started mid-list.
    for _ in range(max_swipes):
        try:
            sim.swipe("down"); sim.wait(0.4)
        except Exception:
            break
        if movie_id in _visible_row_ids():
            return True
    return False


def _ensure_movie_row_visible(sim, movie_id: int) -> bool:
    """Self-navigate so ``cinephile_movie_row_<movie_id>`` is on screen.

    Strategy (blind-call friendly):
      1. If the row is already visible, done.
      2. Resolve which My Lists segment owns the id (seenlist/wishlist)
         from the persisted/seed state, switch to My Lists, pick that
         segment, and scroll to it.
      3. Otherwise fall back to scanning every My Lists segment and the
         Movies tab, scrolling each.
    Returns True if the row becomes visible.
    """
    if movie_id in _visible_row_ids():
        return True

    # Bug-class 2: if a detail/editor overlay is pushed, the tab bar and
    # segment buttons are present in the tree but covered — a blind tap
    # no-ops. Pop back to the list root first so navigation actually lands.
    _dismiss_overlays(sim)
    if movie_id in _visible_row_ids():
        return True

    def _open_my_lists_segment(segment: Optional[str]) -> bool:
        if segment not in {"wishlist", "seenlist"}:
            return False
        if not _select_my_lists_segment(sim, segment):
            return False
        return _scroll_find_row(sim, movie_id)

    membership = _list_membership(movie_id)
    if membership and _open_my_lists_segment(membership):
        return True
    # Brute-force both My Lists segments.
    for seg in ("wishlist", "seenlist"):
        if seg == membership:
            continue
        if _open_my_lists_segment(seg):
            return True
    # Last resort: the Movies tab lists (Now Playing / Popular / etc.).
    _dismiss_overlays(sim)
    if _tap_first(sim, ["cinephile_tab_movies", "Movies"]):
        sim.wait(0.5)
        if _scroll_find_row(sim, movie_id):
            return True
    return movie_id in _visible_row_ids()


@mcp.tool()
def open_movie(movie_id: int) -> str:
    """Open a movie's detail view, self-navigating to find its row first.

    Args:
        movie_id: TMDB integer id (e.g. ``238`` for The Godfather, ``438631``
            for Dune). This arg is the integer id ONLY — it does not accept a
            title; get the id from ``search`` (the ``movie_id`` field) or
            ``list_visible_movies``. The row does NOT need to be on-screen
            already — this tool self-navigates: it resolves which My Lists
            segment (seenlist/wishlist) contains the movie from the app's
            persisted state, pops any open overlay, switches to that screen,
            scrolls the row into view, and taps it (falling back to scanning
            both segments and the Movies tab).

    Returns ``Opened movie <id> (<title>).`` on success, or a controlled
    error string if the id can't be located anywhere in the app (a movie that
    isn't in any list and isn't in the loaded Movies tab — add it first with
    ``wishlist_movie(movie=...)`` or ``mark_seen(movie=...)``).
    """
    sim = SimulatorBridge.get()
    title = CATALOG.get(movie_id)
    # Fast path: already visible.
    if movie_id not in _visible_row_ids():
        _ensure_movie_row_visible(sim, movie_id)
    err = sim.tap_and_verify_changed(
        f"cinephile_movie_row_{movie_id}",
        prefix_for_failure=(
            f"Could not locate movie row {movie_id}"
            + (f" ({title})" if title else "")
            + " in the wishlist, seenlist, or loaded Movies tab. This movie "
            "is not currently in any of the app's lists, so it has no detail "
            "row to open. Add it first with wishlist_movie(movie=...) or "
            "mark_seen(movie=...), then open_movie will reach it. "
        ),
    )
    if err:
        return err
    sim.wait(0.6)
    suffix = f" ({title})" if title else ""
    return f"Opened movie {movie_id}{suffix}."


@mcp.tool()
def open_fan_club() -> str:
    """Switch to the Fan Club tab (favorite people). Shortcut for ``navigate_to_tab('fan_club')``."""
    return navigate_to_tab("fan_club")


@mcp.tool()
def open_my_lists() -> str:
    """Switch to the My Lists tab (custom watch lists + wishlist/seen). Shortcut for ``navigate_to_tab('my_lists')``."""
    return navigate_to_tab("my_lists")


@mcp.tool()
def open_seenlist() -> dict:
    """Open My Lists and select the Seenlist segment.

    This is a direct affordance for tasks that need to inspect the Seenlist;
    the SwiftUI segmented picker exposes only the visible label, so this tool
    handles the tab switch, overlay dismissal, and segment tap.
    """
    sim = SimulatorBridge.get()
    ok = _select_my_lists_segment(sim, "seenlist")
    return {"ok": bool(ok), "action": "open_seenlist",
            "message": "Opened Seenlist." if ok else "Could not open the Seenlist segment.",
            "ui": sim.observe_text() if ok else None}


@mcp.tool()
def open_wishlist() -> dict:
    """Open My Lists and select the Wishlist segment."""
    sim = SimulatorBridge.get()
    ok = _select_my_lists_segment(sim, "wishlist")
    return {"ok": bool(ok), "action": "open_wishlist",
            "message": "Opened Wishlist." if ok else "Could not open the Wishlist segment.",
            "ui": sim.observe_text() if ok else None}


@mcp.tool()
def list_seenlist() -> dict:
    """Return the persisted Seenlist movie ids/titles and open its UI segment."""
    sim = SimulatorBridge.get()
    _select_my_lists_segment(sim, "seenlist")
    state, _ = _read_state()
    seen = []
    if state:
        for mid in sorted(set(state.get("moviesState", {}).get("seenlist") or [])):
            seen.append({"movie_id": mid, "title": CATALOG.get(mid, f"Movie {mid}")})
    return {"ok": True, "action": "list_seenlist", "movies": seen,
            "movie_ids": [m["movie_id"] for m in seen], "count": len(seen)}


def _open_movie_title() -> Optional[str]:
    """Best-effort: read the open movie-detail view's title from the nav bar.

    Cinephile renders the detail title as the navigation-bar name
    (``Text(movie.userTitle)``). Returns the title string, or None when no
    movie detail view is open (generic shell/tab names are filtered out).
    """
    tree = SimulatorBridge.get().observe_text() or ""
    nav_match = re.search(r'<XCUIElementTypeNavigationBar\b[^>]*\bname="([^"]+)"', tree)
    if not nav_match:
        return None
    candidate = nav_match.group(1).strip()
    if candidate and candidate.lower() not in _NON_DETAIL_NAVBAR:
        return candidate
    return None


@mcp.tool()
def wishlist_movie(movie: str = "", add: bool = True) -> dict:
    """Add/remove a movie from the wishlist (durable, one-shot commit).

    Args:
        movie: Movie title (case-insensitive substring, e.g. ``"Dune"``) or a
            numeric TMDB id. When empty, falls back to the title of the
            currently-open movie detail view (legacy
            ``open_movie`` -> ``wishlist_movie`` flow).
        add: ``True`` (default) to add to the wishlist; ``False`` to remove.

    Persists ``moviesState.wishlist`` directly to the app's archived state
    (``Documents/userData``) and reloads so the change is real and
    observable. A best-effort UI tap of the on-screen ``Wishlist`` button is
    attempted first (only when present) to keep an open detail view in sync.
    Returns ``{ok, movie_id, title, in_wishlist, changed, wishlist}``; returns
    ``ok: False`` when no movie can be resolved, so it never falsely reports
    success when nothing was toggled.
    """
    sim = SimulatorBridge.get()
    target = (movie or "").strip()
    if not target:
        target = _open_movie_title() or ""
        if not target:
            return {"ok": False, "action": "wishlist",
                    "message": "No movie specified and no detail view open. "
                               "Pass movie=<title or tmdb id>, or open_movie first."}
    tree = sim.observe_text() or ""
    if ('name="Wishlist"' in tree) or ('name="In wishlist"' in tree):
        try:
            sim.tap_id("In wishlist" if not add else "Wishlist")
            sim.wait(0.2)
        except Exception:
            pass
    return _wishlist_set(target, add=add)


def _mark_seen_capture_summary() -> tuple[Optional[dict], Optional[str]]:
    """Inspect the current UI tree for an open movie detail view.

    Returns ``(summary, None)`` on success where ``summary`` is
    ``{"movie_title": <str or None>, "movie_id": <int or None>,
       "current_state": "in_seenlist"|"not_in_seenlist"|"unknown"}``.
    Returns ``(None, message)`` if no movie detail view is open so the
    caller can surface a controlled-failure response.
    """
    sim = SimulatorBridge.get()
    tree = sim.observe_text() or ""
    # The detail view exposes a BorderedButton whose label flips between
    # "Seen" (already in seenlist) and "Seenlist" (not yet seen). The
    # Wishlist sibling button is the most reliable detail-view marker.
    has_seen_button = ('name="Seen"' in tree) or ('name="Seenlist"' in tree)
    has_wishlist_button = ('name="Wishlist"' in tree) or ('name="In wishlist"' in tree)
    if not (has_seen_button or has_wishlist_button):
        return None, (
            "No movie detail view is open. Call list_visible_movies() then "
            "open_movie(movie_id=<id>) first, then re-call this tool."
        )
    current_state = "unknown"
    if 'name="Seen"' in tree:
        current_state = "in_seenlist"
    elif 'name="Seenlist"' in tree:
        current_state = "not_in_seenlist"
    # The movie title surfaces as the navigation bar title (Text(movie.userTitle))
    # which renders as an XCUIElementTypeNavigationBar with a child static text.
    title = None
    nav_match = re.search(
        r'<XCUIElementTypeNavigationBar[^>]*\bname="([^"]+)"',
        tree,
    )
    if nav_match:
        candidate = nav_match.group(1).strip()
        # Skip generic shell names.
        if candidate and candidate.lower() not in {"cinephile", "movies", "discover",
                                                    "fan club", "my lists"}:
            title = candidate
    # Movie id is not directly exposed on the detail view; capture any visible
    # cinephile_movie_row_<id> hint as a best-effort context anchor.
    movie_id = None
    row_match = re.search(r'cinephile_movie_row_(\d+)', tree)
    if row_match:
        try:
            movie_id = int(row_match.group(1))
        except ValueError:
            movie_id = None
    return {
        "movie_title": title,
        "movie_id": movie_id,
        "current_state": current_state,
    }, None


@mcp.tool()
def mark_seen(movie: str = "", seen: bool = True) -> dict:
    """Add (or remove) a movie from the user's Seen list (one-shot commit).

    Args:
        movie: Movie title (case-insensitive substring, e.g. ``"Dune"``,
            ``"godfather"``) OR a numeric TMDB id (e.g. ``"438631"``).
            Resolve titles you are unsure of with ``search``. When empty,
            falls back to the title of the currently-open movie detail view.
        seen: ``True`` (default) to add to the seenlist; ``False`` to remove.

    Persists directly to ``moviesState.seenlist`` in the app's archived
    state (``Documents/userData``) and reloads the app so the Seen list
    reflects the change. Returns ``{ok, movie_id, title, in_seenlist,
    changed, seenlist}``.
    """
    target = (movie or "").strip()
    if not target:
        # Best-effort: derive from the open detail view's title.
        summary, err = _mark_seen_capture_summary()
        if err is not None:
            return {"ok": False, "action": "mark_seen",
                    "message": "No movie specified and no detail view open. "
                               "Pass movie=<title or tmdb id>, or open_movie first."}
        target = summary.get("movie_title") or ""
        if not target:
            return {"ok": False, "action": "mark_seen",
                    "message": "Could not read the open movie's title; pass movie=<title or tmdb id>."}
    # Best-effort UI tap (keeps the detail view in sync when it's open).
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("Seen" if seen else "Seenlist"); sim.wait(0.2)
    except Exception:
        pass
    return _seenlist_set(target, add=seen)


@mcp.tool()
def prepare_mark_seen(movie: str = "", seen: bool = True) -> dict:
    """Stage a Seen-list change for a named movie WITHOUT committing.

    Args:
        movie: Movie title (case-insensitive substring) or numeric TMDB id.
            When empty, falls back to the currently-open movie detail view's
            title.
        seen: ``True`` (default) to stage an add; ``False`` to stage a removal.

    Resolves the movie to a TMDB id and mints a draft naming it. Returns
    ``{ok, draft_id, summary: {movie_id, title, seen}, next}``. Pass the
    ``draft_id`` to ``confirm_mark_seen`` to commit. On an unresolvable
    movie or no open detail view, returns ``{ok: False, ...}``.
    """
    target = (movie or "").strip()
    if not target:
        summary, err = _mark_seen_capture_summary()
        if err is not None:
            return {"ok": False, "action": "prepare_mark_seen",
                    "message": "No movie specified and no detail view open. "
                               "Pass movie=<title or tmdb id>, or open_movie first."}
        target = summary.get("movie_title") or ""
    movie_id = int(target) if target.isdigit() else title_to_id(target)
    if movie_id is None:
        return {"ok": False, "action": "prepare_mark_seen",
                "message": f"Could not resolve '{movie or target}' to a movie. "
                           "Use search() to find a title/id."}
    payload = {"movie_id": movie_id, "title": CATALOG.get(movie_id), "seen": bool(seen)}
    draft_id = ts.create_draft("cinephile", "mark_seen", payload)
    return {
        "ok": True,
        "action": "prepare_mark_seen",
        "draft_id": draft_id,
        "summary": payload,
        "next": "Call confirm_mark_seen(draft_id) to commit.",
    }


@mcp.tool()
def confirm_mark_seen(draft_id: str) -> dict:
    """Commit the Seen-list change previously staged by ``prepare_mark_seen``.

    ``draft_id`` is the id returned by ``prepare_mark_seen``. Reads the
    movie id + direction from the draft payload and persists it to
    ``moviesState.seenlist`` in the app's archived state, then reloads the
    app. Returns ``{ok: True, action: "confirm_mark_seen", evidence}`` on
    success, or a controlled-failure response if the draft is missing or
    expired.
    """
    draft = ts.consume_draft(draft_id)
    if not draft:
        return {
            "ok": False,
            "action": "confirm_mark_seen",
            "message": f"Draft '{draft_id}' not found or expired. Call prepare_mark_seen first.",
        }
    payload = draft.get("payload", {})
    movie_id = payload.get("movie_id")
    if movie_id is None:
        return {"ok": False, "action": "confirm_mark_seen",
                "message": "Draft is missing a movie_id; re-run prepare_mark_seen."}
    seen = bool(payload.get("seen", True))
    sim = SimulatorBridge.get()
    try:
        sim.tap_id("Seen" if seen else "Seenlist"); sim.wait(0.2)
    except Exception:
        pass
    result = _seenlist_set(str(movie_id), add=seen)
    result["action"] = "confirm_mark_seen"
    result["evidence"] = payload
    return result


if __name__ == "__main__":
    mcp.run()
