#!/usr/bin/env php
<?php

$update = json_decode($argv[1], JSON_OBJECT_AS_ARRAY);

if (isset($update['message']['text']) && false !== strpos($update['message']['text'], 'foo')) {
    echo json_encode([
        [
            "method" => "sendMessage",
            "params" => [
                "text" => "bar",
            ]
        ]
    ], JSON_PRETTY_PRINT);
}