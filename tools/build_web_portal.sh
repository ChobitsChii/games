#!/usr/bin/env bash
# Erstellt das GitHub Pages Portal in einem Zielverzeichnis (Standard: public/).
# Sammelt alle Web-Builds, integriert coi-serviceworker und generiert ein ansprechendes Dashboard.
# Aufruf: tools/build_web_portal.sh [zielverzeichnis]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-$ROOT/public}"

echo "== Erstelle Web-Portal in $TARGET_DIR =="
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 1. Stelle sicher, dass Web-Builds existieren
for project in "$ROOT"/*/project.godot; do
	[ -e "$project" ] || continue
	name="$(basename "$(dirname "$project")")"
	if [ ! -f "$ROOT/build/$name/web/index.html" ]; then
		echo "Web-Build für $name fehlt, baue jetzt..."
		"$ROOT/tools/build_all.sh" "$name"
	fi
done

# 2. Kopiere Web-Builds nach public/<spiel>/
for project in "$ROOT"/*/project.godot; do
	[ -e "$project" ] || continue
	name="$(basename "$(dirname "$project")")"
	[ -d "$ROOT/build/$name/web" ] || continue

	echo "Kopiere $name nach $TARGET_DIR/$name..."
	mkdir -p "$TARGET_DIR/$name"
	cp -r "$ROOT/build/$name/web/"* "$TARGET_DIR/$name/"
	
	# Icon falls SVG vorhanden auch kopieren
	if [ -f "$ROOT/$name/icon.svg" ]; then
		cp "$ROOT/$name/icon.svg" "$TARGET_DIR/$name/icon.svg"
	fi

	# coi-serviceworker sicherstellen
	cp "$ROOT/tools/web/coi-serviceworker.js" "$TARGET_DIR/$name/coi-serviceworker.js"
	if ! grep -q "coi-serviceworker.js" "$TARGET_DIR/$name/index.html"; then
		sed -i 's|<head>|<head>\n\t\t<script src="coi-serviceworker.js"></script>|' "$TARGET_DIR/$name/index.html"
	fi
done

# 3. coi-serviceworker und .nojekyll im Root
cp "$ROOT/tools/web/coi-serviceworker.js" "$TARGET_DIR/coi-serviceworker.js"
touch "$TARGET_DIR/.nojekyll"

