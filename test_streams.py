#!/usr/bin/env python3
"""
Test script to validate and report statistics on ASP TV news channels (Marathi, Hindi, English).
"""
import json
import os

DATA_FILE = os.path.join(os.path.dirname(__file__), 'assets', 'data', 'news_channels.json')
M3U_FILE = os.path.join(os.path.dirname(__file__), 'assets', 'data', 'indian_news.m3u')

def main():
    print("=" * 60)
    print("ASP TV - Marathi, Hindi & English News Channels Verification")
    print("=" * 60)

    if not os.path.exists(DATA_FILE):
        print(f"Error: {DATA_FILE} not found!")
        return

    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        channels = json.load(f)

    print(f"Total Curated Channels: {len(channels)}")

    lang_counts = {}
    total_streams = 0
    with_logos = 0

    for ch in channels:
        lang = ch.get('language_name', 'Unknown')
        lang_counts[lang] = lang_counts.get(lang, 0) + 1
        total_streams += len(ch.get('streams', []))
        if ch.get('logo'):
            with_logos += 1

    print(f"Total Stream Endpoints (including mirrors): {total_streams}")
    print(f"Channels with High-Res Logos: {with_logos} ({with_logos*100//len(channels)}%)")
    print("\nChannel Distribution by Language:")
    print("-" * 45)
    for lang, count in sorted(lang_counts.items(), key=lambda x: -x[1]):
        print(f"  {lang:<15}: {count:>3} channels")

    print("\nSample Marathi Channels:")
    for ch in [c for c in channels if c.get('language_code') == 'mar'][:6]:
        print(f"  • {ch['name']} ({len(ch['streams'])} streams)")

    print("\nSample Hindi Channels:")
    for ch in [c for c in channels if c.get('language_code') == 'hin'][:6]:
        print(f"  • {ch['name']} ({len(ch['streams'])} streams)")

    print("\nSample English Channels:")
    for ch in [c for c in channels if c.get('language_code') == 'eng'][:6]:
        print(f"  • {ch['name']} ({len(ch['streams'])} streams)")

    if os.path.exists(M3U_FILE):
        with open(M3U_FILE, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        extinf = sum(1 for line in lines if line.startswith('#EXTINF:'))
        print("\nM3U Playlist Status:")
        print(f"  File: {M3U_FILE}")
        print(f"  Total #EXTINF entries: {extinf}")
    print("=" * 60)

if __name__ == '__main__':
    main()
