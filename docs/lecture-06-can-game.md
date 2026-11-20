# Lecture 6 — The Night Drive: a CAN bus game for the room

A 20-minute game in which the class plays the ECUs of one car and runs CAN's rules with claps.
It acts out the meeting room of S1 in `lecture-06-plan.md`, with the vocabulary of the deck's
`rules-of-the-room`, `clapping-the-topic`, `strikes` and `where-the-room-stops` slides
(section 01).

**Where it goes in the deck:** after `strikes` and before `where-the-room-stops`. The game makes
the room physical; `where-the-room-stops` then opens the debrief, and the mapping table below
points ahead to sections 05, 07 and 08, where each move gets its real mechanism.

**The web app.** A static page on the course site replaces the paper and the bookkeeping, not the
claps: the projector keeps the beat, claps for the ECUs nobody holds and logs every frame; each
student's phone holds the ECU card, opens the secret envelopes and keeps that ECU's strikes
privately. Even one student can play. The design is in `research_notes/CAN bus/webapp-game.md`.

## The story

The room is the bus of one car: the course's electric car, driving from Prague to Brno on the D1
at night. The ECUs sit at the table at the front. The rest of the class rides along as data
loggers. Each round is one moment of the drive, and each round adds one rule:

| Round | Moment of the drive | New rule | Lesson in one line |
|---|---|---|---|
| 1 | Ignition on | announce a topic, keep it or ignore it | a frame names its content, everyone hears it, each ECU filters |
| 2 | Into the curve | clap the topic number | the lowest number wins, and the winner loses nothing |
| 3 | Under the power line | check, nod, "STOP!" | a frame is valid everywhere or nowhere |
| 4 | Yesterday's workshop visit | (none: a mistake) | two ECUs must never send one topic |
| 5 | Traffic jam *(optional)* | stopwatch | a busy bus starves the low-priority topics |
| 6 | The deer | strikes, whisper, leave the room | a broken ECU takes itself off the bus, and the brakes still work |

Arc: the car starts, the bus works, the bus is tested by noise and a workshop mistake, and in the
finale a water-damaged rain sensor starts garbling just as the driver brakes hard for a deer.
The rain sensor collects strikes, whispers, leaves the room, and the car stops safely. The
dashboard lights a lamp because topic 7 has gone silent.

**The lecturer is not a chairperson.** The lecturer plays three parts, none of which decides who
speaks: **the Clock** (the metronome is the bus's agreed bit rate), **the World** (says what
happens on the road, so some ECUs have news) and **the Workshop** (deals secret cards). The World
never says who speaks next or who won. Say this out loud in Round 1: a meeting room with a chair
would be a master, and CAN has none.

## Roles and terms

| Term in the game | Who or what | CAN term |
|---|---|---|
| **ECU** | a student at the table with a card | node |
| **Topic number** | the 4-bit number on the card | identifier |
| **Sentence** | "Topic 6: motor torque 55, check 10" | data frame |
| **Check** | the sum of the value's digits | CRC |
| **Quiet beats** | three beats with nobody clapping | intermission, bus idle |
| **Start clap** | the one clap everyone standing makes together | start of frame (hard sync) |
| **Topic beats** | four beats, highest bit first | arbitration field |
| **Clap** | one loud clap on the beat | dominant 0 |
| **Open hands** | hands held apart, palms forward, no sound | recessive 1 |
| **Sit down** | stayed open, heard a clap | lost arbitration |
| **Keep** | raise a hand while a topic you listen for is spoken | acceptance filter passes |
| **The nod** | knock once on the desk and nod, on the beat after the sentence | ACK |
| **"STOP!"** | shout it and slap the desk; everyone at the table echoes it | error flag |
| **Strikes** | the tally on the scoreboard | transmit error counter (TEC) |
| **Whisperer** | may only whisper "stop" | error passive |
| **Out of the room** | walks to the back wall | bus off |
| **Bus scribe** | student at the board who writes what the room heard each beat | the bus level |
| **Strike keeper** | student at the board who keeps the scoreboard | (counters are inside each node; see cheats) |
| **Loggers** | everyone else, with a log sheet | listen-only nodes, `candump` |
| **Frame** | one turn, from start clap to the end of the quiet beats | frame |

