<?php

if ( !$isQuiet )
{
    $cli->output( "Processing missing content items by id in search index" );
}

function formatBytes($size, $precision = 2)
{
    $base = log($size, 1024);
    $suffixes = array('', 'k', 'M', 'G', 'T');

    return round(pow(1024, $base - floor($base)), $precision) . $suffixes[floor($base)];
}


$start_time = microtime(true);
echo "Memory used at start: " .   formatBytes(memory_get_peak_usage( true ),0 ) . "\n";
// check that solr is enabled and used
$eZSolr = eZSearch::getEngine();
if ( !$eZSolr instanceof eZSolr )
{
    $script->shutdown( 1, 'The current search engine plugin is not eZSolr' );
}

$db = eZDB::instance();

$idArrayFromSolr = [];
$idQuerySolr = ['q' => '*:*','rows' => 1000000000, 'fl' => 'meta_id_si'];

if ( $eZSolr->UseMultiLanguageCores === true) {
    foreach ( $eZSolr->SolrLanguageShards as $language => $solrShard ) {
        $idArrayFromSolr[$language] = $solrShard->rawSearch( $idQuerySolr, 'json' )['response']['docs'];
    }
} else {
    $idArrayFromSolr['default'] = & $eZSolr->Solr->rawSearch( $idQuerySolr, 'json' )['response']['docs'];
}


echo "Memory used after querying Solr: " .  formatBytes(memory_get_peak_usage( true ),0 ). " after " . intval((microtime(true) - $start_time)*1000) . " ms \n";

foreach ( array_keys( $idArrayFromSolr ) as $language ) {
    echo "Solr index for core " . $language . " has "  . count( $idArrayFromSolr[$language] ) . " documents\n";
}

$idArrayFromDB = $db->query( 'SELECT id from ezcontentobject WHERE status = 1' )->fetch_all( MYSQLI_ASSOC );
$lookupArraySolr = [];

echo "Memory used after querying DB: " .  formatBytes(memory_get_peak_usage( true ),0 ). " after " . intval((microtime(true) - $start_time)*1000) . " ms \n";


echo "Checking " . count( $idArrayFromDB ) . " objects in DB\n";
// look up
foreach ( array_keys( $idArrayFromSolr ) as $language ) {
    foreach ( $idArrayFromSolr[$language] as $row ) {
        // if found in any language, we consider the index to be ok
        $lookupArraySolr[$row['meta_id_si']] = 'ok';
    }
}


echo "Memory used after building lookup array: " .  formatBytes(memory_get_peak_usage( true ),0 ). " after " . intval((microtime(true) - $start_time)*1000) . " ms \n";


$missing = 0;
$found = 0;

foreach ( $idArrayFromDB as $row ) {
    if ( isset( $lookupArraySolr[$row['id']] ) ) {
        $found++;
    } else {
        $missing++;
        $eZSolr->addObject( \eZContentObject::fetch( $row['id'] ), false, 20000 );
    }
}

echo "Found " . $found . " and " . $missing . " are not indexed\n";
echo "Memory used at end: " .   formatBytes(memory_get_peak_usage( true ),0 ) . " after " . intval((microtime(true) - $start_time)*1000) . " ms \n";

if ( !$isQuiet )
{
    $cli->output( "Done" );
}
