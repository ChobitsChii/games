class_name MusicSynth
extends RefCounted
## Komposition für die Hintergrundmusik von Neon Breakout (reine Daten, ohne Nodes).
## A-Moll, 112 BPM, 8 Takte als nahtloser Loop: Bassdrum, Hi-Hat, Bass, Arpeggio
## (mit Echo) und ein weicher Akkord-Teppich. Die Klänge selbst erzeugt MusicRenderer.

enum Kind { KICK, HAT, BASS, ARP, PAD }

const RATE := 22050
const BPM := 112.0
const BEATS := 32
const CHORD_BEATS := 8
## Akkorde in MIDI-Noten (Am, F, C, G): Basston und drei Akkordtöne.
const CHORDS: Array = [
	{"root": 45, "notes": [57, 60, 64]},
	{"root": 41, "notes": [53, 57, 60]},
	{"root": 48, "notes": [55, 60, 64]},
	{"root": 43, "notes": [55, 59, 62]},
]
## Bassmuster pro Takt in Achteln (Halbtöne über dem Basston).
const BASS_PATTERN: Array = [0, 0, 12, 0, 0, 12, 7, 0]
## Arpeggio in Sechzehnteln (Index in die Akkordtöne), eine Oktave höher gespielt.
const ARP_PATTERN: Array = [0, 1, 2, 1, 2, 1, 0, 1]
## Die ersten Takte laufen ohne Arpeggio (ruhiger Einstieg).
const ARP_START_BAR := 2
const PAD_FADE_SECONDS := 0.9
const PAD_SEGMENT_SECONDS := 0.25


static func beat_samples() -> float:
	return 60.0 / BPM * RATE


## Länge des Loops in Samples.
static func total_frames() -> int:
	return int(round(BEATS * beat_samples()))


static func midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Alle Klangereignisse des Songs. Ein Ereignis ist ein Dictionary mit
## kind, start (Sample, darf negativ sein: der Loop schließt sich), length (Samples),
## freq, vol, duck (wird vom Bassdrum-Pumpen abgesenkt), seg_from/seg_to (Teilstück).
static func build_events() -> Array:
	var events: Array = []
	var beat := beat_samples()

	for b in BEATS:
		events.append(_event(Kind.KICK, b * beat, 0.0, 0.30, 0.62, false))
		events.append(_event(Kind.HAT, (b + 0.5) * beat, 0.0, 0.08, 0.55, false))

		var chord: Dictionary = CHORDS[int(b / CHORD_BEATS)]
		for half in 2:
			var step := (b % 4) * 2 + half
			var note: int = chord["root"] + int(BASS_PATTERN[step])
			events.append(_event(Kind.BASS, (b + half * 0.5) * beat, midi_to_hz(note), 0.30, 0.40, true))

	for s in BEATS * 4:
		if s < ARP_START_BAR * 16:
			continue
		var chord: Dictionary = CHORDS[int(s / (CHORD_BEATS * 4))]
		var note: int = int(chord["notes"][int(ARP_PATTERN[s % 8])]) + 12
		var start := s * beat / 4.0
		events.append(_event(Kind.ARP, start, midi_to_hz(note), 0.20, 0.16, true))
		# Echo eine punktierte Achtel später, leiser.
		events.append(_event(Kind.ARP, start + 0.75 * beat, midi_to_hz(note), 0.14, 0.05, true))

	var chord_seconds := CHORD_BEATS * beat / RATE
	for chord_index in CHORDS.size():
		for note: int in CHORDS[chord_index]["notes"]:
			var start := chord_index * CHORD_BEATS * beat - PAD_FADE_SECONDS * 0.5 * RATE
			var whole := _event(Kind.PAD, start, midi_to_hz(note), chord_seconds + PAD_FADE_SECONDS, 0.075, true)
			var segment := int(PAD_SEGMENT_SECONDS * RATE)
			for from in range(0, whole["length"], segment):
				var part: Dictionary = whole.duplicate()
				part["seg_from"] = from
				part["seg_to"] = mini(from + segment, whole["length"])
				events.append(part)
	return events


static func count_kind(events: Array, kind: Kind) -> int:
	var count := 0
	for e: Dictionary in events:
		if e["kind"] == kind:
			count += 1
	return count


static func _event(kind: Kind, start: float, freq: float, seconds: float, vol: float, duck: bool) -> Dictionary:
	var length := int(seconds * RATE)
	return {
		"kind": kind,
		"start": int(round(start)),
		"length": length,
		"freq": freq,
		"vol": vol,
		"duck": duck,
		"seg_from": 0,
		"seg_to": length,
	}