Loggers write every frame but never nod and never shout "STOP!": that is exactly what a
listen-only CAN node does, and the same thing the `candump` demo at the end of the lecture does.

## The rules, in full

These are the rules after Round 6. Each round introduces only its own line.

1. **Speak only after three quiet beats.** Everyone counts them under their breath.
2. **If you have news, stand up during the quiet beats.** The World's line or your card says when.
3. **On the fourth beat, everyone standing makes the start clap**, together.
4. **Then clap your topic number, one beat per bit, highest bit first:** clap for 0, open hands
   for 1. Read the beats off your card; they are printed as `CLAP` and `open`.
5. **If you showed open hands and heard a clap on the same beat, sit down at once.** One clap or
   many: both count as a clap. You judge it yourself; nobody referees.
6. **If you are still standing after the fourth topic beat, you won.** Say your sentence:
   "Topic 6: motor torque 55, check 10." Never say your ECU's name.
7. **Every ECU at the table listens and checks.** Keepers of that topic raise a hand while it is
   spoken. Everyone, keeper or not, adds the digits and compares with the check.
8. **On the beat after the sentence, every ECU at the table except the speaker gives the nod**,
   whether or not it keeps the topic. Losers of this frame nod too.
9. **If anything was wrong — the check, two voices, a beat you were unsure about — shout
   "STOP!".** Everyone at the table echoes "STOP!". Keepers lower their hands and write nothing.
   The speaker stays standing and tries again in the next frame, against everyone else.
10. **If nobody nods, the speaker shouts "STOP!" and tries again.**
11. **If you did something on a beat other than what your card says, shout "STOP!".** You hear
    your own mistake; that is how a CAN node catches its own bit errors.
12. **Strikes.** Shouting is free. A speaker whose sentence is stopped gets **+8**; each of its
    sentences that goes through takes **−1**. At **16** you are a **whisperer**: you may only
    whisper "stop", which nobody acts on, and after each sentence of yours you sit out the next
    frame. At **32** you go **out of the room**. You come back after four clean frames, with zero
    strikes.
13. **After a clean sentence the speaker sits down; keepers write the value on their card.**

### Edge cases

- **Nobody stands.** The Clock keeps beating, nobody claps, the bus is idle. That is fine and
  normal.
- **Everyone sits down? Impossible.** You sit only if you heard a clap, and whoever clapped does
  not sit. If nobody clapped, nobody sits. So every beat leaves at least one ECU standing, and
  with unique topic numbers exactly one is left after the fourth beat.
- **Two still standing after the fourth beat.** They have the same topic number: Round 4.
- **Someone forgets to clap a 0.** If someone else clapped too, the room cannot tell and nothing
  happens. If they were the only 0, the room hears silence: the others stay up, and the one who
  forgot hears a beat different from their card and shouts "STOP!" (rule 11). The bus shows what
  you did, not what you meant. In CAN that is a bit error.
- **Someone claps a 1 by mistake.** Others sit down wrongly. The clapper heard its own wrong beat
  and must shout "STOP!" (rule 11). If nobody notices, the wrong topic wins, which is why real
  controllers compare every bit they send with the bus in hardware.
- **A clap lands between beats, or the scribe cannot tell.** Anyone unsure shouts "STOP!". An
  unreadable bit is an error, not a judgment call.
- **The winner never notices it won.** An ECU that clapped all its 0s cannot know whether anyone
  else clapped. Point this out in Round 2: it is why arbitration costs the winner no time.

## Materials

### ECU cards

Print each card A5 landscape: the topic number in binary 4 cm high, the beats row under it, then
the rest small. The ECU name is printed small and marked "never say this". A log line at the
bottom has room for three kept values. Cards marked **10** are used in the 10-player variant,
**20** add to it for 15–20 players, **30** add to that for about 30.

