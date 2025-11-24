#!/bin/bash

# Intervall zwischen den Aktualisierungen (in Sekunden)
INTERVAL=2

echo "Starte Live-Überwachung des Time-Machine-Backups..."
echo "Drücke STRG+C zum Beenden."
echo

while true; do
  STATUS=$(tmutil status 2>/dev/null)

  if [[ -z "$STATUS" ]]; then
    echo "Kein laufendes Backup gefunden."
    sleep $INTERVAL
    continue
  fi

  RUNNING=$(echo "$STATUS" | grep "Running = " | awk '{print $3}' | tr -d ";")
  
  if [[ "$RUNNING" != "1" ]]; then
    echo "Kein laufendes Backup gefunden."
    sleep $INTERVAL
    continue
  fi

  TOTAL=$(echo "$STATUS" | grep "TotalBytes" | awk '{print $3}' | tr -d ";")
  COPIED=$(echo "$STATUS" | grep "BytesCopied" | awk '{print $3}' | tr -d ";")
  REMAIN=$(echo "$STATUS" | grep "TimeRemaining" | awk '{print $3}' | tr -d ";")
  PHASE=$(echo "$STATUS" | grep "BackupPhase" | awk -F'=' '{print $2}' | tr -d " ;")
  CHANGED=$(echo "$STATUS" | grep "ChangedItemCount" | awk '{print $3}' | tr -d ";")

  # Fallbacks
  [[ -z "$PHASE" ]] && PHASE="Unbekannt"
  [[ -z "$CHANGED" ]] && CHANGED="0"

  if [[ "$TOTAL" -gt 0 ]]; then
    PERCENT=$(echo "scale=1; ($COPIED / $TOTAL) * 100" | bc)
  else
    PERCENT=0
  fi

  HUMAN_COPIED=$(printf "%0.2f" "$(echo "$COPIED / 1024 / 1024 / 1024" | bc -l)")
  HUMAN_TOTAL=$(printf "%0.2f" "$(echo "$TOTAL / 1024 / 1024 / 1024" | bc -l)")

  clear
  echo "📦 Time-Machine Backup läuft"
  echo "=============================="
  echo "Phase:              $PHASE"
  echo "Dateien geändert:   $CHANGED"
  echo "Fortschritt:        $PERCENT %"
  echo "Kopiert:            ${HUMAN_COPIED} GB / ${HUMAN_TOTAL} GB"

  if [[ "$REMAIN" != "0" ]]; then
    echo "Übrig:              ${REMAIN} Sekunden"
  else
    echo "Übrig:              Schätzung nicht verfügbar"
  fi

  sleep $INTERVAL
done
