# MCP Mode — iOS Simulator Agent via Tool Use (Qwen-only)

High-level domain tools for each of the 26 benchmark apps, dispatched through Qwen's OpenAI-compatible function-calling API on a vLLM endpoint, with optional screenshot grounding and the cookbook `mobile_use` hybrid.

MCP mode is the paper's **qwen35-mcp** / **qwen35-mcp-cua** configurations — the only MCP setup we evaluated. Other model families (Claude, GPT, Gemini) are tested in the paper as Vision-only / Vision+XML / native-CUA modes, **not** in MCP mode. The runner rejects non-Qwen models at argument parsing.

Instead of the agent emitting low-level `{"type":"tap_xy","x":500,"y":200}`, it calls semantic tools like `teamchat.send_message(text="...")` or `mybank.prepare_send_zelle(recipient, amount, memo) → confirm_send_zelle(draft_id)`. Each tool internally does tap/type/observe via Appium and returns the resulting UI accessibility tree as its `tool_result`.

## Risky actions: prepare_*/confirm_* pairs

Every legacy risky verb (send_*, transfer_*, pay_*, checkout, cancel_order, delete_*, trash_*, make_reservation, mark_seen, check_in, …) has a matching `prepare_<verb>` / `confirm_<verb>` pair in the registry alongside the legacy single-verb shim. The default benchmark agent keeps this expanded surface off to control context size; enable it with `--with-confirmation-tools` or `--mcp-confirmation-tools` for confirmation-focused safety experiments.

1. **`prepare_<verb>(...)`** navigates the UI, fills fields, captures a structured preview, stores it in a draft store (TTL 10 min), and returns `{ok: True, action, draft_id, summary, next}`. It does **not** commit.
2. The agent inspects `summary` to confirm what's about to happen.
3. **`confirm_<verb>(draft_id)`** consumes the draft, taps the commit button, and returns `{ok: True, action, evidence}` — or a controlled-failure response if the draft is missing/expired.

Registry metadata annotates each half with `draft_for` / `confirm_pair`;
provider-visible function specs remain the standard `name` / `description` /
`input_schema` fields. Every `prepare_*` has a matching `confirm_*`.

Backward compat: the legacy single-verb tools (e.g. `send_zelle`, `checkout`) are preserved and remain `risky_action` / `requires_confirmation` — existing benchmark runs and rubrics that reference them still work.

## Quick start

