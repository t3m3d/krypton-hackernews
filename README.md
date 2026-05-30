  khn — Hacker News in your terminal, written in pure Krypton

  Live front-page feed: title, score, age, comments link.
  Watch any post's rank update in place. No browser, no JS.

  Built end-to-end in Krypton — one .k file, ~80 lines, zero
  non-stdlib dependencies. Uses k:http to hit the official HN
  Firebase API, k:json to parse the responses.

    brew tap t3m3d/krypton && brew install krypton   # if not installed
    kcc -r khn.k                                     # one-shot run
    # or: kcc --native khn.k -o khn && ./khn

  Status: macOS arm64 (2.1.1). Linux + Windows follow Krypton's
  own release cadence.

  Adjust the line count after I ship the actual source.
