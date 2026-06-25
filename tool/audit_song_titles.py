"""Audit songs.json for incorrect titles."""
import json
import os
import re

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "songs.json")

REF = re.compile(r"^(RH|MP|SP|OB|SK)\b", re.IGNORECASE)
GARBAGE = re.compile(r"^PP PPaa|^\d+\s*\([A-G#b]?m?\)", re.IGNORECASE)
NUMERIC_TITLE = re.compile(r"^\d+$")
FRAGMENT_END = re.compile(
    r"\b(the|a|an|and|of|to|in|that|for|who|with|as|at|by|from|on|or|but|if|when|where|while|so|ye|thy|thou|we|they|is|are|was|were|be|have|has|had|will|would|shall|should|may|might|must|can|could|am|i|me|my|you|your|us|our|their|his|her|its|this|these|those|what|how|why|all|each|every|both|some|no|not|only|own|same|too|very|just|now|here|there|then|ever|never|always|still|yet|also|again|much|many|well|oh|lo|lord|god|jesus|christ|spirit|holy|praise|sing|come|go|let|make|take|give|get|see|know|think|say|tell|ask|call|keep|hold|bring|lead|follow|walk|stand|live|die|born|rise|fall|grow|show|find|lose|pray|bless|love|hope|faith|grace|mercy|peace|joy|light|life|death|sin|soul|heart|hand|eye|face|name|word|voice|song|day|night|time|way|world|land|home|heaven|earth|cross|blood|king|son|father|child|man|men|people|nation|church|angel|saint|prophet|shepherd|lamb|rock|river|sea|wind|fire|water|bread|wine|tree|star|sun|moon|cloud|rain|storm|mountain|valley|field|garden|door|gate|path|road|city|house|room|table|throne|crown|key|wall|stone|gold|silver|flesh|head|foot|feet|arm|knee|side|wound|tear|smile|cry|weep|sorrow|pain|heal|save|redeem|forgive|cleanse|wash|purify|worship|adore|honor|serve|obey|trust|believe|confess|repent|restore|renew|revive|awake|arise|abide|dwell|rest|wait|watch|listen|hear|speak|preach|teach|learn|understand|remember|forget|choose|begin|end|start|finish|fulfill|pass|touch|feel|fear|doubt|wonder|glad|happy|sad|free|bound|loose|bind|break|build|create|plan|will|wish|want|need|desire|long|hunger|thirst|feed|fill|pour|flow|deep|wide|weak|strong|mighty|power|glory|beauty|wonder|miracle|hidden|known|seen|heard|spoken|written|given|received|blessed|holy|pure|clean|righteous|good|chosen|called|sent|led|carried|kept|saved|rescued|delivered|freed)\s*$",
    re.IGNORECASE,
)


def norm(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def first_content_line(lyrics: str) -> str:
    for line in lyrics.split("\n"):
        stripped = line.strip()
        if not stripped:
            continue
        if REF.match(stripped) or GARBAGE.match(stripped):
            continue
        if stripped.lower() in {"chorus:", "bridge:", "verse:", "intro:", "outro:"}:
            continue
        return stripped.rstrip(",")
    return ""


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    problems = []
    for song in songs:
        number = song.get("number", "")
        title = song.get("title", "").strip()
        first = first_content_line(song.get("lyrics", ""))
        reasons = []

        if not title:
            reasons.append("empty")
        if REF.match(title):
            reasons.append("ref_title")
        if NUMERIC_TITLE.match(title):
            reasons.append("numeric")
        if title.lower() in {"chorus:", "chorus", "bridge:", "verse:"}:
            reasons.append("label")
        if GARBAGE.search(title):
            reasons.append("garbage")
        if FRAGMENT_END.search(title) and int(number or 0) < 376:
            reasons.append("fragment")
        if first and norm(title) != norm(first):
            num = int(number) if number.isdigit() else 9999
            if num < 376 and not first.lower().startswith(title.lower()[:10]):
                reasons.append("mismatch_first_line")

        if reasons:
            problems.append(
                {
                    "number": number,
                    "title": title,
                    "first_line": first,
                    "reasons": reasons,
                    "key": song.get("key", ""),
                }
            )

    print(f"Total: {len(songs)}, Problems: {len(problems)}\n")
    for item in problems:
        print(f"{item['number']:>4} [{', '.join(item['reasons'])}]")
        print(f"  title: {item['title'][:70]}")
        if item["first_line"] and item["first_line"] != item["title"]:
            print(f"  lyric: {item['first_line'][:70]}")
        print()


if __name__ == "__main__":
    main()
