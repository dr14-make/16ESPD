# CAN bus lecture: which analogy to use

## What educators and trainers use today

| Analogy | Who uses it (source) | What they use it for |
|---|---|---|
| Nervous system / body | CSS Electronics intro, https://www.csselectronics.com/pages/can-bus-simple-intro-tutorial ; IMI MotorPro, https://www.theimi.org.uk/industry-latest/motorpro/how-it-works-can-bus | Motivation only ("the bus links the body parts"). No mechanisms. |
| Human speech and language layers | CSS Electronics (same page): physical layer = "vocal cords", CAN frame rules = "alphabet and grammar", J1939/OBD2 = "languages like German or English", a logger = "sound recorder" | Layering: physical, data link, higher-layer protocols |
| Protocols as languages, gateway as translator, modules "talking over each other" | Mechanic trade press, https://trade.mechanic.com.au/news/can-bus-systems-made-easy-for-non-electricians | Gateways, priority |
| Group chat | HP Academy, https://hpacademy.com/technical-articles/get-started-with-can-bus ; chatroom: https://autosecurityy.gitbook.io/home/protocols | Broadcast, shared wire |
| Cocktail party (cough = SOF, introduce yourself = ID, one person yields = arbitration, "please repeat that" = CRC/ACK) | NetBurner, https://www.netburner.com/learn/the-can-protocol-of-course-we-can-can-you/ | A walk through the frame fields |
| Dinner-party conversation | https://eathealthy365.com/an-automotive-can-bus-system-explained/ (weak source) | General |
| Party-line telephone | Wikipedia-derived explainers (search result) | Shared medium, collisions |
| Error frame = everyone loudly says "start over" | Student CAN intro, https://pt.slideshare.net/SNViswanathaReddy/canintroductiondocx | Error frame |
| "Here's a message containing data labeled X", not "a message for node X" | Kvaser, https://kvaser.com/lesson/addressing-arbitration-identification-message-reaches-controller/ | Content-based addressing. A framing, not a full analogy |
| Producer/consumer, publish/subscribe with the ID as the topic | B&R, https://www.br-automation.com/en/products/network-and-fieldbus-modules/additional-information/message-transfer-according-to-the-producer-consumer-principle/ ; Vector e-learning (receiver-selective addressing), https://elearning.vector.com/course/view.php?id=20 ; OpenMV, https://docs.openmv.io/openmvcam/tutorial/hardware/can/can-basics.html | Broadcast and filtering. OpenMV and HiveMQ point out there is no broker |
| "Binary countdown" | Koopman, CMU 18-649, https://users.ece.cmu.edu/~koopman/lectures/ece649/14_can.pdf | Arbitration, taught as a mechanism rather than an analogy |
| Railway (trains, wagons, stations) | The current deck. I found no published source for it, French automotive training included (eduscol, nomadeducation) | Frame structure |

What I found:
- No mainstream source carries one analogy through all of CAN.
- Industry trainers (Vector, Kvaser, TI SLOA101B, CiA) explain arbitration and errors directly with bus levels and do not use an analogy for them.
- The analogies that keep coming back are **people talking in a shared room** (conversation, party, chat), used for broadcast and arbitration, and **language layers**, used for OSI. CSS Electronics, probably the most widely read CAN intro, uses the speech/language model for layering.
- I found no published post-office, PA-announcement or bulletin-board analogy for CAN. I evaluated them anyway because they are obvious choices.

## How each candidate scores on the seven criteria

Legend: F = fits, S = strained, B = breaks, **M** = actively misleads (teaches something false about CAN).

### Railway (current deck)
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast, content ID | B | A train goes from one station to another. Every station "receiving" every train is not how railways work. |
| 2 | Bitwise arbitration | B **M** | Two trains on one track crash, or a dispatcher holds one back. That teaches either destructive collision or a central master. |
| 3 | Error handling, fault confinement | S | A defective train can be stopped, but no station can "cancel" a train for everyone. |
| 4 | ACK by any receiver | B | Nothing in a railway corresponds to it. |
| 5 | Wired-AND, differential, termination | S | Rails = medium is fine. Wired-AND has no equivalent. |
| 6 | Encapsulation / OSI | F | Train > wagons > passengers maps neatly to frame > bytes > signals (DBC packing). |
| 7 | Periodic messages, bus load | F | Timetable = periodic schedule, track occupancy = bus load. |