| Set | ECU (never say) | Topic | Beats: start + 4 | Sentences, in order | Period in the car | Keeps topics |
|---|---|---|---|---|---|---|
| 10 | Brake pedal sensor | 1 · 0001 · 0x1 | CLAP · CLAP CLAP CLAP open | brake request 0, check 0 · brake request 95, check 14 | 10 ms | none |
| 10 | ABS/ESP | 2 · 0010 · 0x2 | CLAP · CLAP CLAP open CLAP | vehicle speed 87, check 15 · speed 62, check 8 · speed 31, check 4 · speed 0, check 0 | 10 ms | 1, 5, 3 |
| 10 | Motor controller | 6 · 0110 · 0x6 | CLAP · CLAP open open CLAP | motor torque 55, check 10 · torque 20, check 2 | 10 ms | 1, 2 |
| 10 | Rain sensor | 7 · 0111 · 0x7 | CLAP · CLAP open open open | rain level 34, check 7 | 100 ms | 2 |
| 10 | Dashboard | 12 · 1100 · 0xC | CLAP · open open CLAP CLAP | lamps 00, check 0 · lamps 07, check 7 | 100 ms | 2, 6, 7, 9 |
| 10 | Radio | 14 · 1110 · 0xE | CLAP · open open open CLAP | volume 40, check 4 | 1000 ms | 2 |
| 20 | Steering angle sensor | 5 · 0101 · 0x5 | CLAP · CLAP open CLAP open | steering angle 12, check 3 | 10 ms | none |
| 20 | Battery management | 9 · 1001 · 0x9 | CLAP · open CLAP CLAP open | charge 76, check 13 | 100 ms | 6 |
| 30 | Yaw-rate sensor | 3 · 0011 · 0x3 | CLAP · CLAP CLAP open open | yaw rate 18, check 9 | 10 ms | none |
| 30 | Climate control | 10 · 1010 · 0xA | CLAP · open CLAP open CLAP | cabin temperature 21, check 3 | 1000 ms | 9 |
| bonus | Airbag | 0 · 0000 · 0x0 | CLAP · CLAP CLAP CLAP CLAP · *open (stuff beat)* | crash status 00, check 0 | 1000 ms | 2 |

Brakes and chassis get low numbers, comfort high ones, so the curve in Round 2 has dropouts on
the first and on the last beat. Sensors that keep nothing still check and nod: the nod is not
filtering.

### Secret cards (envelopes, dealt by the Workshop)

| Card | To | Text |
|---|---|---|
| **Interference** (Round 3) | Dashboard | "You are next to the power line. The next time topic 2 is spoken, you hear the check wrong: shout STOP!" |
| **New radio** (Round 4) | Radio | "Yesterday's workshop flashed you with the wrong software. Your topic is now **6 · 0110**: beats CLAP · CLAP open open CLAP. Keep your own sentence: volume 40, check 4." |
| **Water in the connector** (Round 6) | Rain sensor | "Water got into your connector. Every check you say is one too low: rain level 34, check 6. Once you are a whisperer: while topic 2 is spoken, whisper stop." |
| **Workshop fix** (end of Round 4) | Radio | "Reflashed. Your topic is 14 · 1110 again." |

### Log sheet (loggers)

One row per frame: frame number · bus beats (start + 4) · topic heard · value · check OK? · nod
heard? · STOP? A row that ended in "STOP!" is kept and crossed through. In Round 5 one logger
gets the stopwatch.

### Board layout

```
+------------------------------+---------------------------+----------------------+
| BUS (scribe)                 | STRIKES (keeper)          | RULES SO FAR         |
| fr  S  b3 b2 b1 b0  topic    | ECU topic  strikes  state | 1 announce a topic   |
|  1  0  0  1  1  0   6  ok    |  1          0    active   | 2 clap the number    |
|  2  0  0  1  1  1   7  STOP  |  2          0    active   | 3 check, nod, STOP   |
|  …                           |  7         16    WHISPER  | 4 one topic, one ECU |
|                              |  …                        | 6 strikes            |
+------------------------------+---------------------------+----------------------+
| ROUND / moment of the drive:  6 — the deer          speed: 62 km/h            |
+-------------------------------------------------------------------------------+
```