# 4. Generiere responsives, modernes Dashboard index.html
cat << 'EOF' > "$TARGET_DIR/index.html"
<!DOCTYPE html>
<html lang="de">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Mini-Games Portal | Godot 4 Games</title>
	<script src="coi-serviceworker.js"></script>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
	<style>
		:root {
			--bg-primary: #0a0b12;
			--bg-card: rgba(18, 22, 38, 0.75);
			--border-card: rgba(255, 255, 255, 0.08);
			--text-main: #f1f5f9;
			--text-muted: #94a3b8;
			--text-dim: #64748b;
			--accent-cyan: #00d2ff;
			--accent-green: #10b981;
			--accent-amber: #f59e0b;
			--accent-pink: #ec4899;
			--accent-blue: #3b82f6;
			--glow-cyan: rgba(0, 210, 255, 0.25);
		}

		* {
			box-sizing: border-box;
			margin: 0;
			padding: 0;
		}

		body {
			background-color: var(--bg-primary);
			background-image: 
				radial-gradient(circle at 15% 15%, rgba(59, 130, 246, 0.12) 0%, transparent 40%),
				radial-gradient(circle at 85% 20%, rgba(236, 72, 153, 0.1) 0%, transparent 35%),
				radial-gradient(circle at 50% 80%, rgba(16, 185, 129, 0.08) 0%, transparent 50%);
			background-attachment: fixed;
			color: var(--text-main);
			font-family: 'Outfit', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
			min-height: 100vh;
			display: flex;
			flex-direction: column;
		}

		header {
			padding: 4rem 1.5rem 2.5rem;
			text-align: center;
			max-width: 1000px;
			margin: 0 auto;
		}

		.badge-top {
			display: inline-flex;
			align-items: center;
			gap: 0.5rem;
			padding: 0.35rem 1rem;
			border-radius: 9999px;
			background: rgba(255, 255, 255, 0.05);
			border: 1px solid rgba(255, 255, 255, 0.1);
			font-size: 0.85rem;
			font-weight: 500;
			color: #38bdf8;
			margin-bottom: 1.25rem;
			backdrop-filter: blur(8px);
		}

		.badge-top .dot {
			width: 8px;
			height: 8px;
			border-radius: 50%;
			background-color: #38bdf8;
			box-shadow: 0 0 8px #38bdf8;
			animation: pulse 2s infinite;
		}

		@keyframes pulse {
			0%, 100% { opacity: 1; }
			50% { opacity: 0.4; }
		}

		h1 {
			font-size: clamp(2.2rem, 5vw, 3.5rem);
			font-weight: 800;
			letter-spacing: -0.03em;
			line-height: 1.15;
			margin-bottom: 1rem;
			background: linear-gradient(135deg, #ffffff 30%, #94a3b8 100%);
			-webkit-background-clip: text;
			-webkit-text-fill-color: transparent;
		}

		p.lead {
			font-size: clamp(1rem, 2vw, 1.2rem);
			color: var(--text-muted);
			line-height: 1.6;
			max-width: 650px;
			margin: 0 auto 1.5rem;
		}

		.container {
			flex: 1;
			max-width: 1280px;
			width: 100%;
			margin: 0 auto;
			padding: 0 1.5rem 4rem;
		}

		.games-grid {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
			gap: 1.75rem;
		}

		.game-card {
			position: relative;
			background: var(--bg-card);
			border: 1px solid var(--border-card);
			border-radius: 20px;
			overflow: hidden;
			display: flex;
			flex-direction: column;
			backdrop-filter: blur(16px);
			transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
		}

		.game-card:hover {
			transform: translateY(-6px);
			border-color: rgba(255, 255, 255, 0.2);
			box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.6);
		}

		.game-card[data-color="cyan"]:hover {
			border-color: rgba(0, 210, 255, 0.4);
			box-shadow: 0 20px 40px -15px rgba(0, 210, 255, 0.25);
		}

		.game-card[data-color="green"]:hover {
			border-color: rgba(16, 185, 129, 0.4);
			box-shadow: 0 20px 40px -15px rgba(16, 185, 129, 0.25);
		}

		.game-card[data-color="amber"]:hover {
			border-color: rgba(245, 158, 11, 0.4);
			box-shadow: 0 20px 40px -15px rgba(245, 158, 11, 0.25);
		}

		.game-card[data-color="pink"]:hover {
			border-color: rgba(236, 72, 153, 0.4);
			box-shadow: 0 20px 40px -15px rgba(236, 72, 153, 0.25);
		}

		.card-header {
			padding: 1.5rem 1.5rem 1rem;
			display: flex;
			align-items: center;
			gap: 1rem;
		}

		.icon-wrapper {
			width: 64px;
			height: 64px;
			border-radius: 16px;
			background: rgba(255, 255, 255, 0.04);
			border: 1px solid rgba(255, 255, 255, 0.08);
			display: flex;
			align-items: center;
			justify-content: center;
			flex-shrink: 0;
			overflow: hidden;
		}

		.icon-wrapper img {
			width: 48px;
			height: 48px;
			object-fit: contain;
			filter: drop-shadow(0 2px 8px rgba(0,0,0,0.4));
		}

		.title-wrap h2 {
			font-size: 1.35rem;
			font-weight: 700;
			letter-spacing: -0.01em;
			margin-bottom: 0.25rem;
		}

		.tags-row {
			display: flex;
			flex-wrap: wrap;
			gap: 0.4rem;
			align-items: center;
		}

		.tag {
			font-size: 0.72rem;
			font-weight: 600;
			padding: 0.2rem 0.6rem;
			border-radius: 6px;
			letter-spacing: 0.02em;
			text-transform: uppercase;
		}

		.tag-ver {
			font-family: 'JetBrains Mono', monospace;
			background: rgba(255, 255, 255, 0.08);
			color: #e2e8f0;
			text-transform: none;
		}

		.tag-ready {
			background: rgba(16, 185, 129, 0.15);
			color: #34d399;
			border: 1px solid rgba(16, 185, 129, 0.25);
		}

		.tag-proto {
			background: rgba(245, 158, 11, 0.15);
			color: #fbbf24;
			border: 1px solid rgba(245, 158, 11, 0.25);
		}

		.tag-genre {
			background: rgba(59, 130, 246, 0.15);
			color: #60a5fa;
		}

		.card-body {
			padding: 0 1.5rem 1.5rem;
			flex: 1;
			display: flex;
			flex-direction: column;
		}

		.card-desc {
			color: var(--text-muted);
			font-size: 0.95rem;
			line-height: 1.55;
			margin-bottom: 1.25rem;
		}

		.features-list {
			list-style: none;
			margin-top: auto;
			padding-bottom: 1.25rem;
			display: flex;
			flex-direction: column;
			gap: 0.5rem;
		}

		.features-list li {
			font-size: 0.85rem;
			color: var(--text-dim);
			display: flex;
			align-items: center;
			gap: 0.5rem;
		}

		.features-list li::before {
			content: "✔";
			font-size: 0.75rem;
			color: var(--accent-cyan);
		}

		.card-footer {
			padding: 1.25rem 1.5rem;
			background: rgba(0, 0, 0, 0.2);
			border-top: 1px solid var(--border-card);
			display: flex;
			gap: 0.75rem;
			align-items: center;
		}

		.btn {
			display: inline-flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
			text-decoration: none;
			font-weight: 600;
			font-size: 0.95rem;
			padding: 0.75rem 1.25rem;
			border-radius: 12px;
			transition: all 0.2s ease;
			cursor: pointer;
		}

		.btn-primary {
			flex: 1;
			background: linear-gradient(135deg, #2563eb, #1d4ed8);
			color: #ffffff;
			box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
			border: 1px solid rgba(255, 255, 255, 0.15);
		}

		.btn-primary:hover {
			background: linear-gradient(135deg, #3b82f6, #2563eb);
			box-shadow: 0 6px 20px rgba(37, 99, 235, 0.5);
			transform: scale(1.02);
		}

		.game-card[data-color="cyan"] .btn-primary {
			background: linear-gradient(135deg, #0284c7, #0369a1);
			box-shadow: 0 4px 14px rgba(2, 132, 199, 0.35);
		}
		.game-card[data-color="cyan"] .btn-primary:hover {
			background: linear-gradient(135deg, #0ea5e9, #0284c7);
			box-shadow: 0 6px 20px rgba(2, 132, 199, 0.5);
		}

		.game-card[data-color="green"] .btn-primary {
			background: linear-gradient(135deg, #059669, #047857);
			box-shadow: 0 4px 14px rgba(5, 150, 105, 0.35);
		}
		.game-card[data-color="green"] .btn-primary:hover {
			background: linear-gradient(135deg, #10b981, #059669);
			box-shadow: 0 6px 20px rgba(5, 150, 105, 0.5);
		}

		.game-card[data-color="amber"] .btn-primary {
			background: linear-gradient(135deg, #d97706, #b45309);
			box-shadow: 0 4px 14px rgba(217, 119, 6, 0.35);
		}
		.game-card[data-color="amber"] .btn-primary:hover {
			background: linear-gradient(135deg, #f59e0b, #d97706);
			box-shadow: 0 6px 20px rgba(217, 119, 6, 0.5);
		}

		.game-card[data-color="pink"] .btn-primary {
			background: linear-gradient(135deg, #db2777, #be185d);
			box-shadow: 0 4px 14px rgba(219, 39, 119, 0.35);
		}
		.game-card[data-color="pink"] .btn-primary:hover {
			background: linear-gradient(135deg, #ec4899, #db2777);
			box-shadow: 0 6px 20px rgba(219, 39, 119, 0.5);
		}

		.btn-secondary {
			padding: 0.75rem;
			background: rgba(255, 255, 255, 0.05);
			color: var(--text-muted);
			border: 1px solid var(--border-card);
		}

		.btn-secondary:hover {
			background: rgba(255, 255, 255, 0.1);
			color: #ffffff;
		}

		footer {
			border-top: 1px solid var(--border-card);
			padding: 2.5rem 1.5rem;
			text-align: center;
			color: var(--text-dim);
			font-size: 0.9rem;
			background: rgba(10, 11, 18, 0.8);
		}

		footer a {
			color: #38bdf8;
			text-decoration: none;
			transition: color 0.2s ease;
		}

		footer a:hover {
			color: #7dd3fc;
			text-decoration: underline;
		}

		.footer-links {
			display: flex;
			justify-content: center;
			gap: 1.5rem;
			margin-top: 0.75rem;
			flex-wrap: wrap;
		}
	</style>
</head>
<body>
	<header>
		<div class="badge-top">
			<span class="dot"></span>
			Godot 4.7 HTML5 Web Portal
		</div>
		<h1>Mini-Games Launcher</h1>
		<p class="lead">Kleine, moderne Spiele mit Godot 4.7 (GDScript) – direkt im Browser spielbar oder als Desktop-Builds für Linux & Windows.</p>
	</header>

	<main class="container">
		<div class="games-grid">

			<!-- Block Stack -->
			<article class="game-card" data-color="cyan">
				<div class="card-header">
					<div class="icon-wrapper">
						<img src="block_stack/icon.svg" alt="Block Stack Icon">
					</div>
					<div class="title-wrap">
						<h2>Block Stack</h2>
						<div class="tags-row">
							<span class="tag tag-ver">v1.0.0</span>
							<span class="tag tag-ready">Vollversion</span>
							<span class="tag tag-genre">Puzzle</span>
						</div>
					</div>
				</div>
				<div class="card-body">
					<p class="card-desc">Modernes Puzzle-Spiel im Guideline-Stil mit SRS-Rotationssystem, 7-Bag-Zufall, Hold und Ghost Piece. Beinhaltet Einzelspieler- und CPU-Duell-Modi.</p>
					<ul class="features-list">
						<li>Marathon, Sprint (40L) & Ultra (2 Min)</li>
						<li>Symmetrisches CPU-Duell mit KI</li>
						<li>Integrierte Steuerungshilfe & Neon-Design</li>
					</ul>
				</div>
				<div class="card-footer">
					<a href="block_stack/" class="btn btn-primary" title="Block Stack im Browser spielen">
						▶ Jetzt spielen
					</a>
					<a href="https://github.com/ChobitsChii/games/releases/tag/block_stack-latest" class="btn btn-secondary" title="Downloads & Releases">
						📦
					</a>
				</div>
			</article>

			<!-- Lane Defenders -->
			<article class="game-card" data-color="green">
				<div class="card-header">
					<div class="icon-wrapper">
						<img src="lane_defenders/icon.svg" alt="Lane Defenders Icon">
					</div>
					<div class="title-wrap">
						<h2>Lane Defenders</h2>
						<div class="tags-row">
							<span class="tag tag-ver">v1.4.0</span>
							<span class="tag tag-ready">Vollversion</span>
							<span class="tag tag-genre">Tower Defense</span>
						</div>
					</div>
				</div>
				<div class="card-body">
					<p class="card-desc">Actionreiches Mini-Tower-Defense auf 5 Spuren im modernen Flat-Cartoon-Look. Platziere Einheiten taktisch und wehre die Gegnerwellen ab.</p>
					<ul class="features-list">
						<li>7 Einheiten & 6 verschiedene Gegnertypen</li>
						<li>10 abwechslungsreiche Level in 2 Welten</li>
						<li>Giga-Bosskampf & Sternesystem mit Speicherung</li>
					</ul>
				</div>
				<div class="card-footer">
					<a href="lane_defenders/" class="btn btn-primary" title="Lane Defenders im Browser spielen">
						▶ Jetzt spielen
					</a>
					<a href="https://github.com/ChobitsChii/games/releases/tag/lane_defenders-latest" class="btn btn-secondary" title="Downloads & Releases">
						📦
					</a>
				</div>
			</article>

			<!-- Connect Four Deluxe -->
			<article class="game-card" data-color="amber">
				<div class="card-header">
					<div class="icon-wrapper">
						<img src="vier_gewinnt/icon.svg" alt="Connect Four Deluxe Icon">
					</div>
					<div class="title-wrap">
						<h2>Connect Four Deluxe</h2>
						<div class="tags-row">
							<span class="tag tag-ver">v1.1.2</span>
							<span class="tag tag-ready">Vollversion</span>
							<span class="tag tag-genre">Strategie</span>
						</div>
					</div>
				</div>
				<div class="card-body">
					<p class="card-desc">Modernes „Vier gewinnt“ mit stimmungsvoller 2.5D-Präsentation, dynamischen Soundeffekten und einer extrem schnellen Bitboard-Engine mit Alpha-Beta-Suche.</p>
					<ul class="features-list">
						<li>3 KI-Schwierigkeitsgrade (Leicht, Mittel, Schwer)</li>
						<li>Lokaler 2-Spieler-Modus (Hotseat)</li>
						<li>Zug-Tipp (Hinweis) & Undo-Funktion</li>
					</ul>
				</div>
				<div class="card-footer">
					<a href="vier_gewinnt/" class="btn btn-primary" title="Connect Four Deluxe im Browser spielen">
						▶ Jetzt spielen
					</a>
					<a href="https://github.com/ChobitsChii/games/releases/tag/vier_gewinnt-latest" class="btn btn-secondary" title="Downloads & Releases">
						📦
					</a>
				</div>
			</article>

			<!-- Neon Breakout -->
			<article class="game-card" data-color="pink">
				<div class="card-header">
					<div class="icon-wrapper">
						<img src="neon_breakout/icon.svg" alt="Neon Breakout Icon">
					</div>
					<div class="title-wrap">
						<h2>Neon Breakout</h2>
						<div class="tags-row">
							<span class="tag tag-ver">v0.1.0</span>
							<span class="tag tag-proto">Prototyp</span>
							<span class="tag tag-genre">Arcade</span>
						</div>
					</div>
				</div>
				<div class="card-body">
					<p class="card-desc">Klassisches Breakout im modernen Neon-Look mit dynamischer Schläger- und Ballphysik. Erste spielbare Version (M0 & M1).</p>
					<ul class="features-list">
						<li>Präzise Kollisionsberechnung</li>
						<li>Mehrere Levelformationen & Highscores</li>
						<li>Gamepad-, Maus- & Tastatursteuerung</li>
					</ul>
				</div>
				<div class="card-footer">
					<a href="neon_breakout/" class="btn btn-primary" title="Neon Breakout im Browser spielen">
						▶ Jetzt spielen
					</a>
					<a href="https://github.com/ChobitsChii/games/releases/tag/neon_breakout-latest" class="btn btn-secondary" title="Downloads & Releases">
						📦
					</a>
				</div>
			</article>

		</div>
	</main>

	<footer>
		<p>Erstellt mit <strong>Godot Engine 4.7</strong> • Veröffentlicht als freie Software</p>
		<div class="footer-links">
			<a href="https://github.com/ChobitsChii/games" target="_blank" rel="noopener">GitHub Repository</a>
			<span>•</span>
			<a href="https://github.com/ChobitsChii/games/releases" target="_blank" rel="noopener">Alle Releases & Downloads</a>
			<span>•</span>
			<a href="https://godotengine.org/" target="_blank" rel="noopener">Godot Engine</a>
		</div>
	</footer>
</body>
</html>
EOF

echo "== Web-Portal erfolgreich in $TARGET_DIR generiert =="