### Post office / letters
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | B **M** | Letters are addressed to a recipient. This is exactly the false model of CAN. |
| 2 | Arbitration | B | No shared medium. |
| 3 | Errors | S | "Return to sender" exists, but there is no global cancel and no fault confinement. |
| 4 | ACK | B **M** | A signed receipt from the addressee is the opposite of ACK by any node. |
| 5 | Physical | S | Roads and vans, but no wired-AND. |
| 6 | Encapsulation | F | Envelope inside envelope is the textbook OSI picture. For CAN that teaches nesting that classic CAN does not have (layers 3-6 are empty). |
| 7 | Periodic / load | S | Daily collection is a weak match. |

### Station or airport PA announcement
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | F | "Train 512 to Brno, platform 3" names the content. Everyone hears it and only the interested act. |
| 2 | Arbitration | B **M** | There is a single announcer, which implies a master. |
| 3 | Errors | B | No listener can cancel an announcement. |
| 4 | ACK | B | Nothing corresponds to it. |
| 5 | Physical | S | Loudspeaker wiring, nothing more. |
| 6 | OSI | S | Weak. |
| 7 | Periodic | F | Repeated announcements. |

### TV / radio broadcast (current deck, slide 5)
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | F | Every receiver gets every channel and picks one. |
| 2 | Arbitration | B **M** | One transmitter, and channels as frequencies suggest FDM. CAN is single-channel multi-master TDM. |
| 3 | Errors | B **M** | A TV viewer cannot make the station repeat anything. The current slide 5 says otherwise. |
| 4 | ACK | B | Nothing corresponds to it. |
| 5 | Physical | B | Radio, not a wired bus. |
| 6 | OSI | S | Weak. |
| 7 | Periodic | S | A program schedule, loosely. |

### Nervous system (CSS Electronics, IMI)
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | B **M** | Nerves are point-to-point wiring, which is the very harness CAN replaced. |
| 2 to 7 | All | B | Nothing beyond "it carries signals". Fine as a one-line hook, useless after that. |

### Publish/subscribe, topics (B&R, Vector, OpenMV)
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | F | ID = topic, receivers subscribe and filter. |
| 2 | Arbitration | B | Says nothing about the medium. |
| 3 | Errors | B | Nothing corresponds. |
| 4 | ACK | B | Nothing corresponds. |
| 5 | Physical | B | Nothing corresponds. |
| 6 | OSI | S | It is an application-layer concept. |
| 7 | Periodic | S | Loosely. |

Pub/sub suggests a broker, and CAN has none. It is also too abstract for students who are not networking specialists. Useful as a single sentence for students who know MQTT or ROS.

### Meeting room with a strict rulebook (conversation, party, group chat family)
| # | Criterion | | Reason |
|---|---|---|---|
| 1 | Broadcast | F | Everyone in the room hears everything. The rule: you announce a **topic** ("Vehicle speed: 87"), never a person's name. Each listener decides whether the topic matters to them. |
| 2 | Arbitration | F (with one stated rule) | Speakers start by beating out their topic number: a clap = 0 (dominant), silence = 1 (recessive). If you stayed silent and heard a clap, you stop and listen. The lowest number keeps talking, nothing is lost, and the winner never notices the contest. Free-form "polite yielding" would be S **M**, so the clap rule must be shown explicitly. |
| 3 | Errors, fault confinement | F | Anyone who hears something wrong shouts "STOP!" (breaking the speaking rules = error flag). Everyone, including those who heard it fine, discards the sentence, and the speaker repeats it. A person who keeps causing stops collects strikes. Past a threshold they may only object in a whisper (error passive), and past a higher one they leave the room (bus-off). |
| 4 | ACK | F | In the pause at the end, any listener nods. The speaker needs one nod from anyone, not from a particular person. No nod at all means nobody is listening, so repeat. |
| 5 | Physical | S | The clap/silence rule is wired-AND. The differential pair and termination have no room equivalent. |
| 6 | OSI | F | This is CSS Electronics' language model: air and voice = physical; turn-taking, clap rule, nods, STOP = data link; the agreed meaning of each topic number and its units = application (DBC). Layers 3-6 are empty because everyone is in one room: no forwarding (network), no splitting of long speeches (transport; ISO-TP/J1939 TP add it), no sessions, and one shared language (presentation). A gateway is an interpreter standing in the doorway to another room. |
| 7 | Periodic, load | F | Some people report on a fixed beat ("speed" every 10 ms). Bus load = the share of time someone is talking. Latency = how long a high-numbered (low-priority) topic waits for a gap. |