The scribe writes 0 for a beat with any clap and 1 for a silent beat. The strike columns list
topics, because names are never said.

### For the lecturer

- A metronome app through the room speaker, woodblock sound, no accent: **60 bpm** for Rounds 1–2,
  **80 bpm** from Round 3. Conduct the beat with one arm too; in a noisy room people follow the
  hand.
- The cards, the four envelopes, log sheets, a phone stopwatch, two board markers.
- Deal cards and seat the ECUs at the front during the break before section 01 ends; that saves
  the setup minutes.

## Lecturer script

Times are for the 15–20 player set at the tempos above. Each frame takes about 12 s at 60 bpm
and 10 s at 80 bpm, plus talk.

### Setup — 2 min

> "This room is the bus of our car. You at the front are its ECUs. Everybody else is a data
> logger: you write down everything and never interfere. I am the Clock and the World: I keep the
> beat and tell you what happens on the road. I never tell you who speaks."

Name the bus scribe and the strike keeper. Every ECU reads its topic number aloud once.

### Round 1 — Ignition on (broadcast and filtering) — 2 min

**Rule:** the speaker stands, announces topic and value, never a name. Keepers raise a hand.

- World: "Ignition on, the car rolls." ABS stands: "Topic 2: vehicle speed 87, check 15."
  Motor, rain sensor, dashboard, radio raise hands; pedal, steering, battery do not.
- World: "The battery reports." Battery: "Topic 9: charge 76, check 13." One hand: the dashboard.
  (10 players: motor, "Topic 6: motor torque 55, check 10"; one hand: the dashboard.)

**Point out:** nobody was addressed. Every ECU heard every word and decided for itself. The
battery's sentence used everyone's time for one keeper: that time is the bus load of section 08.

**Lesson:** a frame names its content, not its receiver.

### Round 2 — Into the curve (arbitration) — 4 min

**Rule:** quiet beats, start clap, topic beats; open hands and heard a clap: sit down. Winner
speaks. Losers stand up again at the next quiet beats.

Warm-up, 30 s: the whole room claps topic 5 together (CLAP · CLAP open CLAP open). Then the left
half claps topic 5 and the right half topic 6 at the same time; the right half sits on beat b1.
Everyone has now done arbitration once.

World: "A curve: steering, motor, rain sensor, battery, dashboard and radio all have news." All
six stand. Expected frames (the scribe's bus row equals the winner's beats each time):

| Frame | Standing | b3 | b2 | b1 | b0 | Wins |
|---|---|---|---|---|---|---|
| a | 5, 6, 7, 9, 12, 14 | 9, 12, 14 sit | all open: nobody sits | 6, 7 sit | — | **5** |
| b | 6, 7, 9, 12, 14 | 9, 12, 14 sit | all open | all open | 7 sits | **6** |
| c | 7, 9, 12, 14 | 9, 12, 14 sit | — | — | — | **7** |
| d | 9, 12, 14 | all open: nobody sits | 12, 14 sit | — | — | **9** |
| e | 12, 14 | open | open | 14 sits | — | **12** |
| f | 14 | open | open | open | clap | **14**, alone |

10 players: frames b, c, e, f only. Play a and b at full attention, then let c–f run at speed.

**Point out:** (a) two ECUs dropped on the same beat; (b) on beats where everyone was open, nobody
sat; (c) frame b was decided on the last beat; (d) the bus row on the board is exactly the
winner's number, so the winner lost nothing; (e) the radio waited five frames: a high number means
waiting, and section 08 calculates how long; (f) the radio claps alone the same way, it never
knows whether there was a contest.

Optional contrast, 1 min: replay frame e the Ethernet way. The dashboard and the radio speak their
sentences at the same time, hear the mess, both stop, each rolls a die and waits that many beats.
Both sentences were lost and time was wasted. CAN resolves the clash; Ethernet's CSMA/CD destroys
it and backs off (`three-ways-to-share`).

