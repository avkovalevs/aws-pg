#!/usr/bin/php
<?php

/*
example block:

backend_hostname0 = ip-172-31-46-91
backend_port0 = 5432
backend_weight0 = 1
backend_flag0 = 'DISALLOW_TO_FAILOVER'
backend_data_directory0 = '/var/lib/postgresql/9.6/main'
*/

$USAGE = <<<LINES
        pgconfi (v1.0)
        sPARK Parking Techologies * 2019
        author: iddo@sparking.co.il

        Usage:  /etc/gconfi  <file.conf> add     backend_hostname,backend_port,backend_weight,backend_flag,backend_data_directory
                /etc/pgconfi <file.conf> remove  backend_hostname

        Examples:
          Executing the following two examples will leave the original file test.conf in original condition -
          1)    /etc/pgconfi test.conf add ip-172-31-46-93,5433,2,'DISALLOW_TO_FAILOVER','/var/lib/postgresql/9.6/main'
          2)    /etc/pgconfi test.conf remove ip-172-31-46-93

        Notes:
          o 'single quotes' can be added. the script makes sure that 'backend_flag' and 'backend_data_directory' will have only one set of single quotes.
          o in case the csv is seperated with spaces, then the whole csv should be "csv" double quoted (to be regarded as one cli parameter).
          o Original file is backed up, in same path as origial, with the '.bak' extension.
          o There could only be one block per ip-address, this leads to the next bullet:
          o For changing an existig block, use the 'add' option, providing different set of parameters for the same existing ip-address.
LINES;

$PARAMS = explode('/', 'backend_hostname/backend_port/backend_weight/backend_flag/backend_data_directory');
$TYPES  = explode('/', 'as-is/int/float/string/string');

if ($argc != 4) {
        echo $USAGE . PHP_EOL . PHP_EOL;
                exit(1);
}

$filename = $argv[1];
$action   = $argv[2];
$data     = $argv[3];

function backup($filename) {
        @shell_exec("cp -n $filename $filename.bak"); // no overwrite
}

function reader($filename) {
        global $PARAMS;
        $memo = array();
        $params = array();
        $text = explode(PHP_EOL, @file_get_contents($filename));
        $mark = null;

        if (count($text))
                for ($i=0; $i < count($text); $i++) {
                                $found = false;
                                for ($p=0; $p < count($PARAMS); $p++) {
                                                if (strpos($text[$i], $PARAMS[$p]) !== false) {
                                                                $found = true;

                                                                $pair = explode('=', $text[$i]);
                                                                $leftside  = trim($pair[0]);
                                                                $rightside = trim($pair[1]);

                                                                if ($leftside == $PARAMS[0].'0') $mark = $i;
                                                                $index = str_replace($PARAMS[$p], '', $leftside);
                                                                $value = $rightside;

                                                                if (!isset($params[$index])) $params[$index] = array();
                                                                $params[$index][ $PARAMS[$p] ] = $value;
                                                                break;
                                                }
                                }
                                if (!$found)
                                                $memo[] = $text[$i];
                }

        if (!$mark) $mark = count($memo)-1;
        return [ $memo, $params, $mark ];
}//reader

// returns the config blocks as a string based on read $params structure
function plot($params) {
        global $PARAMS;
                $blocks = array();
        for ($i=0; $i < count($params); $i++) {
                                $block = array();

                                for ($p=0; $p < count($PARAMS); $p++)
                                        $block[] = $PARAMS[$p] . $i . ' = ' . $params[$i][ $PARAMS[$p] ];

                                $blocks[] = implode(PHP_EOL, $block);
        }
        return implode(PHP_EOL.PHP_EOL, $blocks);
}

function edit(&$params, $action, $data) {
        global $PARAMS, $TYPES;
        $parts = array_map('trim', explode(',', $data));
        switch ($action) {
                        case 'add':     if (count($parts) != 5) {
                                                                echo "using the add option, the csv parameter should contain only 5 elements: " . implode(',', $PARAMS) . PHP_EOL;
                                                                exit(1);
                                                        }
                                                        // parse csv: spaces are allowed, quotes will be trimmed and re-added
                                                        $obj = array();
                                                        for ($i=0; $i < count($PARAMS); $i++) {
                                                                switch ($TYPES[$i]) {
                                                                        case 'as-is':   $obj[ $PARAMS[$i] ] = $parts[$i];                       break;
                                                                        case 'int':     $obj[ $PARAMS[$i] ] = (int)$parts[$i];          break;
                                                                        case 'float':   $obj[ $PARAMS[$i] ] = (float)$parts[$i];        break;
                                                                        case 'string':  $parts[$i] = trim($parts[$i], "'\"");
                                                                                                        $obj[ $PARAMS[$i] ] = "'{$parts[$i]}'";         break;
                                                                }
                                                        }
                                                        // no ip duplicates
                                                        for ($i=0; $i < count($params); $i++)
                                                                if ($params[$i][ $PARAMS[0] ] == $parts[0])
                                                                        array_splice($params, $i, 1);
                                                        // add new as last
                                                        $params[] = $obj;
                                                        break;
                        case 'remove':  if (count($parts) != 1) {
                                                                echo "using the remove option, the csv parameter should contain only 1 element: " . $PARAMS[0] . PHP_EOL;
                                                                exit(1);
                                                        }
                                                        for ($i=0; $i < count($params); $i++)
                                                                        if ($params[$i][ $PARAMS[0] ] == $parts[0])
                                                                                        array_splice($params, $i, 1);
                                                        break;
                        default:                echo "bad action: $action" . PHP_EOL;
                                                        exit(1);
        }
}

function writer($filename, $memo, $params, $mark) {
        $output = implode(PHP_EOL, array_slice($memo, 0, $mark)) .
                          PHP_EOL .
                  plot($params) .
                          PHP_EOL .
                  ltrim(implode(PHP_EOL, array_slice($memo, $mark)));

        @file_put_contents($filename, $output);
}

// main:
        backup($filename);
        list($memo, $params, $mark) = reader($filename);
        edit($params, $action, $data);
        writer($filename, $memo, $params, $mark);

?>

