# 🛡️ Plan 5 – Lane Defenders

**Genre:** Mini-Tower-Defense (Lane-basiert) · **Modus:** Single Player · **Aufwand:** ⭐⭐⭐

## Idee
Gegner laufen auf mehreren Bahnen (Lanes) von rechts nach links auf die Basis zu. Der Spieler platziert Verteidiger auf einem Raster und sammelt Energie, um mehr davon zu bauen. Das Prinzip ist übersichtlich, aber taktisch. Ein eigener Stil und eigene Einheiten machen das Spiel eigenständig.

## Kernmechanik
- Raster von 5 Lanes × 9 Feldern
- **Energie** entsteht durch Generator-Einheiten und fällt zusätzlich periodisch vom Himmel (anklicken zum Einsammeln)
- Einheiten kosten Energie und haben eine Abklingzeit
- Gegner laufen pro Lane und greifen die erste Einheit auf ihrem Weg an
- Erreicht ein Gegner die Basis, verliert man ein Leben, bei 3 Verlusten ist das Spiel vorbei
- Level bestehen aus Wellen mit einer **großen Schlusswelle**
- Sterne und Freischaltungen nach jedem Level

## Einheiten (Beispiele)
| Einheit | Kosten | Funktion |
|---|---|---|
| Generator | 50 | erzeugt Energie |
| Schütze | 100 | schießt geradeaus |
| Doppelschütze | 175 | zwei Schüsse |
| Frostturm | 150 | verlangsamt Gegner |
| Mauer | 50 | viele HP, blockiert |
| Mine | 25 | einmalige Explosion, braucht Aufladezeit |
| Flächenwerfer | 200 | trifft mehrere Lanes in der Nähe |

## Gegner (Beispiele)
Läufer (Standard) · Schneller Läufer · Panzer (viele HP) · Springer (überspringt die erste Einheit) · Schild-Träger (Schutz gegen Geradeausschüsse) · Boss (am Ende von Welt 1)

## Technischer Entwurf
- **Daten statt Code:** Einheiten, Gegner und Level als `Resource`-Dateien (`.tres`) mit eigenen Klassen (`UnitData`, `EnemyData`, `LevelData`). Das erleichtert Balancing und Erweiterungen.
- **Grid-Modell** als eigene Klasse. Die Darstellung liest sie nur.
- **Komponenten:** `HealthComponent`, `ShooterComponent`, `ProducerComponent`
- **Wellen-Director:** Spawn-Plan aus `LevelData` (Zeit, Lane, Gegnertyp)
- **Projektile:** Pooling, Treffer per Lane-Vergleich und x-Position statt physikalischer Kollision. Das ist deutlich schneller und stabiler.
- **Zustandsautomat:** `PRE_WAVE → RUNNING → BOSS → WON / LOST`

```
data/units/*.tres  data/enemies/*.tres  data/levels/*.tres
scripts/core/grid.gd  scripts/core/wave_director.gd  scripts/entities/*.gd  scripts/ui/*.gd
scenes/ main_menu  level_select  game  hud  unit_card  ...
```

## Optik & Assets
**Stil:** Freundlicher **Flat-Cartoon-Look** im Vektor-Stil mit weichen Schatten und kräftigen Farben, **ohne Pixel-Art**. Leicht schräge Draufsicht mit Tiefenschichten. Einheiten haben kleine Idle-Animationen (Atmen, Wippen), per Tween oder Skelett-Animation.

- **Palette:** Frisches Grün und Himmelsblau als Welt, kräftige Farben pro Einheitentyp für klare Erkennbarkeit
- **Grafik:** Flat-Vektor-Pakete (z. B. Kenney Tower Defense oder Toon-Pakete, Stil beim Aussuchen prüfen) oder eigene SVG-Figuren, auf die Godot-`Skeleton2D` oder Tweens angewendet werden. Wenn nötig, ergänzen generierte Bilder für Hintergründe.
- **Effekte:** Schuss-Treffer mit Funken und Zahlen ("Damage Numbers"), Energie fliegt animiert zur Anzeige, Wellenstart mit Banner, Boss-Eintritt mit Kamerazoom und Shake
- **UI:** Kartenleiste mit Abkling-Anzeige (Radial-Shader), eigenes UI-Theme
- **Font:** Runder, freundlicher Font mit Umlauten (OFL)
- **Audio:** Kenney-Sounds (CC0), fröhliche, loopbare Musik (CC0/CC-BY)

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
1. **M0:** Setup aus Vorlage (`shared/`: Menü, Theme, `LocaleService` mit DE/EN-CSV, `DisplayService`/Vollbild, Credits) und Platzhalter-Optik
2. **M1:** Raster, Platzieren und Entfernen von Einheiten, Energie-System
3. **M2:** Ein Gegnertyp, Schütze, Lebenspunkte, Projektile
4. **M3:** Wellen-Director und Level-Daten
5. **M4:** Alle Einheiten und Gegner, Abklingzeiten, Karten-UI
6. **M5:** 10 Level in 2 Welten mit Boss, Freischaltungen
7. **M6:** Fortschritts-Speicherung, Level-Auswahl, Tutorial-Level
8. **M7:** Juice, Sound, Balancing-Durchgang, Export

## Tests
- Kostenprüfung, Abklingzeit, Platzierungsregeln
- Wellen-Director erzeugt exakt die Gegner aus `LevelData`
- Schadensberechnung (Frost, Schild, Fläche)
- Automatischer "Bot-Test": Eine Standardstrategie muss Level 1–3 schaffen, damit sich das Balancing nicht unbemerkt verschlechtert

## Risiken
- Balancing ist aufwendig → Daten in Ressourcen, schnell änderbar, Bot-Test
- Viele Objekte im Web → Pooling

## Erweiterungsideen
Endlos-Modus, Tagesaufgaben, Einheiten-Upgrades, mehr Welten
