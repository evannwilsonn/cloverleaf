.PHONY: setup collect weather sync load build dashboard serve eval all

all: sync load build dashboard   ## everything after collection, on DuckDB

setup:      ## pipeline dependencies (add requirements-collect.txt to run the collector)
	pip install -r requirements.txt
collect:    ## record one clip per camera and count vehicles (what the 30-minute workflow runs)
	python collector/capture.py
weather:    ## pull recent NWS observations
	python collector/fetch_weather.py
sync:       ## copy everything the scheduled collector has gathered from the data branch
	python ingest/sync_data.py
load:       ## land captures, weather and eval predictions in DuckDB (raw_cloverleaf)
	python ingest/load_raw.py
build:      ## seed, run and test every dbt model
	dbt build --profiles-dir .
eval:       ## re-run the detector over the hand-labelled frames
	python eval/predict_frames.py
dashboard:  ## export the reporting marts and current camera stills
	python dashboard/export_data.py
serve:      ## open the dashboard at http://localhost:8000
	cd dashboard && python -m http.server 8000
