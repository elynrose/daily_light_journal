import json
import os
import re

import pypdf

PDF_PATH = r"c:\Users\Eliezer\Downloads\Songs.pdf"
OUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "assets",
    "songs.json",
)


def main() -> None:
    reader = pypdf.PdfReader(PDF_PATH)
    text = "\n".join(page.extract_text() or "" for page in reader.pages)
    text = text.replace("\r", "")

    header_re = re.compile(
        r"\n\s*(\d+)\s*\(([^)]+)\)\s*(?:(MP|OB)\s*(\d+))?\s*\n",
        re.IGNORECASE,
    )

    matches = list(header_re.finditer(text))
    songs = []

    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        body = text[start:end].strip()
        lines = [line.strip() for line in body.split("\n") if line.strip()]

        if not lines:
            continue

        title = lines[0].rstrip(",").strip()
        lyrics = "\n".join(lines)

        book = match.group(3) or ""
        book_num = match.group(4) or ""

        songs.append(
            {
                "number": match.group(1),
                "key": match.group(2).strip(),
                "title": title,
                "lyrics": lyrics,
            }
        )

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as handle:
        json.dump(songs, handle, indent=2, ensure_ascii=False)

    print(f"Parsed {len(songs)} songs -> {OUT_PATH}")


if __name__ == "__main__":
    main()