Bonus, 1 min (bit stuffing): hand out the airbag card. Its beats are five claps in a row, start
clap plus 0000, so it must add one open beat, the stuff beat, before speaking; everyone ignores
that beat. Six claps in a row never occur in a valid frame, which is why a real error flag is six
dominant bits: everyone recognizes it.

**Lesson:** the lowest topic number wins, and the winner's frame is not damaged.

### Round 3 — Under the power line (check, nod, STOP) — 3 min

Switch the metronome to 80 bpm. Deal the **interference** card to the dashboard.

**Rule:** everyone at the table checks the digits; on the beat after the sentence, everyone at the
table except the speaker nods; if anything is wrong, shout "STOP!", everyone echoes it, keepers
write nothing, the speaker tries again.

- World: "The speed changes, and the radio wants to say something." ABS and radio stand. ABS wins
  on b3: "Topic 2: speed 62, check 8." The dashboard shouts "STOP!", the table echoes, the
  keepers lower their hands. Ask the motor: "Did you hear it fine?" Yes. "Do you keep it?" No.
- Next frame: ABS (still standing) and radio. ABS wins again, clean sentence, the nod.
- Next frame: radio alone, clean, the nod.
- 20 s: "Everybody, switch off." All ECUs cover their ears. The pedal stands and speaks. Nobody
  nods; the pedal shouts "STOP!" itself (rule 10).

**Point out:** the motor heard the sentence fine and threw it away anyway, so every ECU holds the
same data. The nod came from everyone, including ECUs that ignore topic 2: the speaker learns
that somebody got it, never who.

**Lesson:** a frame is valid everywhere or nowhere.

### Round 4 — Yesterday's workshop visit (duplicate topic) — 2 min

Deal the **new radio** card.

- World: "The motor reports torque, the radio changes volume, the dashboard updates its lamps."
  Motor, radio, dashboard stand. On b3 the dashboard sits. On b2, b1, b0 the motor and the radio
  make the same beats. **Two are still standing.** Both speak at once. The table hears two voices:
  "STOP!". Both stand again, and it happens again.
- Stop after the second clash. Deal the **workshop fix**.

**Point out:** CAN cannot tell the two apart, because the topic number names content, not the
sender. In a real car both would collect +8 per clash and both would end up out of the room,
taking the motor's torque topic with them, all because of a radio. Unique numbers are the
designer's job, in the DBC (section 06). If the two had said the same value, nobody would have
noticed.

**Lesson:** two ECUs must never send the same topic.

### Round 5 — Traffic jam, optional (bus load) — 3 min

Use it instead of Round 4 if the class wants more arbitration, or skip it.

World: "Stop-and-go. Pedal, ABS and motor have news every third frame: frames 1, 4, 7. Dashboard
and radio have news from frame 1." The stopwatch logger starts at the first start clap and
records the seconds someone is speaking.

| Frame | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|
| Wins | 1 | 2 | 6 | 1 | 2 | 6 | 1 | 2 | 6 |

The dashboard and the radio stand through all nine and never speak. World: "The jam clears: the
fast ones now report every sixth frame." In the gaps the dashboard speaks, then the radio.

**Point out:** the bus was busy the whole time, close to 100 % load. Priority protected the brake
topics, but nothing protected the dashboard. That is why a car's bus runs at a low load (our car's
7.45 %, section 08) and why response times are calculated, not hoped for.

**Lesson:** priority bounds the wait only for the topics at the top.

### Round 6 — The deer (strikes, whisperer, out of the room) — 5 min

Deal the **water in the connector** card to the rain sensor. Introduce the strike rule (rule 12)
and draw the scoreboard: +8 for a stopped sentence of yours, −1 for a good one, 16 whisperer,
32 out of the room.

