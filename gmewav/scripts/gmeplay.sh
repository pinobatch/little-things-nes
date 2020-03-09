#!/bin/bash
set -e
gmewav "$@" - | paplay --raw --rate=44100 --format=s16ne --channels=2

