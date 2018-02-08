<?php
$recommendations = [
    'andrew-tanenbaum-operating-systems' => [
        'US' => 'https://www.amazon.com/gp/product/013359162X/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=013359162X&linkCode=as2&tag=opsbears04-20&linkId=4aef4e1c6afdbd356e095b98c24218ad',
        'UK' => 'https://www.amazon.co.uk/gp/product/1292061421/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=1292061421&linkCode=as2&tag=opsbears04-21&linkId=0153e1853d3801729b64ea28eae3ac3f',
        'CA' => 'https://www.amazon.ca/gp/product/013359162X/ref=as_li_tl?ie=UTF8&camp=15121&creative=330641&creativeASIN=013359162X&linkCode=as2&tag=opsbears03-20&linkId=23965c19f96421a7bf19d67e9744aa20',
        'DE' => 'https://www.amazon.de/gp/product/1292061421/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=1292061421&linkCode=as2&tag=opsbears-21&linkId=3a94181a5a07d1e781ee80106e10e3c5',
        'FR' => 'https://www.amazon.fr/gp/product/1292061421/ref=as_li_tl?ie=UTF8&camp=1642&creative=6746&creativeASIN=1292061421&linkCode=as2&tag=opsbears00-21&linkId=a806af0bbfa08634dd1313638339a04f',
        'ES' => 'https://www.amazon.es/gp/product/1292061421/ref=as_li_tl?ie=UTF8&camp=3638&creative=24630&creativeASIN=1292061421&linkCode=as2&tag=opsbears0e-21&linkId=21cccf8b6484a986c668f7e1548091dc',
        'IT' => 'https://www.amazon.it/gp/product/9332575770/ref=as_li_tl?ie=UTF8&camp=3414&creative=21718&creativeASIN=9332575770&linkCode=as2&tag=opsbears01-21&linkId=a2d4ce18002f19dff10bb165a5806a00'
    ]
];

$countryMap = [
    'HU' => 'DE',
    'AT' => 'DE',
    'GB' => 'UK',
    'IE' => 'GB',
];

$geoIpCountry = 'US';
if (function_exists('geoip_country_code_by_name')) {
    $geoIpCountry = strtoupper(geoip_country_code_by_name($_SERVER['REMOTE_ADDR']));
}

if (array_key_exists($geoIpCountry, $countryMap)) {
    $geoIpCountry = $countryMap[$geoIpCountry];
}

if (!array_key_exists($_GET['book'], $recommendations)) {
    header("404 Not Found");
    echo(file_get_contents('404.html'));
    exit;
}

if (!array_key_exists($geoIpCountry, $recommendations[$_GET['book']])) {
    $geoIpCountry = 'US';
}

header("Location: " . $recommendations[$_GET['book']][$geoIpCountry]);
