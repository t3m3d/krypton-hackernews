// khn — Hacker News in your terminal, written in pure Krypton.
// Author: Brian / KryptonBytes — https://krypton-lang.org
//
// Build + run (one-shot):
//   kcc -r khn.k
//
// Build a binary:
//   kcc --native khn.k -o khn
//   ./khn
//
// Usage:
//   khn            top 20 stories
//   khn 50         top 50 stories
//   khn best       /beststories
//   khn new        /newstories
//   khn ask        /askstories
//   khn show       /showstories
//   khn job        /jobstories

import "k:json_parse"

// ── HTTP via curl (skips k:http's Windows-isms; works on any platform) ──

func hnFetch(url) {
    emit exec("curl -sS --max-time 10 " + url)
}

// ── ANSI colors ──────────────────────────────────────────────────────

func esc()     { emit fromCharCode(27) }
func ansiBold(s)    { emit esc() + "[1m" + s + esc() + "[0m" }
func ansiDim(s)     { emit esc() + "[2m" + s + esc() + "[0m" }
func ansiPurple(s)  { emit esc() + "[35m" + s + esc() + "[0m" }
func ansiCyan(s)    { emit esc() + "[36m" + s + esc() + "[0m" }
func ansiYellow(s)  { emit esc() + "[33m" + s + esc() + "[0m" }
func ansiGreen(s)   { emit esc() + "[32m" + s + esc() + "[0m" }
func ansiBlue(s)    { emit esc() + "[34m" + s + esc() + "[0m" }
func ansiRed(s)     { emit esc() + "[31m" + s + esc() + "[0m" }

// ── Helpers ──────────────────────────────────────────────────────────

// Pull the host (no scheme) out of a URL: "https://example.com/a/b" → "example.com".
func urlHost(url) {
    let after = url
    if startsWith(url, "https://") { after = substring(url, 8, len(url)) }
    if startsWith(url, "http://")  { after = substring(url, 7, len(url)) }
    let slash = indexOf(after, "/")
    if slash < 0 { emit after }
    emit substring(after, 0, slash)
}

// Format a unix timestamp as "Nm ago" / "Nh ago" / "Nd ago".
func relTime(unix) {
    let nowS = trim(exec("date +%s"))
    let now = toInt(nowS)
    let diff = now - toInt(unix)
    if diff < 60   { emit "" + diff + "s ago" }
    if diff < 3600 { emit "" + (diff / 60) + "m ago" }
    if diff < 86400 { emit "" + (diff / 3600) + "h ago" }
    emit "" + (diff / 86400) + "d ago"
}

// Right-pad a string to width `w`.
func padR(s, w) {
    let out = s
    let pad = w - len(s)
    while pad > 0 {
        out = out + " "
        pad -= 1
    }
    emit out
}

// Left-pad a string to width `w`.
func padL(s, w) {
    let out = ""
    let pad = w - len(s)
    while pad > 0 {
        out = out + " "
        pad -= 1
    }
    emit out + s
}

// ── HN API ───────────────────────────────────────────────────────────

func hnEndpoint(kind) {
    if kind == "best" { emit "https://hacker-news.firebaseio.com/v0/beststories.json" }
    if kind == "new"  { emit "https://hacker-news.firebaseio.com/v0/newstories.json" }
    if kind == "ask"  { emit "https://hacker-news.firebaseio.com/v0/askstories.json" }
    if kind == "show" { emit "https://hacker-news.firebaseio.com/v0/showstories.json" }
    if kind == "job"  { emit "https://hacker-news.firebaseio.com/v0/jobstories.json" }
    emit "https://hacker-news.firebaseio.com/v0/topstories.json"
}

func hnItem(id) {
    emit hnFetch("https://hacker-news.firebaseio.com/v0/item/" + id + ".json")
}

// ── Story rendering ──────────────────────────────────────────────────

func renderStory(rank, jp) {
    let title = jpGet(jp, "title")
    let score = jpGet(jp, "score")
    let by    = jpGet(jp, "by")
    let url   = jpGet(jp, "url")
    let id    = jpGet(jp, "id")
    let time  = jpGet(jp, "time")
    let kids  = "0"
    if jpHas(jp, "descendants") {
        kids = jpGet(jp, "descendants")
    }
    let host = ""
    if len(url) > 0 { host = urlHost(url) }
    let when = relTime(time)
    let comments = "https://news.ycombinator.com/item?id=" + id

    // Row 1: rank + score + title.
    kp(ansiDim("#" + padL("" + rank, 3)) + " " +
       ansiYellow(padL("" + score, 4)) + "  " +
       ansiBold(title))

    // Row 2: indented meta.
    let meta = ""
    if len(host) > 0 {
        meta = ansiCyan(host) + ansiDim(" · ")
    }
    meta = meta + ansiGreen(by) + ansiDim(" · ") +
                  ansiPurple(when) + ansiDim(" · ") +
                  ansiBlue(kids + " comments")
    kp("       " + meta)
    kp("       " + ansiDim(comments))
    kp("")
}

// ── Main ─────────────────────────────────────────────────────────────

just run {
    let kind = "top"
    let limitArg = ""
    let arg0 = arg("0")
    let arg1 = arg("1")

    // arg("0") returns "0" when no args given (Krypton 2.1.1 quirk).
    if argCount() > 0 && arg0 != "0" && arg0 != "" {
        // First arg may be a number ("50") or a kind ("best", "new", …).
        if toInt(arg0) > 0 {
            limitArg = arg0
        } else {
            kind = arg0
            limitArg = arg1
        }
    }

    let limit = 20
    if limitArg != "" && toInt(limitArg) > 0 {
        limit = toInt(limitArg)
    }

    let endpoint = hnEndpoint(kind)
    kp("khn — " + ansiPurple("HN /" + kind) + " " + ansiDim("(top " + limit + ")"))
    kp("")

    let raw = hnFetch(endpoint)
    if len(raw) == 0 {
        kp(ansiRed("khn: no response from " + endpoint))
        emit 1
    }

    // The list endpoint returns a JSON array of integer IDs:
    //   [123, 456, 789, …]
    // Strip the brackets + spaces, swap commas to newlines, iterate with
    // getLine/lineCount. Avoids fighting `split` on a 500-entry list.
    let cleaned = replace(replace(replace(raw, "[", ""), "]", ""), " ", "")
    let idList = replace(cleaned, ",", "\n")

    let i = 0
    let shown = 0
    let total = lineCount(idList)
    while shown < limit && i < total {
        let id = trim(getLine(idList, i))
        if len(id) > 0 {
            let itemRaw = hnItem(id)
            if len(itemRaw) > 0 {
                let jp = jpParse(itemRaw)
                renderStory(shown + 1, jp)
                shown += 1
            }
        }
        i += 1
    }

    kp(ansiDim("— " + shown + " stories. Open the comments URL in a browser to discuss."))
}
