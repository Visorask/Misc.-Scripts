#!/bin/bash
# Generate Plex Library stats

#### Variables ####

#Change to where you want the logfile to go.
logfile="$HOME/logs/plexstats.log"
#Change this to your plex database location.
db="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
#Change this to the name of your docker. It must match exactly. If not using then just leave the default.
docker="plex"    
#Change to the location of your media scanner. This is the default one. It will work for docker and linux.
scanner="/usr/lib/plexmediaserver/Plex Media Scanner"                                                                                  

####End Variables####

list_section_id() {
echo "**************************************"
echo "** List of section ID's to utilize. **"
echo "**************************************"
if [[ $(docker ps --filter "name=^/$docker$" --format '{{.Names}}') == "$docker" ]]; then
        docker exec -it $docker "$scanner" --list
else
        "$scanner" --list
fi
}

get_array() {
if [[ $(docker ps --filter "name=^/$docker$" --format '{{.Names}}') == "$docker" ]]; then
        readarray -t d_section < <(docker exec -it $docker "$scanner" --list | sed 's/:.*//')
else
        readarray -t section < <( "$scanner" --list | sed 's/:.*//' )
fi
}

choice() {
echo "**************************************************************************************************" | tee -a $logfile
echo "** Please enter the number of the section id, as seen above, that you want to check intros for. **" | tee -a $logfile
echo "**************************************************************************************************" | tee -a $logfile
if [ -n "$d_section" ]; then
        select id in "${d_section[@]}"; do
                [[ -n $id ]] || { echo "Invalid choice. Please try again." >&2; continue; }
               break
        done
else
        select id in "${section[@]}"; do
                [[ -n $id ]] || { echo "Invalid choice. Please try again." >&2; continue; }
                break
        done
fi
}

library_stats() {
echo "Date: $(date "+%d.%m.%Y %T")" | tee -a $logfile
echo "" | tee -a $logfile
echo "************************" | tee -a $logfile
echo "** Plex Library Stats **" | tee -a $logfile
echo "************************" | tee -a $logfile
echo "" | tee -a $logfile
echo "Media items in Libraries" | tee -a $logfile
echo "" | tee -a $logfile
query="SELECT Library, Items \
                        FROM ( SELECT name AS Library, \
                        COUNT(duration) AS Items \
                        FROM media_items m  \
                        LEFT JOIN library_sections l ON l.id = m.library_section_id  \
                        WHERE library_section_id > 0 GROUP BY name );"
sqlite3 -header -line "$db" "$query" | tee -a $logfile
echo " " | tee -a
echo "" | tee -a $logfile
}

sql_library() {
query="SELECT count(*) FROM media_items"
result=$(sqlite3 -header -line "$db" "$query")
echo "Library Total = ${result:11} files in library" | tee -a $logfile
echo "" | tee -a $logfile
}

sql_intro() {
echo "--Skip intro stats:--"
echo ""
query="SELECT count(*) FROM media_parts mp JOIN media_items mi on mi.id = mp.media_item_id WHERE mi.library_section_id = 1 and mp.extra_data like '%intros=%';"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} files analyzed for skip intros." | tee -a $logfile

query="SELECT count(*) FROM media_parts mp JOIN media_items mi on mi.id = mp.media_item_id WHERE mi.library_section_id = 1 and mp.extra_data not like '%intros=%';"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} files that have not been analyzed for skip intros." | tee -a $logfile

query="SELECT count(*) FROM media_parts mp JOIN media_items mi on mi.id = mp.media_item_id WHERE mi.library_section_id = 1 and mp.extra_data like '%intros=%%7B%';"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} files that actually have skip intros." | tee -a $logfile
echo ""
}

sql_analyze() {
echo "--Analyze stats:--" | tee -a $logfile
echo "" | tee -a $logfile
query="SELECT count(*) FROM media_items WHERE bitrate is null"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} files missing analyzation info" | tee -a $logfile

query="SELECT count(*) FROM metadata_items meta \
                        JOIN media_items media on media.metadata_item_id = meta.id \
                        JOIN media_parts part on part.media_item_id = media.id \
                        WHERE part.extra_data not like '%deepAnalysisVersion=2%' \
                        and meta.metadata_type in (1, 4, 12) and part.file != '';"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} files missing deep analyzation info." | tee -a $logfile
echo "" | tee -a $logfile
}

sql_deleted() {
echo "--Deleted stats:--" | tee -a $logfile
echo "" | tee -a $logfile
query="SELECT count(*) FROM media_parts WHERE deleted_at is not null"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} media_parts marked as deleted" | tee -a $logfile

query="SELECT count(*) FROM metadata_items WHERE deleted_at is not null"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} metadata_items marked as deleted" | tee -a $logfile

query="SELECT count(*) FROM directories WHERE deleted_at is not null"
result=$(sqlite3 -header -line "$db" "$query")
echo "${result:11} directories marked as deleted" | tee -a $logfile
echo "" | tee -a $logfile
}



list_section_id
get_array
choice
library_stats
sql_library
sql_intro
sql_analyze
sql_deleted

exit
