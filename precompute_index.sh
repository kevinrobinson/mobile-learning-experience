#!/bin/bash

coffee -e "require('./scripts/build_index.coffee').buildAndSerialize 'data/app_activity_tuples.qsv'" > data/prebuilt-search-index.json