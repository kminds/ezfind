<?php

/**
 *
 */

/**
 * Interface ezfElevateSyncInterface
 */

interface ezfElevateSyncInterface
{
    public function synchronise(eZSolrBase $collection, $elevateXML, $params );
}