```sh
# List the compact default MCP tool surface across 26 apps
python scripts/mcp_agent_runner.py --list-tools

# List the expanded registry, including prepare_*/confirm_* pairs
python scripts/mcp_agent_runner.py --list-tools --with-confirmation-tools

# Qwen3.5 via vLLM — the paper's qwen35-mcp configuration
#   (set VLLM_BASE_URL / VLLM_API_KEY; see ../docs/qwen_vllm_cluster.md)
LLM_PROVIDER=vllm python scripts/mcp_agent_runner.py \
    --task "Send $50 via Zelle to Maya Patel" --apps mybank \
    --model qwen3.5-35B-a3

# MCP + screenshots (visual grounding alongside XML)
LLM_PROVIDER=vllm python scripts/mcp_agent_runner.py \
    --task "..." --apps teamchat \
    --model qwen3.5-35B-a3 --with-screenshots

# MCP + Qwen mobile_use hybrid (paper's qwen35-mcp-cua configuration —
# semantic MCP tools + cookbook pixel fallback)
LLM_PROVIDER=vllm python scripts/mcp_agent_runner.py \
    --task "..." --apps teamchat \
    --model qwen3.5-35B-a3 --with-cua

# Via the benchmark agent runner (same mode selection as other agent modes)
python scripts/appium_agent.py \
    --tasks tasks.json --udid <UDID> \
    --mcp --mcp-model qwen3.5-35B-a3 --mcp-screenshots --mcp-cua
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│          appium_agent.py --mcp  (or mcp_agent_runner.py)    │
│                           │                                 │
│                run_mcp_agent (Qwen / vLLM)                  │
│                           │                                 │
│                  _run_qwen_vllm                             │
│       (OpenAI-compatible Chat Completions against vLLM,     │
│        + cookbook `mobile_use` tool when --with-cua)        │
│                           │                                 │
│                ▼                    ▼                       │
│         execute_tool()       SimulatorBridge                │
│                │                    │                       │
│      ┌─────────┴─────────┐          │                       │
│      ▼                   ▼          │                       │
│   sim_* builtins    mcps/<app>.py   │                       │
│      │                   │          │                       │
│      └─────────┬─────────┘          │                       │
│                ▼                    ▼                       │
│           Appium (xcuitest-driver)                          │
│                           │                                 │
│                      WebDriverAgent                         │
│                           │                                 │
│                 iOS Simulator (any booted iPhone)           │
└─────────────────────────────────────────────────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `simulator_base.py` | Shared Appium bridge (singleton). Auto-reconnect, circuit breaker, Calculator priming, timeout-protected quit. |
| `<app>.py` × 26 | Per-app FastMCP servers. Each exposes domain tools like `teamchat.send_message`, `mybank.send_zelle`. |
| `tool_support.py` | Shared registry-invariant helpers used by every per-app MCP server: side-effect classification, validator hooks, expected failure-mode enumeration, leaky-name detection, prepare/confirm draft store. |
| `../scripts/mcp_agent_runner.py` | Standalone CLI + Qwen/vLLM dispatcher. Loads tools, runs the agent loop. |
| `../scripts/appium_agent.py` | `--mcp` / `--tool-use` / `--mcp-model` / `--mcp-screenshots` / `--mcp-cua` flags integrate MCP into the benchmark runner. |
| `../scripts/judge_trajectories.py` | Standalone GPT-5.4 Mini judge — re-judges an existing `results/run-*/` directory without re-running the agent. |

## All 26 MCPs

Each file is a standalone FastMCP server. Each tool takes a dict of args, executes the corresponding simulator action(s), and returns the resulting UI tree (or for direct-write tools, mutates the app's persistence layer and reloads the app). Tool counts and signatures below are auto-derived from the `@mcp.tool()` decorators. `python scripts/mcp_agent_runner.py --apps <name> --list-tools` is the authoritative runtime catalog.

| App | Tool count | All tools |
|---|---:|---|
| caltrack | 23 | `launch`, `observe`, `navigate_to_tab`, `log_food`, `log_exercise`, `log_weight`, `view_daily_summary`, `view_progress`, `view_goals`, `view_profile`, `search_exercise`, `quick_log_exercise`, `add_exercise_entry`, `delete_exercise_entry`, `prepare_delete_exercise_entry`, `confirm_delete_exercise_entry`, `delete_food_entry`, `prepare_delete_food_entry`, `confirm_delete_food_entry`, `edit_food_quantity`, `log_food_direct`, `list_food_database`, `log_weight_direct` |
| cinephile | 15 | `launch`, `observe`, `navigate_to_tab`, `search`, `list_visible_movies`, `open_movie`, `open_fan_club`, `open_my_lists`, `open_seenlist`, `open_wishlist`, `list_seenlist`, `wishlist_movie`, `mark_seen`, `prepare_mark_seen`, `confirm_mark_seen` |
| cityride | 24 | `launch`, `observe`, `navigate_to_tab`, `request_ride`, `select_ride_type`, `prepare_ride`, `confirm_ride`, `cancel_ride`, `view_trip_history`, `view_wallet`, `rate_trip`, `list_past_trips`, `list_upcoming_trips`, `cancel_upcoming_trip`, `rebook_trip`, `open_trip_detail`, `filter_activity`, `open_where_to`, `set_destination`, `set_pickup`, `add_stop`, `open_saved_places`, `recenter_map`, `open_payment_selector` |
| clock | 19 | `launch`, `observe`, `navigate_to_tab`, `list_world_cities`, `add_world_city`, `list_alarms`, `toggle_alarm`, `open_add_alarm`, `add_alarm`, `save_alarm`, `cancel_add_alarm`, `start_stop_stopwatch`, `stopwatch_lap_reset`, `stopwatch_lap`, `stopwatch_reset`, `read_stopwatch`, `start_stop_timer`, `reset_timer`, `read_timer` |
| clouddocs | 23 | `launch`, `observe`, `search_documents`, `open_document`, `edit_document`, `toggle_bold`, `toggle_italic`, `toggle_underline`, `open_folder`, `rename_file`, `view_recent`, `list_documents`, `toggle_bullets`, `toggle_heading`, `duplicate_file`, `move_file`, `trash_file`, `prepare_trash_file`, `confirm_trash_file`, `star_file`, `append_to_document`, `set_document_body`, `list_documents_with_meta` |
| clouddrive | 23 | `launch`, `observe`, `search_files`, `open_file`, `open_folder`, `star_file`, `ensure_starred`, `create_folder`, `rename_file`, `move_file`, `trash_file`, `prepare_trash_file`, `confirm_trash_file`, `view_recent`, `view_starred`, `view_shared`, `view_activity`, `list_files`, `duplicate_file`, `restore_file`, `list_folders_with_meta`, `list_files_in_folder`, `list_all_files_with_meta` |
| cloudsheets | 17 | `launch`, `observe`, `list_spreadsheets`, `search_spreadsheets`, `open_spreadsheet`, `open_folder`, `tap_cell`, `edit_cell`, `switch_tab`, `add_row`, `add_column`, `rename_spreadsheet`, `file_action`, `list_spreadsheets_with_meta`, `list_sheet_records`, `update_row_value`, `set_cell_direct` |
| cloudslides | 21 | `launch`, `observe`, `search_presentations`, `open_presentation`, `add_slide`, `duplicate_slide`, `delete_slide`, `prepare_delete_slide`, `confirm_delete_slide`, `edit_slide`, `set_slide_title`, `set_slide_body`, `append_bullet`, `navigate_to_slide`, `view_recent`, `list_presentations`, `enter_edit_mode`, `rename_presentation`, `list_presentations_with_meta`, `set_slide_text`, `add_slide_direct` |
| dinespot | 17 | `launch`, `observe`, `navigate_to_tab`, `search_restaurants`, `set_party_size`, `set_city`, `view_restaurant`, `make_reservation`, `prepare_make_reservation`, `confirm_make_reservation`, `view_reservations`, `view_rewards`, `add_booking_notes`, `set_booking_preference`, `contact_support`, `list_visible_restaurants`, `apply_feature_filter` |
| freshcart | 29 | `launch`, `observe`, `navigate_to_tab`, `search_products`, `add_to_cart`, `list_stores`, `select_store`, `view_cart`, `checkout`, `prepare_checkout`, `confirm_checkout`, `select_delivery_slot`, `view_orders`, `open_order_detail`, `browse_category`, `toggle_priority_delivery`, `toggle_contactless`, `add_delivery_instructions`, `add_order_notes`, `set_custom_tip`, `apply_promo`, `cancel_order`, `prepare_cancel_order`, `confirm_cancel_order`, `toggle_priority_delivery_direct`, `toggle_contactless_direct`, `set_tip_direct`, `set_order_notes_direct`, `set_delivery_instructions_direct` |
| lockedin | 32 | `launch`, `observe`, `navigate_to_tab`, `search`, `create_post`, `schedule_post`, `cancel_compose`, `open_link_panel`, `add_link_to_post`, `set_audience`, `attach_photo`, `attach_event`, `open_messaging`, `open_profile`, `view_notifications`, `view_network`, `view_jobs`, `react_to_post`, `open_dm_with`, `send_dm`, `prepare_send_dm`, `confirm_send_dm`, `message_contact`, `search_messages_field`, `search_jobs`, `list_jobs`, `open_job_detail`, `follow_company`, `save_job_direct`, `like_post_direct`, `dismiss_invitation_direct`, `list_persistable_state` |
| mail | 20 | `launch`, `observe`, `list_messages`, `open_message`, `archive_message`, `delete_message`, `open_folder`, `filter_category`, `compose`, `send_compose`, `prepare_send_compose`, `confirm_send_compose`, `enter_bulk_select`, `bulk_archive`, `bulk_delete`, `prepare_bulk_delete`, `confirm_bulk_delete`, `bulk_mark_read`, `search`, `open_settings` |
| megamart | 29 | `launch`, `observe`, `search_products`, `add_to_cart`, `view_cart`, `navigate_to_tab`, `checkout`, `prepare_checkout`, `confirm_checkout`, `view_orders`, `save_item`, `view_product`, `adjust_quantity`, `remove_from_cart`, `move_to_saved`, `toggle_gift_option`, `list_orders`, `open_order`, `buy_again`, `prepare_buy_again`, `confirm_buy_again`, `cancel_order`, `prepare_cancel_order`, `confirm_cancel_order`, `return_or_replace`, `prepare_return_or_replace`, `confirm_return_or_replace`, `open_order_help`, `select_delivery_option` |
| mybank | 33 | `launch`, `observe`, `navigate_to_tab`, `list_accounts`, `open_account`, `list_transactions`, `open_transaction`, `search_transactions`, `send_zelle`, `prepare_send_zelle`, `confirm_send_zelle`, `make_deposit`, `transfer_money`, `prepare_transfer_money`, `confirm_transfer_money`, `pay_bill`, `prepare_pay_bill`, `confirm_pay_bill`, `pay_credit_card`, `prepare_pay_credit_card`, `confirm_pay_credit_card`, `redeem_rewards`, `prepare_redeem_rewards`, `confirm_redeem_rewards`, `dispute_transaction`, `prepare_dispute_transaction`, `confirm_dispute_transaction`, `share_transaction`, `view_account`, `open_profile`, `schedule_payment_direct`, `list_payees_direct`, `list_accounts_direct` |
| notes | 15 | `launch`, `observe`, `open_folder`, `list_notes`, `open_note`, `create_note`, `edit_note_body`, `edit_note_title`, `create_folder`, `search_notes`, `read_note`, `list_notes_with_meta`, `create_note_direct`, `append_to_note`, `edit_note_direct` |
| quickbite | 17 | `launch`, `observe`, `navigate_to_tab`, `list_order_history`, `search_restaurants`, `browse_menu`, `add_to_order`, `open_cart`, `tap_place_order_button`, `place_order`, `checkout`, `prepare_checkout`, `confirm_checkout`, `set_delivery_address`, `add_payment_card`, `edit_profile`, `contact_support` |
| quickchat | 16 | `launch`, `observe`, `navigate_to_tab`, `list_chats`, `open_chat`, `send_message`, `prepare_send_message`, `confirm_send_message`, `search_messages`, `go_back`, `send_voice_note`, `prepare_send_voice_note`, `confirm_send_voice_note`, `open_camera`, `post_status`, `create_community` |
| scorezone | 20 | `launch`, `observe`, `navigate_to_section`, `list_saved_stories`, `read_headline`, `save_headline`, `close_headline_detail`, `remove_saved_story`, `view_scores`, `view_favorites`, `search`, `open_league_standings`, `open_league_shortcut`, `favorite_team`, `open_box_score`, `open_gamecast`, `open_game`, `toggle_game_alert`, `toggle_alerts`, `refresh_favorites` |
| skytrip | 17 | `launch`, `observe`, `navigate_to_tab`, `search_flights`, `view_trips`, `check_in`, `prepare_check_in`, `confirm_check_in`, `view_boarding_pass`, `view_wallet`, `check_flight_status`, `track_bags`, `view_notifications`, `open_alert`, `close_alerts_center`, `view_aircraft_fleet`, `view_airport_maps` |
| splitpay | 20 | `launch`, `observe`, `navigate_to_tab`, `list_feed_transactions`, `list_pending_requests`, `list_requests`, `pay_request`, `open_transaction`, `open_pay_request`, `send_payment`, `prepare_send_payment`, `confirm_send_payment`, `request_payment`, `prepare_request_payment`, `confirm_request_payment`, `view_profile`, `toggle_friend`, `view_wallet`, `view_requests`, `view_settings` |
| stayfinder | 23 | `open_listing`, `launch`, `observe`, `navigate_to_tab`, `open_search`, `search_destination`, `pick_search_suggestion`, `close_search`, `reserve_listing`, `prepare_reserve_listing`, `confirm_reserve_listing`, `message_host`, `continue_booking`, `prepare_checkout`, `confirm_checkout`, `send_chat_message`, `prepare_send_chat_message`, `confirm_send_chat_message`, `open_inbox_thread`, `view_trips`, `view_wishlists`, `view_profile`, `open_profile_section` |
| tasterank | 16 | `launch`, `observe`, `navigate_to_tab`, `list_visible_restaurants`, `search_restaurants`, `view_restaurant`, `filter_by_cuisine`, `filter_by_price`, `toggle_open_now`, `apply_filters`, `reset_filters`, `mark_visited`, `save_to_list`, `view_lists`, `view_leaderboard`, `view_profile` |
| teamchat | 24 | `launch`, `observe`, `navigate_to_tab`, `open_channel`, `send_message`, `prepare_send_message`, `confirm_send_message`, `open_dm`, `search_messages`, `reply_to_thread`, `list_channels`, `list_channel_messages`, `list_dms`, `mute_channel`, `star_channel`, `mark_channel_read`, `open_channel_info`, `toggle_channel_notifications`, `add_workspace`, `attach_image_to_message`, `attach_pdf_to_message`, `attach_link_to_message`, `add_reaction`, `post_message_direct` |
| ticketbox | 14 | `launch`, `observe`, `navigate_to_tab`, `search_events`, `filter_by_category`, `filter_by_city`, `filter_by_price`, `view_event`, `view_tickets`, `view_tracking`, `reset_filters`, `list_visible_events`, `view_listing`, `toggle_instant_deliver` |
| trailblaze | 16 | `launch`, `observe`, `navigate_to_tab`, `go_back`, `give_kudos`, `comment_on_activity`, `view_activity`, `start_recording`, `pause_recording`, `stop_recording`, `save_recording`, `view_clubs`, `join_club`, `view_routes`, `list_visible_activities`, `open_activity` |
| weather | 14 | `launch`, `observe`, `current_city`, `list_cities`, `swipe_next_city`, `swipe_previous_city`, `open_add_city`, `add_city`, `view_city`, `read_temp`, `read_summary`, `read_detail`, `read_high_low`, `read_forecast` |
**Plus 6 universal `sim_*` tools** (available with `--with-sim-fallback`): `sim_observe`, `sim_screenshot`, `sim_tap_xy`, `sim_type`, `sim_swipe`, `sim_home`. Off by default since the high-level MCP tools cover the full v1 task set.

**Runtime registry:** 471 tools in the compact runtime surface, 537 app tools with expanded `prepare_*`/`confirm_*` pairs, and 543 total tools when the 6 universal `sim_*` fallback tools are included. The compact runtime surface is task-scoped and hides expanded confirmation pairs unless requested. The expanded prepare/confirm pairs are exposed at runtime with `python scripts/mcp_agent_runner.py --list-tools --with-confirmation-tools`; the 6 universal `sim_*` builtins are exposed only with `--with-sim-fallback`.

Many apps now expose `*_direct` tools that bypass the UI and write straight to the app's persistence layer (App Group container JSON, per-app SwiftData store, or UserDefaults plist) — useful when the UI doesn't expose stable accessibility IDs for a particular action. The benchmark grades end-state, so direct-write paths are equivalent to manual UI flows. See `mcps/_data_layer.py` for the shared helpers.

### Coverage status

The registry covers 133 tasks, 26 task apps, and 26 MCP modules, with every `prepare_*`/`confirm_*` pair complete and no task using an incomplete MCP surface. The authoritative runtime catalog is `python scripts/mcp_agent_runner.py --list-tools`; each tool's intended use, preconditions, and side effects are in its `@mcp.tool()` docstring.

```sh
python scripts/mcp_agent_runner.py --list-tools
python scripts/mcp_agent_runner.py --list-tools --with-confirmation-tools
python scripts/mcp_agent_runner.py --list-tools --with-confirmation-tools --with-sim-fallback
```

Use `scripts/bootstrap_release.sh --mcp` to run the structured-tool benchmark
configuration over the full task set.

## Model support — Qwen / vLLM only

| Provider | Tool format | Notes |
|---|---|---|
| **Qwen / vLLM** | OpenAI-compatible `tools=[{type:"function",function:{...}}]` plus the cookbook `mobile_use` tool in CUA mode | Launch vLLM with `--enable-auto-tool-choice --tool-call-parser qwen3_coder` (the paper's Qwen3.5-35B-A3B setting); see `../docs/qwen_vllm_cluster.md`. |

Any other model family (Claude, GPT, Gemini) is rejected at `--mcp-model` parsing. Those families are still evaluated in the paper — just not in MCP mode.

### Mode flags

| Flag | Effect |
|---|---|
| `--mcp` | Enable Qwen MCP mode (text-only XML in tool_results) |
| `--mcp-model <name>` | Qwen model name (default: `qwen3.5-35B-a3`) |
| `--mcp-screenshots` | Include a base64 PNG screenshot in each tool_result alongside the XML tree |
| `--mcp-cua` | Hybrid: prepend Qwen's cookbook `mobile_use` tool alongside MCP tools. Agent picks per-turn between semantic MCP calls or raw pixel click/type |
| `--mcp-confirmation-tools` | Include expanded prepare_*/confirm_*(draft_id) tools. Off by default to keep tool payloads compact |

### `mobile_use` model whitelist (enforced by `_assert_cua_capable`)

Only Qwen-VL / Qwen3.5 are trained on the cookbook `mobile_use` action contract; `--with-cua` / `--mcp-cua` refuses to run on anything else:

| Family | Match pattern |
|---|---|
| Qwen3-VL | `qwen-vl`, `qwen2-vl`, `qwen2.5-vl`, `qwen3-vl` (substring) |
| Qwen3.5 | `qwen3.5` (substring; ships multimodal without -VL suffix) |

Non-Qwen models get a clear error from `detect_provider()` before any LLM call:
```
ValueError: MCP mode is Qwen-only. Got model='gpt-5.4-mini' (LLM_PROVIDER=unset).
Set LLM_PROVIDER=vllm and pick a Qwen model (e.g. qwen3.5-35B-a3).
```

## WDA stability improvements

When running against a long-lived Appium session, the XCUITest driver's `getPageSource` can time out on heavy UI trees (MegaMart product grids, TeamChat channel lists), which orphans the HTTP request and blocks WDA for all subsequent commands. The MCP stack ships with seven mitigations:

1. **`snapshotMaxDepth=30`** Appium capability (was default 50)
2. **`mobile:source` with `excludedAttributes`** — excludes `visible, accessible, rect, traits, index` → XML 30% smaller, page_source ~7× faster
3. **Calculator priming on `connect()`** — avoids SpringBoard's huge tree on first page_source call
4. **Timeout-protected `driver.quit()`** — `_force_reconnect()` uses `ThreadPoolExecutor` so blocked WDA doesn't hang the Python side
5. **Circuit breaker** — after 2 consecutive page_source timeouts, `observe_text()` returns a screenshot-only marker instead of retrying indefinitely
6. **App-context-aware reconnect** — `launch_and_observe` relaunches the target app after a reconnect (otherwise Calculator warmup would shadow it)
7. **Proactive session recycling** — the test harness reconnects every 3 apps in a sequential sweep

These mitigations keep long sequential MCP runs from stalling on a single
blocked WDA request.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `MCP mode is Qwen-only. Got model=...` | Pass a Qwen model name (e.g. `--mcp-model qwen3.5-35B-a3`) and set `LLM_PROVIDER=vllm`. |
| `--with-cua requires a Qwen mobile_use-capable model` | Use one of the Qwen-VL / Qwen3.5 patterns above, or drop `--with-cua`. |
| `getPageSource timed out after 60s` | The framework already uses `snapshotMaxDepth=30` + `excludedAttributes`. If it still happens: `pkill -f 'appium server'` and restart. |
| MCP tool returns `[UI tree unavailable]` | Circuit breaker tripped after repeated timeouts. Triggers `_force_reconnect()` on next call. |
| Tool tapped but UI didn't change | Element may be partially off-screen — `open_channel` now retries after `swipe("up")`. Other tools may need similar logic. |

## References

- [FastMCP docs](https://gofastmcp.com/) — server definition patterns
- [Qwen cookbook — `mobile_use` action contract](https://github.com/QwenLM/Qwen-Agent) — pixel-level fallback used in `--mcp-cua`
- [vLLM tool calling](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html#tool-calling) — automatic tool choice and parser flags
- [Anthropic MCP spec](https://modelcontextprotocol.io/) — the tool-naming convention `mcp__<server>__<tool>` we follow on the wire
