# Story Magic: words that make pictures

Written 2026-10-21 for Reason's ask: a game section where she strings words she can already read into sentences, statements and tiny stories. Code: `app/L2RR2L/Games/StoryMagic/`, content: `Media/content/stories.json`.

## Where it sits in the learning path

This is the **story moment** from `learning-path.md` section 5 (step 7, from late Stage 1) and the "Reads a whole sentence" and "First mini-story" milestones (section 8, numbers 4 and 7). Star Catch checks single words; Read Along models fluent reading; Story Magic is where *she* puts words together and sees that order and word choice change the meaning.

- In a session it comes after Star Catch, once she has some words read alone (8+) or is past Stage 1.
- It is also a portal on the home sky, any time.
- Every sentence is decodable with the sounds taught by its stage plus that stage's heart words (unit-tested, like Read Along).

## The idea: Cutisie dreams it, her words make it real

Each page shows a **dream**: a ghostly, shimmering picture of a scene (a cat on a mat). Under it is a sentence rail. The real things only appear when the words that name them land in the sentence, and they arrange themselves the way the sentence says. Words *do* something here: the cat drops onto the mat, the pig digs, the hen turns red. That is the payoff and the meaning check in one.

Scenes are composed live from the word pictures (the transparent art-pack cards), so every new sentence needs data, not art: who (`a`), where (`on`, `in`, `has`, `and`) and what (`b`), plus an action (`nap`, `dig`, `hop`, `run`, `sing`, `jump`...) or a look (`sad`, `mad`, `red`, `hot`, `big`).

## A round is one tiny story (3 pages and a meaning check)

1. **Pick It.** The sentence has one gap and three word clouds that differ by one sound (bed / bud / bad). She reads them and taps one. It flies into the gap and the scene obeys: the right word completes the dream; a wrong word makes a silly scene (the dog sits on a *bug*), Cutisie giggles, and the word pops back out.
2. **Make It.** The words are scrambled on clouds; she taps them into the rail in order (capital first, full stop fixed at the end). Each picture word she places pops its thing into the scene. When the rail is full:
   - right order: everything snaps into place, the dream turns real, the Star Voice reads the sentence while each word lights;
   - the two things swapped ("The mat is on the cat."): the silly scene plays out, the cat gets squashed, Cutisie falls about giggling, and the two words hop back;
   - anything else: the words in the right place lock and glow, the rest hop back.
   Scaffolding grows with her: at first the heart words are already in place and she places only the content words; then only the first word is given; then nothing.
3. **Page 3** is Pick It or Make It, alternating by session.
4. **Silly or not?** A sentence with no picture ("The bed is in the box."). She reads it and taps the happy face (makes sense) or the giggly face (silly). Then the scene acts it out. This is the learning-path "Does it make sense?" check, praised with "You noticed it was silly!"
5. **The story book.** The pages fly into a book; the Star Voice reads the whole story back, page by page, each word lighting as it is said. The story is saved to Cutisie's book (progress `storiesRead`) and the round ends with the dance.

## Help and feel

- A help wing replays the sentence (Pick It and Make It) and counts as audio help; she is praised for asking ("Asking for help is smart.").
- Stuck for 7 s: the next right word glows; 14 s: the Star Voice says that word.
- Tapping a placed word sends it back. Tiles are jelly cards with a heart on heart words.
- No fail state, no timers on screen. Misses are soft and funny; Cutisie is always the silly one.

## Scoring

- Pick It: the gap word is scored like any word read alone (correct first try without help counts toward mastery).
- Make It and Silly-or-not: sentence-level answers for the game stats; misses tagged `word-order` or `meaning` so the parent view can show "decodes well, misses meaning".

## Content

27 stories across Stages 1 to 6 in `stories.json`. Words not in the curriculum get their tiles from the file's `words` table. This game's narrator lines and the word "big" are recorded in the Star Voice (Runway preset Serene) with `tools/record_voice.py`; `tools/voice_lines.py` lists every line the app needs.