| Frame | World says | Standing | Wins | What happens | Rain sensor strikes |
|---|---|---|---|---|---|
| 1 | "It starts to rain." | 7, 12 | 7 | check one too low → STOP | 8 |
| 2 | "The radio wants to speak." | 7, 12, 14 | 7 | STOP | **16: whisperer**, sits out frame 3 |
| 3 | **"Deer! Full brake!"** | 1, 12, 14 | 1 | "brake request 95, check 14", clean | 16 |
| 4 | "ABS takes over." | 2, 6, 7, 12, 14 | 2 (b2) | rain sensor whispers "stop"; nobody reacts; clean | 16 |
| 5 | | 6, 7, 12, 14 | 6 (b0) | regen torque 20, clean | 16 |
| 6 | | 7, 12, 14 | 7 | STOP (the others still shout) | 24, sits out frame 7 |
| 7 | | 2, 12, 14 | 2 | speed 31, clean | 24 |
| 8 | | 7, 12, 14 | 7 | STOP | **32: out of the room**, walks to the back |
| 9 | "Almost stopped." | 2, 12, 14 | 2 | speed 0, clean | — |
| 10 | | 12, 14 | 12 | "lamps 07, check 7": the dashboard noticed topic 7 went silent | — |

World: "The car stopped short of the deer. The bus survived its broken ECU."

If time remains: after four clean frames the rain sensor walks back in with zero strikes, wins,
says check 6, gets "STOP!" again. Real ECUs often limit how often they restart and store a fault
code; the dashboard lamp sends the driver to the workshop.

**Point out:** losing arbitration is never a strike (frames 3–5). Whispering destroyed nothing
(frame 4): the ABS frame went through. The healthy ECUs still stopped the whisperer's own garbled
sentences (frame 6), because they were still active. Nobody voted the rain sensor out: it counted
its own strikes and left.

**Lesson:** fault confinement lets a broken ECU silence itself instead of jamming the bus.

### Debrief — 3 min

Open with `where-the-room-stops`, then show this table.

| In the game | In CAN | Deck |
|---|---|---|
| everyone hears every sentence | broadcast: every node receives every frame | 01 `rules-of-the-room` |
| a topic, never a name | identifier names the content, not sender or receiver | 01 `rules-of-the-room`, 02 `not-a-post-office` |
| raising a hand to keep | acceptance filtering | 01 `rules-of-the-room` |
| quiet beats | intermission, 3 recessive bits; bus idle | 05 `data-frame` |
| start clap, all together | start of frame, a dominant bit every node hard-syncs on | 04 `bit-timing` |
| clap / open hands; one clap beats silence | dominant / recessive, wired-AND | 04 `dominant-and-recessive` |
| open hands, heard a clap: sit down | bitwise arbitration, lowest identifier wins | 01 `clapping-the-topic`, 05 `arbitration-on-the-wire` |
| losers listen, nod, retry at the next quiet beats | loser becomes a receiver; automatic retry when idle | 05 `arbitration-on-the-wire` |
| the board's bus row = the winner's number | arbitration is non-destructive, costs the winner nothing | 05 `arbitration-on-the-wire` |
| stuff beat after five equal beats | bit stuffing | 05 `bit-stuffing` |
| check = digit sum | 15-bit CRC | 07 `five-checks` |
| everyone nods, keeper or not | ACK slot driven dominant by every correct receiver | 05 `acknowledgement` |
| nobody nods: speaker shouts STOP | ACK error | 05 `acknowledgement`, 07 `five-checks` |
| a beat different from your card: STOP | bit error (transmitter reads back each bit) | 07 `five-checks` |
| "STOP!" and its echo, everyone discards | active error flag, others' flags, global rejection | 01 `strikes`, 07 `error-frame` |
| the speaker tries again, against everyone | automatic retransmission, re-arbitrated | 07 `error-frame` |
| two standing after b0 | duplicate identifier: bit error in the data field | 01 `where-the-room-stops`, 06 `dbc` |
| strikes +8 / −1 | TEC: +8 transmit error, −1 per successful frame | 07 `fault-confinement` |
| whisperer; sits out a frame after speaking | error passive: passive flag of 6 recessive bits; suspend transmission | 07 `error-frame`, `fault-confinement` |
| out of the room; back after quiet frames | bus off; recovery after 128 × 11 recessive bits | 07 `fault-confinement` |
| dashboard notices topic 7 is silent | application timeout monitoring | 05 `acknowledgement`, 06 `counters-and-checksums` |
| radio waits through the curve and the jam | arbitration latency, bus load, response time | 08 `bus-load`, `response-time` |
| loggers | listen-only nodes, `candump` | 10 demo |

