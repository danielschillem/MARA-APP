<?php
// Sprint 3 API tests

$base = 'http://127.0.0.1:8000/api';
$passed = 0;
$failed = 0;

function req($method, $url, $data = null, $token = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    } elseif ($method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'body' => json_decode($body, true)];
}

function check($label, $condition) {
    global $passed, $failed;
    if ($condition) { echo "  ✓ $label\n"; $passed++; }
    else { echo "  ✗ $label\n"; $failed++; }
}

// Register a professionnel
echo "=== 1. Register professionnel ===\n";
$email = 'sprint3_' . time() . '@test.com';
$r = req('POST', "$base/register", [
    'name' => 'Dr Sprint3',
    'email' => $email,
    'password' => 'Password1!',
    'password_confirmation' => 'Password1!',
    'role' => 'professionnel'
]);
$token = $r['body']['token'];
check('Registration OK', $r['code'] === 201 && $token);

// Create a report
echo "\n=== 2. Create report ===\n";
$r = req('POST', "$base/reports", [
    'violence_type_ids' => [1],
    'description' => 'Cas de test sprint 3 pour dashboard - details importants ici',
    'region' => 'Centre',
    'reporter_type' => 'victime',
    'victim_gender' => 'feminin'
]);
check('Report created', $r['code'] === 201);
$ref = $r['body']['report']['reference'];
$reportId = $r['body']['report']['id'];
echo "  Reference: $ref (ID: $reportId)\n";

// Dashboard
echo "\n=== 3. Dashboard endpoint ===\n";
$d = req('GET', "$base/dashboard", null, $token);
check('Dashboard 200', $d['code'] === 200);
$keys = array_keys($d['body']);
check('Has reports_total', in_array('reports_total', $keys));
check('Has reports_by_priority', in_array('reports_by_priority', $keys));
check('Has reports_by_violence_type', in_array('reports_by_violence_type', $keys));
check('Has reports_by_month', in_array('reports_by_month', $keys));
check('Has recent_reports', in_array('recent_reports', $keys));
check('Has my_assigned', in_array('my_assigned', $keys));
check('reports_total >= 1', $d['body']['reports_total'] >= 1);

// Reports with filters
echo "\n=== 4. Reports list with filters ===\n";
$r = req('GET', "$base/reports?per_page=5", null, $token);
check('Reports paginated', $r['code'] === 200 && isset($r['body']['current_page']));
check('Per page = 5', $r['body']['per_page'] == 5);

$r2 = req('GET', "$base/reports?search=sprint+3", null, $token);
check('Search filter works', $r2['code'] === 200);

$r3 = req('GET', "$base/reports?assigned_to=unassigned", null, $token);
check('Unassigned filter works', $r3['code'] === 200);

// Update report with notes
echo "\n=== 5. Update report (status + notes) ===\n";
$r = req('PUT', "$base/reports/$reportId", [
    'status' => 'en_cours',
    'priority' => 'haute',
    'notes' => 'Notes internes de test sprint 3'
], $token);
check('Update 200', $r['code'] === 200);
check('Status updated', $r['body']['status'] === 'en_cours');
check('Notes saved', $r['body']['notes'] === 'Notes internes de test sprint 3');

// Assign to self
echo "\n=== 6. Assign to self ===\n";
$me = req('GET', "$base/me", null, $token);
$myId = $me['body']['id'];
$r = req('PUT', "$base/reports/$reportId", [
    'assigned_to' => $myId
], $token);
check('Assigned to self', $r['body']['assigned_to'] == $myId);

// Check my_assigned now includes the report
echo "\n=== 7. My assigned in dashboard ===\n";
$d2 = req('GET', "$base/dashboard", null, $token);
$found = false;
foreach ($d2['body']['my_assigned'] as $rep) {
    if ($rep['id'] == $reportId) { $found = true; break; }
}
check('Report appears in my_assigned', $found);

echo "\n=============================\n";
echo "PASSED: $passed | FAILED: $failed\n";
echo "=============================\n";