It actively misleads in one place: NetBurner's "introduce yourself = ID" makes the ID a sender identity. It must be a topic, which is why the topic rule above is stated. Two nodes must never send the same ID, but the ID still names the content, not the person.

## Recommendation

**Main analogy: the meeting room with a strict rulebook.** It is the only candidate that covers criteria 1-4 (the mechanisms that matter most) without teaching something false. It is also the family that educators already use (NetBurner, HP Academy, trade press), and it merges with CSS Electronics' speech/language model for the OSI slides.

**One contrast analogy: "CAN is not a post office."** Use it once, on the OSI/encapsulation slide. The post office is how students already picture networks: addressed letters, nested envelopes, a receipt from the addressee. Contrasting with it states the three CAN differences in one picture: no address, almost no nesting, ACK from anyone.

**Retire the railway and TV slides (4-5).** The railway's real strengths (wagons = bytes, timetable = periodic schedule) are both covered by the room ("a sentence of up to 8 words", "reporting on a fixed beat"). The TV slide is wrong about retransmission. If keeping the railway matters for continuity, limit it to one slide on frame anatomy and never use it for arbitration.

### Mapping table for the deck

| Meeting room | CAN |
|---|---|
| The room, the air | The bus (twisted pair) |
| A person at the table | ECU / node |
| The rulebook everyone follows | CAN protocol (ISO 11898-1) |
| A sentence, announced to the room | Frame (broadcast) |
| The topic said first ("Vehicle speed:") | Identifier: names content, not sender or recipient |
| Topic number: lower = more important | ID value = priority |
| The value after the topic, at most 8 words | Data field, 0-8 bytes (64 in CAN FD) |
| Listening only for topics you care about | Acceptance filtering |
| Clap = 0, silence = 1; a clap always wins over silence | Dominant/recessive, wired-AND |
| Everyone beats out their topic number together; whoever stays silent and hears a clap stops | Bitwise non-destructive arbitration (CSMA/CR) |
| The loser waits for the next gap and tries again | Automatic retry after lost arbitration |
| A nod from anyone in the pause | ACK slot, set by any receiver |
| "STOP!", which breaks the rules so everyone notices | Error flag (6 dominant bits, violates bit stuffing) |
| Everyone discards the sentence; the speaker repeats it | Global frame rejection and automatic retransmission |
| Strikes tallied per person | TEC/REC error counters |
| May only object in a whisper | Error passive (passive error flag) |
| Leaves the room | Bus-off |
| Air and voice / speaking rules / what topic 0x0C4 means and in what units | Physical / data link / application (DBC) |
| Everyone in one room, one language, short sentences | Layers 3-6 empty in classic CAN |
| Interpreter in the doorway to another room | Gateway between CAN networks |
| Reporting on a fixed beat | Periodic (cyclic) messages |
| Share of time someone is speaking | Bus load |
| Waiting for a gap as a low-priority topic | Arbitration latency |

### Where the deck should say out loud that the analogy stops working

1. **Arbitration slide.** "Real people don't clap their topic numbers in sync. CAN nodes do: every node samples the same bit at the same instant, the contest is deterministic, and it costs the winner zero time. Polite yielding is not the mechanism." Show the clap rule as an explicit rule of the game, then switch to the bit-level timing diagram.
2. **Physical layer slide.** "The room has no equivalent for CAN_H/CAN_L, differential voltage or the two 120 ohm terminations." Switch to the electrical picture here and do not stretch the analogy (no "echoes = reflections").

Optional third line on the error slide: in a real meeting, people who heard fine would keep the sentence. In CAN, everyone throws it away, so that all nodes always have the same data.
