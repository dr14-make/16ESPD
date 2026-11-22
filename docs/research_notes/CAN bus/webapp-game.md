# The Night Drive web app — design note

The classroom CAN game in `docs/lecture-06-can-game.md` gets a web app. This note records the
settled design and keeps the research behind it (timing, hosting, prior art).

## What the app is, and what it is not

**The claps and the physical play stay.** The room is the wired-AND: one clap beats silence, and
every student hears it at the same moment. A student with open hands *hears* the clap and sits
down; a student who forgot a clap hears the silence and shouts "STOP!". A screen cannot give that,
and Rounds 1–4 depend on it.

**The app replaces the paper and the bookkeeping:** the ECU cards, the secret envelopes, the bus
scribe and the strike keeper. It also plays the ECUs nobody holds, so **even one student can
play**: bots fill the empty seats.

An earlier draft of this note proposed a phone mode in which the app resolves arbitration and the
students watch; that premise is dropped. The app never decides on the students' behalf what they
clapped.

## Settled design

### Pages and hosting

- **Static pages, no server, no network between phones and projector.** Each phone and the
  projector derive everything from the same inputs: the head count, the seat and the round.
- Three VitePress pages in `slides/site/game/`: `projector.md`, `play.md` (phone) and
  `debrief.md`. Each mounts a `<ClientOnly>` Vue 3 component. They ship through the existing Pages
  workflow (`npm run check`, `npm run build` in `slides/`, publishing `slides/dist`), with no new
  build path.
- The engine is a pure TypeScript module with no Vue, tested with Vitest. `npm run check` runs the
  tests before it builds anything.
- The deck links to the projector page after the `strikes` slide; `where-the-room-stops` links to
  the debrief.

### Seats and cards

- The lecturer enters the head count **N (1–11)** on the projector. N picks the card set of the
  game doc: up to 6 the cards marked 10, 7–8 adds the 20 set, 9 and more adds the 30 set.
- ECUs go to seats 1…N in a fixed priority: rain sensor, radio, dashboard, ABS, motor, brake pedal,
  then steering and battery (20 set), then yaw rate and climate (30 set). Every ECU of the set
  that the script needs and no seat holds is a **bot**. Solo play (N = 1) is the rain sensor.
  Seat 11 is a logger: the set has only ten ECUs.
- Secret cards stay fixed by role, as in the game doc: interference to the dashboard (Round 3),
  new radio and workshop fix to the radio (Round 4), water in the connector to the rain sensor
  (Round 6).

### Joining

- The projector shows a QR code for `…/game/play.html?n=N` and a short typed fallback: a letter
  for N plus the seat number (N = 8, seat 3 → `H3`).
- The phone shows seat buttons 1…N, matching paper seat tents at the table. It keeps the seat, the
  round and the strikes in `localStorage` (every access wrapped, so a private window still plays).

### Script and deviations: a hybrid

- The app holds the game doc's scripted rounds as **inputs**: who gets news at which frame, and
  which sentence (`cards.ts`, `rounds.ts`). The engine **derives** the rest: who stands, the bus
  row, who sits on which beat, the winner, clean or STOP, and the strikes.
- When a frame goes as planned, the lecturer taps once to advance. When it does not, the lecturer
  records the deviation: **STOP** where none was planned, a **different winner**, or a **replay**
  (the frame did not count and is clapped again). A deviation branches from the script: the
  engine recomputes every later frame from the recorded inputs, so a stopped speaker stands again
  in the next frame and the strikes follow.
- Lecturer input: presenter clicker **PageDown** = frame as planned, **PageUp** = undo the last
  input; keyboard **S** = STOP, **digits** = the topic that actually won, **R** = replay,
  **Space** = start or pause the metronome. A small key legend sits in a corner.

### The Clock on the projector

- The projector owns the metronome: a Web Audio woodblock, scheduled ahead with a lookahead
  scheduler, **60 bpm** in Rounds 1–2 and **80 bpm** from Round 3. Phones play no beat.
- A frame is twelve beats: three quiet beats, the start clap, b3 b2 b1 b0, three beats for the
  sentence and the nod. That is the game doc's 12 s at 60 bpm.
- A beat cursor runs across `S b3 b2 b1 b0`; the bus level of each beat appears as the cursor
  passes it, which is the scribe's job.
- The projector claps for the bots: a synthesized clap on each standing bot's start clap and on
  its dominant (0) beats until it sits down.

### Rounds in scope

Rounds 1, 2, 3, 4, 5 (traffic jam) and 6. Two optional frames the lecturer can switch on: the
Round 2 warm-up (the whole room claps topic 5, then the halves clap 5 against 6) and the Round 3
"everybody switch off" ACK demo. Out of scope: the Ethernet contrast, the airbag stuff-beat bonus
and the Round 6 comeback after four clean frames.

### Strikes stay private

- Strike counts live **only on the phone**. After each of their own sentences in Round 6 the
  student taps **went through** (−1, never below 0) or **stopped** (+8). The phone shows the
  state: active, whisperer (16 and up) or out of the room (32 and up).
- The projector computes its own counts but hides them until the debrief. For bots it shows the
  behavior (whispering, sitting out, walking out), never a number. This repairs cheat 7 of the
  game doc: counters are private to each node.

### Rounds and secret cards on the phone

- The phone knows the round because the student steps a big **Round N ▸** button; the projector
  shows the round number large.
- A secret card appears on its seat's phone when the phone enters that card's round, with a
  vibration and an envelope that opens. The workshop fix waits in a second, sealed envelope that
  the radio opens when the Workshop says so at the end of Round 4.