Close with the scale: at 80 bpm one beat is 0.75 s; at 500 kbit/s one bit is 2 µs. The whole
20-minute game, about 1500 beats, is **3 ms of a real bus**, less than one ABS control cycle.

## Faithfulness check and where the game cheats

Checked against Bosch CAN Specification 2.0 (1991; Part A/B, chapters on error handling and fault
confinement) and ISO 11898-1. The deck's section 07 states the same rules.

**Faithful:** broadcast with content identifiers; filtering after reception; wired-AND
arbitration, MSB first, lowest wins, winner unaffected, losers become receivers and retry when the
bus is idle; ACK by every correct receiver regardless of filtering, the sender learning only "at
least one"; one node's local error destroying the frame for all; retransmission that competes in
arbitration again; +8 for the transmitter, −1 per successful transmission, no change for lost
arbitration; error-passive flags that cannot destroy other nodes' frames, while active receivers
still destroy the passive node's own bad frames; the passive transmitter's extra wait; bus off by
the node's own counter, not a vote; listen-only loggers that neither ACK nor signal errors.

**Where the game cheats** — say these in the debrief:

1. **A shared beat from the lecturer.** CAN has no clock line or clock master. Each node runs its
   own oscillator at the agreed bit rate, hard-syncs on the start-of-frame edge and resynchronizes
   on every recessive-to-dominant edge (`bit-timing`). The metronome stands for the agreed bit
   rate.
2. **The World decides when news is due.** In a car each ECU's own timer or event decides that.
   The script does it here to keep the outcomes planned.
3. **4-bit topic numbers.** Real base identifiers have 11 bits (29 extended); the RTR and IDE bits
   also take part in arbitration.
4. **The data is spoken, not clapped.** In CAN the control field, data, CRC, delimiters, ACK and
   end of frame are bits on the same wire; arbitration is only the first 12.
5. **A digit-sum check.** The real CRC has 15 bits and catches far more; CAN also checks stuffing,
   form, bit and ACK errors (five checks in section 07).
6. **"STOP!" is a word.** An active error flag is six dominant bits that break the stuffing rule,
   so the others detect a stuff error and add their own flags: the echo. A CRC error is flagged
   only after the ACK delimiter, so the nod comes before the "STOP!" in reality.
7. **Only the transmitter's counter is kept, and kept in public.** Real nodes also keep a receive
   counter (REC: mostly +1, sometimes +8, −1 per good frame; error passive also when REC passes
   127). Counters are private to each node; no one else knows them. Round 3 and Round 4 should
   also have added +8 to the speakers; the game starts counting in Round 6.
8. **Thresholds divided by 8.** Real error passive starts when TEC exceeds 127 and bus off when it
   exceeds 255: 16 and 32 consecutive transmit errors. The game keeps +8 and −1 but passes at 16
   and 32: 2 and 4 errors.
9. **"Sit out one frame" for the passive wait.** The real suspend transmission is 8 recessive bits
   after the intermission; any node that starts in that time goes first.
10. **"Four clean frames" for recovery.** The standard requires 128 occurrences of 11 consecutive
    recessive bits, about 128 frame ends on a busy bus; many ECUs wait for their software to allow
    the restart.
11. **The rain sensor whispers by instruction.** Its receive fault is scripted. A real node that
    sees good frames as bad raises its own REC and goes passive the same way, which is the point of
    the rule.
12. **A lone speaker.** With nobody to nod, a real transmitter's TEC stops rising once it is error
    passive (an ACK-error exception), so a node alone on the bus does not go bus off. The game
    does not count strikes for that demo.
13. **The room has no wires.** Nothing here models CAN_H/CAN_L, voltage levels, termination or
    propagation delay (`where-the-room-stops`).

