"""cmd+opt+arrows: move between panes, whatever kind they are.

* plain window (no multiplexer): move between kitty splits.
* window running tmux or herdr locally: send ctrl+alt+arrow so it moves its own
  panes; when a kitty split exists that way too, check whether the screen changed
  and if not (the multiplexer was at an edge) move to the kitty split.
* window running ssh/mosh: kitty cannot tell what is on the other end, and a plain
  remote shell would print the key as garbage ("D", "C"), so a kitty split in that
  direction always wins.  With no kitty split that way the key is forwarded, so a
  remote tmux/herdr can still move its panes.

kitty's `cmdline:` match only sees the launch command (the shell), so this asks the
window for its foreground processes.  Usage in kitty.conf:

    map cmd+alt+left kitten arrow_pass.py left
"""
import os
from hashlib import sha1

from kittens.tui.handler import result_handler
from kitty.boss import Boss
from kitty.fast_data_types import add_timer

# ctrl+alt+arrow, which tmux.conf and herdr/config.toml bind to pane moves
SEQUENCES = {
    'left': b'\x1b[1;7D',
    'right': b'\x1b[1;7C',
    'up': b'\x1b[1;7A',
    'down': b'\x1b[1;7B',
}
LOCAL_MULTIPLEXERS = {'tmux', 'herdr'}
REMOTE_SESSIONS = {'ssh', 'mosh', 'mosh-client'}
# the neighboring_window action accepts up/down, but Tab.neighboring_window wants top/bottom
EDGES = {'left': 'left', 'right': 'right', 'up': 'top', 'down': 'bottom'}
# how long to wait for a local multiplexer to redraw before deciding it was at an edge
# (animated spinners on screen can hide an edge)
EDGE_CHECK_SECONDS = 0.25


def foreground_kind(window) -> str:
    """'multiplexer', 'remote' or 'other' for what the window is running."""
    try:
        processes = window.child.foreground_processes
    except Exception:
        return 'other'
    kind = 'other'
    for process in processes:
        argv = process.get('cmdline') or []
        if not argv:
            continue
        name = os.path.basename(argv[0])
        if name in LOCAL_MULTIPLEXERS:
            return 'multiplexer'
        if name in REMOTE_SESSIONS or (name == 'kitten' and argv[1:2] == ['ssh']):
            kind = 'remote'
    return kind


def screen_fingerprint(window) -> str:
    # the ansi text includes colours, so a moved focus highlight changes it
    return sha1(window.as_text(as_ansi=True).encode('utf-8', 'replace')).hexdigest()


def main(args: list[str]) -> str:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    direction = args[1]
    edge = EDGES[direction]
    window = boss.window_id_map.get(target_window_id)
    tab = boss.active_tab
    if tab is None:
        return
    kind = foreground_kind(window) if window is not None else 'other'
    if kind == 'other':
        tab.neighboring_window(edge)
        return
    has_kitty_neighbor = tab.neighboring_group_id(edge) is not None
    if not has_kitty_neighbor:
        window.write_to_child(SEQUENCES[direction])
        return
    if kind == 'remote':
        tab.neighboring_window(edge)
        return
    before = screen_fingerprint(window)
    window.write_to_child(SEQUENCES[direction])

    def check(timer_id: int) -> None:
        if boss.active_window is window and screen_fingerprint(window) == before:
            tab.neighboring_window(edge)

    add_timer(check, EDGE_CHECK_SECONDS, False)
