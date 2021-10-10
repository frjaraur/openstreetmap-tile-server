
## Quick test

### Execute
```
docker run --name openstsmap-run 
-p 8080:80 -d \
-v openstreetmap-data:/var/lib/postgresql/12/main 
-v $(pwd)/PBF:/PBF \
overv/openstreetmap-tile-server run
```

### Import using its own container
```
$ wget -P $(pwd)/PBF  https://download.geofabrik.de/europe/spain-latest.osm.pbf

$ docker cp import.sh overv/openstreetmap-tile-server:/import.sh

$ docker exec -ti openstsmap-run /import.sh
```

### MAPS
https://download.geofabrik.de/europe.html