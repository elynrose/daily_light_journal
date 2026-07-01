"""Clean song titles and lyrics in samples/songs_library_template.json."""
import json
import os
import re

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "samples", "songs_library_template.json")

REF_TITLE_RE = re.compile(
    r"^(?:(?:RH|MP|SP|OB|SK)\s*[\d\-]+(?:\s+(?:RH|MP|SP|OB|SK)\s*[\d\-]+)*(?:\s+OB)?\s*)+$",
    re.IGNORECASE,
)
REF_LINE_RE = re.compile(r"^(?:RH|MP|SP|OB|SK)\s*[\d\-]+", re.IGNORECASE)
MERGE_MARKER_RE = re.compile(
    r"^\d+\s*\([A-G][#b]?m?\)\s+(?:RH|MP|SP|OB|SK)\s*[\d\-]+",
    re.IGNORECASE,
)
PDF_GARBAGE_RE = re.compile(r"^PP PPaa aagg ggee ee\s+[\d\s]+$", re.IGNORECASE)
NUMERIC_TITLE_RE = re.compile(r"^\d+$")
VERSE_PREFIX_RE = re.compile(r"^\d+\)\s*")
INCOMPLETE_END_RE = re.compile(
    r"\b(that|and|or|the|a|an|in|of|to|for|with|as|at|by|from|on|but|if|when|where|who|which)\s*$",
    re.IGNORECASE,
)
LABEL_TITLE_RE = re.compile(r"^chorus:?$", re.IGNORECASE)
LABEL_LINE_RE = re.compile(r"^(chorus|bridge|verse|intro|outro):?\s*$", re.IGNORECASE)
KNOWN_MERGE_START_RE = [
    re.compile(r"^Do Lord,", re.MULTILINE | re.IGNORECASE),
]


def is_ref_title(text: str) -> bool:
    text = text.strip()
    if not text:
        return False
    if REF_TITLE_RE.match(text):
        return True
    return bool(re.match(r"^(RH|MP|SP|OB|SK)\b", text, re.IGNORECASE))


def should_skip_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    if PDF_GARBAGE_RE.match(stripped):
        return True
    if MERGE_MARKER_RE.match(stripped):
        return True
    if NUMERIC_TITLE_RE.match(stripped):
        return True
    if REF_LINE_RE.match(stripped) and len(stripped.split()) <= 6:
        return True
    return False


def first_content_line(lyrics: str) -> str:
    for line in lyrics.split("\n"):
        stripped = line.strip()
        if should_skip_line(stripped):
            continue
        if LABEL_LINE_RE.match(stripped):
            continue
        return polish_title(stripped)
    return ""


def truncate_known_merges(lyrics: str, title: str) -> str:
    title_low = title.lower()
    for pattern in KNOWN_MERGE_START_RE:
        match = pattern.search(lyrics)
        if not match:
            continue
        marker = pattern.pattern.strip("^").split(",")[0].lower()
        if marker not in title_low:
            lyrics = lyrics[: match.start()].rstrip()
    return lyrics


def polish_title(line: str) -> str:
    line = line.rstrip(",").strip()
    line = re.sub(r"\s+that\s*$", "", line, flags=re.IGNORECASE)
    return line


def clean_lyrics(lyrics: str, title: str = "") -> str:
    cleaned: list[str] = []
    for line in lyrics.split("\n"):
        stripped = line.strip()
        if MERGE_MARKER_RE.match(stripped):
            break
        if PDF_GARBAGE_RE.match(stripped):
            continue
        if NUMERIC_TITLE_RE.match(stripped) and not cleaned:
            continue
        if REF_LINE_RE.match(stripped) and not cleaned:
            continue
        if LABEL_LINE_RE.match(stripped) and not cleaned:
            continue
        cleaned.append(line.rstrip())
    lyrics = "\n".join(cleaned).strip()
    return truncate_known_merges(lyrics, title)


def normalize_title(title: str) -> str:
    title = VERSE_PREFIX_RE.sub("", title.strip())
    title = re.sub(r"\s+", " ", title)
    return title.strip()


def fix_incomplete_title(title: str, lyrics: str) -> str:
    if not INCOMPLETE_END_RE.search(title):
        return title

    lines = [line.strip() for line in lyrics.split("\n") if line.strip() and not should_skip_line(line.strip())]
    if len(lines) < 2:
        return title

    second = lines[1]
    if second[0].islower() or second.startswith("Out"):
        phrase = second.split(",")[0].strip()
        return f"{lines[0].rstrip(',')} {phrase}".strip()
    return title


def title_needs_fix(title: str) -> bool:
    title = title.strip()
    if not title:
        return True
    if NUMERIC_TITLE_RE.match(title):
        return True
    if LABEL_TITLE_RE.match(title):
        return True
    if is_ref_title(title):
        return True
    if VERSE_PREFIX_RE.match(title):
        return True
    return False


def fix_song(song: dict) -> list[str]:
    changes: list[str] = []
    old_title = song.get("title", "").strip()
    old_lyrics = song.get("lyrics", "")

    new_lyrics = clean_lyrics(old_lyrics, old_title)
    if new_lyrics != old_lyrics:
        song["lyrics"] = new_lyrics
        changes.append("lyrics_cleaned")

    title = normalize_title(old_title)
    title_was_bad = title_needs_fix(title)

    if title_was_bad:
        replacement = first_content_line(song["lyrics"])
        if replacement:
            title = replacement
            changes.append("title_from_lyric")

    title = fix_incomplete_title(title, song["lyrics"])
    if title_was_bad or title.endswith(" that"):
        first_line = first_content_line(song["lyrics"])
        if first_line and title.lower().startswith(polish_title(first_line).lower()):
            title = polish_title(first_line)
        elif title.lower() == first_line.lower():
            title = polish_title(title)
    title = normalize_title(title)

    if title != old_title:
        song["title"] = title
        changes.append(f"title:{old_title!r}->{title!r}")

    return changes


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    fixed = 0
    for song in songs:
        changes = fix_song(song)
        if changes:
            fixed += 1
            print(f"{song['number']}: {', '.join(changes)}")

    with open(SONGS_PATH, "w", encoding="utf-8") as handle:
        json.dump(songs, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    remaining = [s for s in songs if title_needs_fix(s.get("title", ""))]
    print(f"\nFixed {fixed} songs. Remaining bad titles: {len(remaining)}")
    for song in remaining:
        print(f"  {song['number']}: {song['title']!r}")


if __name__ == "__main__":
    main()
