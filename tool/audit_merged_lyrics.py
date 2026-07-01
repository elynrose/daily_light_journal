"""Find songs that may still contain merged hymns."""
import json
import os
import re

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "samples", "songs_library_template.json")

KNOWN_SECOND_SONG_STARTS = [
    r"^Do Lord,",
]


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    for song in songs:
        lyrics = song["lyrics"]
        title = song["title"]
        for pattern in KNOWN_SECOND_SONG_STARTS:
            match = re.search(pattern, lyrics, re.MULTILINE)
            if match and "do lord" not in title.lower():
                print(f"{song['number']}: {title!r} — merged at: {match.group()[:40]}")


if __name__ == "__main__":
    main()
