# khn

**Hacker News in your terminal, written in pure Krypton.**

Live front-page feed: title, score, age, host, comments link.
Watch any post's rank update by re-running. No browser, no JS.

Built end-to-end in [Krypton](https://krypton-lang.org) — one `.k` file,
~200 lines, zero non-stdlib dependencies. Uses `k:json_parse` to read
the official HN Firebase API and shells out to `curl` for the HTTP
calls (skips `k:http`'s Windows-isms, works on any platform with
`curl` installed).

```
khn — HN /top (top 5)

#  1   41  OpenRouter raises $113M Series B
       openrouter.ai · freeCandy · 30m ago · 4 comments
       https://news.ycombinator.com/item?id=48338660

#  2  151  Voxel Space
       s-macke.github.io · davikr · 3h ago · 32 comments
       https://news.ycombinator.com/item?id=48336564

#  3  207  Openrsync: An implementation of rsync, by the OpenBSD team
       github.com · sph · 7h ago · 92 comments
       https://news.ycombinator.com/item?id=48334854
```

## Install

```bash
# 1. Krypton 2.1.1 or later.
brew tap t3m3d/krypton
brew install krypton

# 2. khn — one of three flavors:
git clone https://github.com/t3m3d/khn
cd khn

# a) one-shot run
kcc -r khn.k

# b) build a native binary (preferred — no startup cost on repeat runs)
kcc --c khn.k > /tmp/khn.c
clang /tmp/khn.c -o khn -w
codesign -s - -f khn        # macOS only; ad-hoc signature for AMFI
./khn

# c) drop the binary into your $PATH
mv khn /usr/local/bin/
khn
```

Once Krypton 2.1.2 fixes the macho self-host regression, `kcc --native
khn.k -o khn` replaces step (b) and we drop clang from the loop.

## Usage

```bash
khn              # top 20 stories
khn 50           # top 50 stories
khn best         # /beststories
khn new          # /newstories
khn ask          # /askstories
khn show         # /showstories
khn job          # /jobstories
khn best 30      # /beststories, top 30
```

## How it works

1. Hit one of the HN Firebase endpoints (e.g.
   `topstories.json`) → returns a JSON array of integer story IDs.
2. Strip brackets/spaces, swap commas to newlines, iterate via
   `lineCount` / `getLine`.
3. For each ID, fetch `/v0/item/<id>.json` and parse with `k:json_parse`.
4. Render two lines per story (rank+score+title, then meta) with ANSI
   colors via `fromCharCode(27) + "[...m"`.

The whole thing is in `khn.k`. Pure Krypton, single file, no `import`
beyond `k:json_parse`. Reads as a worked example of:

- Calling shell commands and capturing stdout (`exec(cmd)`).
- Parsing JSON with `jpParse` / `jpGet` / `jpHas`.
- ANSI color helpers and right/left-padding for table-shaped output.
- The `arg("0") == "0"` quirk in Krypton 2.1.1 args.
- Unix-time → relative-age math without a `time` module.

## Status

| Platform | Status |
|---|---|
| macOS arm64 | ✅ Works on Krypton 2.1.1+ |
| Linux x86_64 | 🟡 Source compatible; build path unverified |
| Windows | 🟡 Should work; `curl` ships with Windows 10+ |

## License

Apache-2.0. Same as Krypton itself.
