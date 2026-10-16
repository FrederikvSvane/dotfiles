"""cmd+opt+arrows: move tmux panes when the window runs tmux (or ssh/mosh to a
host that does), otherwise move between kitty splits.

kitty's `cmdline:` match only sees the launch command (the shell), so this asks
the window for its foreground processes instead.  Usage in kitty.conf:

    map cmd+alt+left kitten arrow_pass.py left
"""
import os

from kittens.tui.handler import result_handler
from kitty.boss import Boss

# ctrl+alt+arrow, which tmux.conf binds to select-pane
SEQUENCES = {
    'left': b'\x1b[1;7D',
    'right': b'\x1b[1;7C',
    'up': b'\x1b[1;7A',
    'down': b'\x1b[1;7B',
}
PASS_THROUGH = {'tmux', 'herdr', 'ssh', 'mosh', 'mosh-client'}
# the neighboring_window action accepts up/down, but Tab.neighboring_window wants top/bottom
EDGES = {'left': 'left', 'right': 'right', 'up': 'top', 'down': 'bottom'}


def runs_pass_through_program(window) -> bool:
    try:
        processes = window.child.foreground_processes
    except Exception:
        return False
    for process in processes:
        argv = process.get('cmdline') or []
        if not argv:
            continue
        name = os.path.basename(argv[0])
        if name in PASS_THROUGH or (name == 'kitten' and argv[1:2] == ['ssh']):
            return True
    return False


def main(args: list[str]) -> str:
    pass


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    direction = args[1]
    window = boss.window_id_map.get(target_window_id)
    if window is not None and runs_pass_through_program(window):
        window.write_to_child(SEQUENCES[direction])
    else:
        tab = boss.active_tab
        if tab is not None:
            tab.neighboring_window(EDGES[direction])