## Risks and fixes

| What goes wrong | Fix |
|---|---|
| Too slow; the 20 minutes run out | ECUs seated and cards dealt in the break; run Round 2 frames c–f at speed; Round 5 is optional; Round 4 can shrink to one clash; drop the finale's frames 5 and 10 |
| Claps out of sync, bits unreadable | the whole-room warm-up in Round 2; 60 bpm until it works; conduct with an arm; the beats printed on each card; an unclear beat is "STOP!" by rule, so a sync failure becomes the lesson on bit errors and resynchronization |
| Students stand or sit late | stand only during the quiet beats; sit "at once" means before the next beat; the scribe calls the beat aloud for the first frames |
| Loud room, nobody hears a single clap | the open-hands gesture makes 1 visible; claps are strong two-handed claps; ECUs in one line facing the class |
| Shy students | ECUs volunteer; every spoken line is printed; claps and nods are collective; loggers have a written job with no exposure |
| The winner forgets to speak, or says its name | rule 6 on the card; the World waits two beats, then prompts "topic first" |
| Someone ignores the strike rule and keeps shouting | shouting is free, but the strike keeper's board makes the whisperer's state public; the World reads it out at 16 and 32 |
| Arithmetic slows the check | values are two digits; the check is printed for the speaker; listeners only add two digits |
| Students read the World as a master | say it in setup and in the debrief: the World never says who speaks or who won |
| A large class (about 30) leaves loggers idle | give loggers a column each (bus beats, check, nod, STOP) and compare logs after Round 6; one logger runs the stopwatch |

## Class-size variants

| Players | ECUs | Board jobs | Loggers | Changes |
|---|---|---|---|---|
| about 10 | the 6 cards marked 10 | scribe, strike keeper | 2 | Round 1 uses the motor instead of the battery; Round 2 plays frames b, c, e, f |
| 15–20 (default) | 8: sets 10 and 20 | scribe, strike keeper | 5–10 | as scripted |
| about 30 | 10: sets 10, 20, 30 | scribe, strike keeper, stopwatch | about 17 | yaw rate and climate speak in Round 1 and stand in no planned contest; they check, nod and shout like the others; Round 5 recommended |

## Prior work borrowed from

No published classroom game for CAN arbitration turned up; trainers explain arbitration with bus
waveforms (Kvaser, https://kvaser.com/lesson/can-basics-bit-wise-arbitration-differential-signals/)
or as a mechanism, Koopman's "binary countdown"
(https://users.ece.cmu.edu/~koopman/lectures/ece649/14_can.pdf). The mechanics come from these:

- **Secret action cards that corrupt messages**: CS Unplugged, *Tablets of Stone* (network
  protocols), https://classic.csunplugged.org/activities/network-protocols/ and the STEM Learning
  version with action cards, https://stem.org.uk/system/files/elibrary-resources/2017/05/network_protocols-v3.1.pdf
  → the interference, new-radio and water cards.
- **Students as visible bits, standing or holding a sign**: CS Unplugged binary numbers,
  https://classic.csunplugged.org/activities/binary-numbers/ ; Computing At School teacher notes,
  https://www.computingatschool.org.uk/media/xcmfl4iv/0100alldonebynumbersteachernotes.pdf
  → open hands as a visible 1, standing as "has a frame".
- **Contention and blocking as a group experience**: CS Unplugged, *The Orange Game*,
  https://classic.csunplugged.org/activities/routing-and-deadlock/ → the traffic jam and the
  radio's wait.
- **CSMA/CD collision and backoff, discussed in class**: Ursinus CS475,
  https://billjr99.github.io/Ursinus-CS475-Spring2021/Activities/PhysicalLayer → the Ethernet
  contrast with the die.
- **Party conversation as frame fields**: NetBurner, https://www.netburner.com/learn/the-can-protocol-of-course-we-can-can-you/
  (see `research_notes/CAN bus/analogy.md`); the game keeps its "please repeat that" and drops
  its "introduce yourself", which would make the identifier a sender.
