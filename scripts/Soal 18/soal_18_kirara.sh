
#!/bin/bash
set -e

FILE="/var/www/api/index.php"

if [ -f "$FILE" ]; then
    cp "$FILE" "$FILE.bak-no18"
fi

cat > "$FILE" <<'PHP'
<?php
header('Content-Type: application/json; charset=UTF-8');

$hostname = gethostname();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri = $_SERVER['REQUEST_URI'] ?? '/';
$peer = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$headerIp = $_SERVER['HTTP_X_REAL_IP'] ?? '';

if (
    $peer === '10.76.4.2' &&
    filter_var($headerIp, FILTER_VALIDATE_IP)
) {
    $client = $headerIp;
} else {
    $client = $peer;
}

$detail = json_encode([
    'method' => $method,
    'uri' => $uri,
    'client_ip' => $client
]);

try {
    $pdo = new PDO(
        'mysql:host=10.76.4.9;dbname=db_shibuya_K25;charset=utf8mb4',
        'api_logger',
        'apilogK25',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare(
        'INSERT INTO request_logs
         (source_node, request_detail, client_ip)
         VALUES (:hostname, :detail, :client_ip)'
    );

    $stmt->execute([
        ':hostname' => $hostname,
        ':detail' => $detail,
        ':client_ip' => $client
    ]);

    echo json_encode([
        'status' => 'success',
        'worker' => $hostname,
        'message' => 'Request berhasil dicatat'
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'worker' => $hostname,
        'message' => 'Gagal mencatat request ke database'
    ]);
}
PHP

php -l "$FILE"
nginx -t
nginx -s reload

echo "API cadangan Kirara selesai disiapkan."
