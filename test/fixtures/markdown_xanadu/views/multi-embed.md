# Multi Embed

Three embeds to exercise LRU limit (max_open_embeds = 3).

![[targets/alpha]]

![[targets/beta]]

![[graphs/hub]]

![[graphs/spoke-a]]

## Steps

1. Open all four via sidebar `<CR>` — oldest closes when fourth opens.
2. Embeds stack vertically in one column to the right of the source doc (not a horizontal chain).
3. Verify gutter shows active connector for the link under the cursor; others dimmed when `gutter_inactive` is true.
