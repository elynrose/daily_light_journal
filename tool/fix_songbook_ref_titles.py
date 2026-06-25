"""Fix songs whose title is a songbook reference (RH/MP/SP/OB) instead of the real title."""
import json
import os
import re

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "songs.json")

REF_TITLE_RE = re.compile(
    r"^(?:(?:RH|MP|SP|OB|SK)\s*[\d\-]+(?:\s+(?:RH|MP|SP|OB|SK)\s*[\d\-]+)*(?:\s+OB)?\s*)+$",
    re.IGNORECASE,
)
REF_LINE_RE = re.compile(
    r"^(?:RH|MP|SP|OB|SK)\s*[\d\-]+",
    re.IGNORECASE,
)
HEADER_LINE_RE = re.compile(
    r"^\d+\s*\([A-G][#b]?m?\)\s+(?:RH|MP|SP|OB|SK)\s*[\d\-]+",
    re.IGNORECASE,
)
PDF_GARBAGE_RE = re.compile(r"^PP PPaa aagg ggee ee\s+[\d\s]+$", re.IGNORECASE)


def is_ref_title(text: str) -> bool:
    text = text.strip()
    if not text:
        return False
    if REF_TITLE_RE.match(text):
        return True
    return bool(re.match(r"^(RH|MP|SP|OB|SK)\b", text, re.IGNORECASE))


def should_skip_line(line: str, old_title: str) -> bool:
    stripped = line.strip()
    if not stripped:
        return True
    if stripped == old_title.strip():
        return True
    if is_ref_title(stripped):
        return True
    if HEADER_LINE_RE.match(stripped):
        return True
    if PDF_GARBAGE_RE.match(stripped):
        return True
    return False


def clean_lyrics_lines(lines: list[str]) -> str:
    cleaned = [line for line in lines if not PDF_GARBAGE_RE.match(line.strip())]
    return "\n".join(cleaned).strip()


def fix_song(song: dict) -> bool:
    title = song.get("title", "").strip()
    if not is_ref_title(title):
        return False

    lyrics = song.get("lyrics", "")
    lines = lyrics.split("\n")

    start = 0
    while start < len(lines) and should_skip_line(lines[start], title):
        start += 1

    if start >= len(lines):
        return False

    new_title = lines[start].strip().rstrip(",")
    if not new_title or is_ref_title(new_title):
        return False

    new_lyrics = clean_lyrics_lines(lines[start:])
    if not song.get("songbookRef", "").strip():
        song["songbookRef"] = title

    song["title"] = new_title
    song["lyrics"] = new_lyrics
    return True


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    fixed = 0
    for song in songs:
        if fix_song(song):
            fixed += 1

    with open(SONGS_PATH, "w", encoding="utf-8") as handle:
        json.dump(songs, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    remaining = sum(1 for song in songs if is_ref_title(song.get("title", "")))
    print(f"Fixed {fixed} songs. Remaining ref titles: {remaining}")


if __name__ == "__main__":
    main()
