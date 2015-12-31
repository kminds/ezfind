<?php

/**
 *
 */
class ezfElevateSimpleFileSync implements ezfElevateSyncInterface
{
    public function synchronise(eZSolrBase $collection, $elevateXML, $params )
    {
        $uri_components = parse_url( $collection->SearchServerURI );
        // The extra variables are used to avoid PHP strict warnings using end() directly on the preg_split result
        $pathElements = preg_split('/\//',$uri_components['path']);
        $collectionName = end($pathElements);
        $filename= implode('__',array(
            $uri_components['host'],
            $uri_components['port'],
            $collectionName,
            'elevate.xml',
        ));
        return eZFile::create ($filename, $params['base_dir'], $elevateXML );
    }
}