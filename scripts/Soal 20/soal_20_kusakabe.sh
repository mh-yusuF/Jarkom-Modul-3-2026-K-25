#!/bin/sh

echo "===== SOAL 20: AUDIT KAPASITAS ====="

echo "\n===== BENCHMARK FRONTEND ====="
ab -n 600 -c 30 http://jujutsu.k25.com/

echo "\n===== BENCHMARK API ====="
ab -n 600 -c 30 http://jujutsu.k25.com/api