### Debrief

- A frame log: round, standing topics, bus row, winner, clean or STOP, and the projector's strike
  counts per ECU, revealed now. Deviations from the script have their own color.
- Selecting a row steps through its beats one at a time: who sat down on which beat, and the bus
  level.
- Each row has a URL hash (`debrief.html#r2-f2`), so the deck can link to one frame. Without a
  played game on the laptop, the debrief shows the script as planned.

### Source of truth and tests

The tests assert the engine against the game doc's expected tables, copied into the tests once:
Round 2 frames a–f, the Round 4 double winner, the Round 5 nine frames and the Round 6 strike
sequence. The game doc points to those tests.

## Research kept from the investigation

### Timing reality

Classroom wifi gives 50–300 ms of jitter per phone, with outliers over a second, and university
networks such as eduroam often isolate clients from each other. At 80 bpm a beat lasts 750 ms, so
syncing taps to the beat over the network would put a third of the taps in the wrong beat.
Real-time bit sync between phones is out, which is one more reason the beat stays in the room and
on the projector's speaker.

**Web Audio scheduling.** `setTimeout` and `setInterval` drift by tens of milliseconds under load,
and a background tab is throttled to one call per second. The standard pattern is a lookahead
scheduler: a timer wakes every 25 ms and schedules every beat due in the next 100 ms on the audio
clock (`AudioContext.currentTime`), which is sample-accurate. The screen follows the audio clock,
not the other way round. Browsers start an `AudioContext` only after a user gesture, so the first
Space or click resumes it.

### How the course ships

`slides/` holds the Slidev decks and a VitePress site (`slides/site/`, with `lecture/` and
`handson/` pages). `.github/workflows/pages.yml` runs `npm ci`, `npm run check` and
`npm run build` in `slides/`, then publishes `slides/dist` to GitHub Pages under `/16ESPD/`.
A static page costs nothing there, needs no accounts and collects no student data.

Hosting options weighed for a phone mode with live state, and why none was taken:

| Option | What it could do | Why not |
|---|---|---|
| Static page + Cloudflare Durable Object (one per room, WebSocket) | server-authoritative phones; the free plan includes SQLite-backed DOs since April 2025 | a second deploy target and an account to own, for a mode the settled design does not need |
| Static page + PartyKit | the same, on Durable Objects | pricing page returned 404 when checked; limits unverified |
| Static page + Firebase / Supabase realtime | phones, client-authoritative unless a cloud function resolves frames | a third-party database holding classroom data |
| Small Node WebSocket server (laptop hotspot) | phones with no venue internet | a server to run in the lecture |
| WebRTC peer-to-peer, projector as host (PeerJS) | phones with the projector as authority | needs a signaling broker; client isolation on eduroam can block direct connections |

With the inputs shared out of band (head count, seat, round button), no option is needed: each
page computes the same deal and the same script locally, and it works offline once loaded.

**Privacy.** No logins, nicknames or student IDs. The phone keeps its own seat, round and strikes
in the browser; the projector keeps the frame log on the lecturer's laptop.

## Prior art

- **Majid Mazouchi, "CAN protocol primer"**, an interactive web primer with a three-node
  arbitration demo and a bit-timing tool, per search snippets:
  https://majid-mazouchi.github.io/autonomy/posts/can-protocol-primer/ . The page is rendered by
  scripts; the demo text could not be confirmed with a plain fetch. **Unverified.**
- **Browser CAN analyzers** (traffic viewers, not arbitration teaching): CSS Electronics webCAN,
  https://www.csselectronics.com/pages/webcan-can-bus-streaming-software-browser ; CANviz (local
  Python backend, virtual bus), https://hackaday.com/2026/04/21/can-bus-analyzer-runs-in-your-browser/ .
  The debrief's frame log borrows their `candump`-style rows. **Not opened**, only seen in search
  results.
- **Kvaser, bit-wise arbitration lesson**, the waveform view the debrief's bit stepper echoes:
  https://kvaser.com/lesson/can-basics-bit-wise-arbitration-differential-signals/ (cited in the game
  doc).
- **Join-by-code classroom apps (Kahoot pattern):** PeerPresent, PeerJS presenter/viewer with a
  4-digit room code, listed at
  https://awesome.ecosyste.ms/projects/github.com%2Fbkrajendra%2Fpeerpresent (license not checked,
  **unverified**). The app borrows the join flow: a big code on the projector, no account.
- **Chris Wilson, "A Tale of Two Clocks"** (web.dev), the lookahead scheduling pattern for Web
  Audio metronomes: https://web.dev/articles/audio-scheduling .
- **CS Unplugged** network-protocol and binary activities, already the mechanics source of the game
  doc: https://classic.csunplugged.org/activities/network-protocols/ .

No multiplayer CAN classroom web game turned up. The closest are single-user arbitration
animations.

## Risks

| Risk | Mitigation |
|---|---|
| The app replaces the claps and the lesson becomes watching | the app never resolves the room's claps; the lecturer records what the room did |
| Room wifi or eduroam blocks phones | nothing travels between devices; each page works offline once loaded |
| A phone reloads mid-game | seat, round and strikes persist in `localStorage` |
| The projector spoils arbitration | the bus row appears beat by beat as the room claps; the winner shows only after b0 |
| Engine diverges from the game doc | the tests replay the doc's tables |
| The projector reads as a master | the World never says who speaks; the beat stands for the agreed bit rate (cheat 1) |
| Students on phones get distracted | the phone shows one card and one round button |
