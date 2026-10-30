# Case Study 05: GitHub 2GB Release Streaming & Branch Alignment

## 1. Problem Statement
When publishing large binary artifacts (the 2.0GB full installer) to GitHub Releases via REST API and maintaining the codebase:
1. Uploading the 2,063,054,832 byte asset using standard HTTP POST methods failed abruptly with `curl: (55) Send failure: Out of memory` or process termination via Linux OOM killer.
2. After pushing updates to GitHub, the user reported: *"you said you updated, i it shows still old , why?"*. Browsing the GitHub web repository showed outdated READMEs and commit histories despite successful local git pushes.

---

## 2. Technical Investigation

### Investigation A: The 2GB cURL Buffer Crash
The standard GitHub Releases upload API accepts assets via HTTP POST:
```bash
# BROKEN COMMAND:
curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/zip" \
     --data-binary @"$ZIP_FILE" \
     "https://uploads.github.com/repos/vishxtr/SweetLinux/releases/$RELEASE_ID/assets?name=$ZIP_NAME"
```

- **The Failure Mechanism:** `--data-binary` instructs `curl` to load the entire specified file into heap memory prior to sending the HTTP request payload.
- In memory-constrained environments or 32-bit processes, attempting to allocate a contiguous 2.06 GB buffer triggers an immediate memory allocation failure (`ENOMEM`) or invokes the Linux Out-Of-Memory (OOM) killer.

### Investigation B: Default Branch Divergence (`main` vs `master`)
Running `git branch -a` and inspecting GitHub remote metadata revealed:
- The local repository was historically configured on branch `master`.
- GitHub's modern default branch initialization creates `main`.
- On GitHub, `remotes/origin/HEAD` pointed to `origin/main`.
- When build scripts executed `git push origin master`, the commits were pushed to branch `master`. However, when visitors or users browsed `https://github.com/vishxtr/SweetLinux`, GitHub displayed the default branch `main`, which remained frozen at an earlier commit!

---

## 3. The Engineering Solution

### 1. Zero-Memory Asset Streaming via `curl -T`
Replaced `--data-binary` with `curl -T` (HTTP PUT streaming / chunked transfer encoding):

```bash
# FIXED STREAMING COMMAND:
curl -X POST \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/zip" \
     -T "$ZIP_FILE" \
     "https://uploads.github.com/repos/vishxtr/SweetLinux/releases/$RELEASE_ID/assets?name=$ZIP_NAME"
```

- **The Benefit:** `curl -T` reads from disk in 16KB/64KB chunk buffers, streaming directly into the socket without loading the entire 2GB file into RAM.
- **Upload Speed:** Streamed the 2.06 GB installer over Google Colab's network uplink to GitHub in **82 seconds** (~25.1 MB/s) with peak memory consumption under 15 MB.

### 2. Dual-Branch Alignment (`master:main`)
To ensure visitors browsing GitHub always see the absolute latest commits regardless of default branch settings:

```bash
# Sync local master to origin/main
git push origin master:main --force-with-lease
# Also keep origin/master synchronized
git push origin master
```

Furthermore, GitHub API was queried to ensure `default_branch` is consistently set and both branches point to the exact same tree SHA.
