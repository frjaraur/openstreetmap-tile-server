#!/bin/bash

# DATABASE
# DBUSER
# DPBASSWD
PBFDIR=/PBF

    if [ "$UPDATES" = "enabled" ]; then
        # determine and set osmosis_replication_timestamp (for consecutive updates)
        osmium fileinfo /PBF/data.osm.pbf > /var/lib/mod_tile/data.osm.pbf.info
        osmium fileinfo /PBF/data.osm.pbf | grep 'osmosis_replication_timestamp=' | cut -b35-44 > /var/lib/mod_tile/replication_timestamp.txt
        REPLICATION_TIMESTAMP=$(cat /var/lib/mod_tile/replication_timestamp.txt)

        # initial setup of osmosis workspace (for consecutive updates)
        sudo -u renderer openstreetmap-tiles-update-expire $REPLICATION_TIMESTAMP
    fi

for pbffile in ${PBFDIR}/*.pbf
do
    echo "PBF FILE: ${pbffile}"
    polyfile="$(echo ${pbffile}|sed -e "s/\.pbf//g")" 
    # copy polygon file if available
    if [ -f ${polyfile}.poly ]; then
        sudo -u renderer cp ${pbffile}.poly /var/lib/mod_tile/${pbffile}.poly
    fi

    # Import data
    sudo -u renderer osm2pgsql -d gis --create --slim -G --hstore --tag-transform-script /home/renderer/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes ${THREADS:-4} -S /home/renderer/src/openstreetmap-carto/openstreetmap-carto.style ${pbffile} ${OSM2PGSQL_EXTRA_ARGS}

    # Create indexes
    sudo -u postgres psql -d gis -f /home/renderer/src/openstreetmap-carto/indexes.sql

    #Import external data
    sudo chown -R renderer: /home/renderer/src
    sudo -u renderer python3 /home/renderer/src/openstreetmap-carto/scripts/get-external-data.py -c /home/renderer/src/openstreetmap-carto/external-data.yml -D /home/renderer/src/openstreetmap-carto/data

    # Register that data has changed for mod_tile caching purposes
    touch /var/lib/mod_tile/planet-import-complete
done
