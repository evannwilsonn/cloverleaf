# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Hiring managers first, arriving from Evan Wilson's resume or LinkedIn and giving the page about a minute; they need to see a working product that turns public video into traffic numbers, and to trust that the numbers are checked. Data, analytics and ML engineers second, who look at the quality rules, the detection accuracy and the pipeline. Desktop and phone viewing are about equal. (Confirmed for the whole portfolio on 2026-10-09.)

## Product Purpose

Cloverleaf answers "how is traffic moving on Bay Area freeways, and how much of that can we actually see?" Every 30 minutes a GitHub Actions job opens 20 live Caltrans District 4 camera streams, records a 12-second clip from each, and counts and tracks vehicles with YOLOv8 and ByteTrack. Each capture is checked against quality rules (offline feed, unreadable video, placeholder card, frozen picture, darkness, obstruction) before it is allowed to count. dbt turns the captures and National Weather Service observations into corridor flow, congestion, truck share, hourly profiles, weather effects and data-quality KPIs, in DuckDB and Snowflake. Success: a reader sees live corridors, real numbers, and an honest account of which cameras and hours can be trusted.

## Positioning

One product that combines a data pipeline, a KPI dashboard and a computer-vision app, on public infrastructure data with real failure modes: dark cameras at night, feeds Caltrans takes offline, detection that is good by day and weak at night, measured against hand-labelled frames.

## Operating Context

Static page with inline data and current camera stills, rebuilt daily by GitHub Actions; also published as a Claude artifact. Sister product Cloverfield monitors its runs.

## Capabilities and Constraints

- Measures per capture: vehicles in view, moving vehicles, vehicles per minute, speed index, truck share, congestion, picture quality, sun elevation.
- Quality outcomes with priorities (seeds/qc_rules.csv); KPIs with targets (seeds/kpi_catalog.csv).
- Detection accuracy against hand-labelled frames, split by light. Night: 50 labelled vehicles, 13 detected. Daylight labels are pending.
- Early life: collection started 2026-10-09 overnight; history is a few runs, mostly dark. The page must read honestly with little and with night-only data.
- Every number on the page comes from data.json.

## Brand Commitments

Each portfolio project has its own visual world and its own new colour palette, distinct from Reprise (cool white, ink, blue ramp, amber), Cloverfield (control-room black, Caltrans orange, green/amber/red) and the earlier sign-green and IBM-Plex-blue looks.

## Evidence on Hand

dashboard/data.json (kpis, corridors, hourly, cameras with still URLs, quality, weather, accuracy, timeline, kpi_catalog, qc_rules). Real camera stills. No users or testimonials.

## Product Principles

1. Show the road: the camera pictures are the evidence and belong on the page.
2. A number only counts after its capture passes the quality rules; say how many did.
3. Night, offline and early states are designed, not hidden.
4. Every mark maps to real data.

## Accessibility & Inclusion

WCAG AA contrast in light and dark; state never carried by colour alone; works at phone width.
