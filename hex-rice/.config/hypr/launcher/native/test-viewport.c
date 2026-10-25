/* Native viewport regressions. Built against the pinned, patched Fuzzel source.
 * No compositor, input device or running desktop is touched by these tests. */
#include <assert.h>
#include <stdio.h>
#include "match.c"

static struct matches list(size_t count) {
    return (struct matches){.match_count=count, .max_matches_per_page=8};
}

int main(void) {
    struct matches m = list(40);
    assert(matches_idx_select(&m, 2));
    assert(matches_scroll(&m, true));
    assert(m.first_visible == 1 && m.selected == 3);
    assert(matches_get_match_index(&m) == 2);
    /* Selecting the hovered row must not cancel the new viewport offset. */
    assert(matches_idx_select(&m, 2));
    assert(m.first_visible == 1 && m.selected == 3);
    for (int i=0; i<100; ++i) matches_scroll(&m, true);
    assert(m.first_visible == 32 && m.selected == 34);
    assert(!matches_scroll(&m, true));
    assert(matches_get_count(&m) == 8);
    assert(matches_idx_select(&m, 7) && m.selected == 39);
    assert(!matches_selected_next(&m, false));
    assert(matches_selected_prev(&m, false) && m.selected == 38);
    assert(matches_selected_first(&m) && m.first_visible == 0);
    assert(matches_selected_last(&m) && m.first_visible == 32);
    assert(matches_selected_next(&m, true) && m.first_visible == 0);
    assert(matches_selected_prev(&m, true) && m.first_visible == 32);
    for (int i=0; i<100; ++i) matches_scroll(&m, false);
    assert(m.first_visible == 0);
    assert(!matches_scroll(&m, false));

    m = list(10);
    assert(matches_idx_select(&m, 2));
    for (int i=0; i<20; ++i) matches_scroll(&m, true);
    assert(m.first_visible == 2 && m.selected == 4);
    assert(matches_get_count(&m) == 8);
    /* Keyboard navigation remains visible after pointer scrolling. */
    assert(matches_selected_next_page(&m, false));
    assert(m.selected == 9 && m.first_visible == 2);
    assert(matches_selected_prev_page(&m, false));
    assert(m.selected == 1 && m.first_visible == 1);

    /* Filtering, resize, short lists and empty results clamp safely. */
    m.match_count = 1;
    keep_selection_visible(&m);
    assert(m.selected == 0 && m.first_visible == 0);
    assert(matches_get_count(&m) == 1 && !matches_scroll(&m, true));
    m.match_count = 0;
    keep_selection_visible(&m);
    assert(matches_get_count(&m) == 0 && !matches_scroll(&m, false));
    m = list(40);
    assert(matches_selected_last(&m));
    matches_max_matches_per_page_set(&m, 12);
    assert(m.first_visible == 28 && matches_get_count(&m) == 12);
    puts("Fuzzel viewport regression checks passed.");
    return 0;
}
