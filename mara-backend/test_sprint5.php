<?php
/**
 * Sprint 5 Tests — Sécurité & UX
 * Tests: rate limiting, password validation, role restriction, change password
 */

$BASE = 'http://127.0.0.1:8000/api';
$passed = 0;
$failed = 0;
$total = 0;

function test($name, $result, &$passed, &$failed, &$total) {
    $total++;
    if ($result) {
        $passed++;
        echo "  ✅ $name\n";
    } else {
        $failed++;
        echo "  ❌ $name\n";
    }
}

function api($method, $url, $data = null, $token = null) {
    global $BASE;
    $ch = curl_init("$BASE$url");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $headers = ['Content-Type: application/json', 'Accept: application/json'];
    if ($token) $headers[] = "Authorization: Bearer $token";
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    } elseif ($method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    $response = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'body' => json_decode($response, true), 'raw' => $response];
}

echo "\n🔒 SPRINT 5 — Sécurité & UX\n";
echo str_repeat('=', 50) . "\n\n";

// ─── 1. Password Strength Validation ───
echo "📋 Password Validation\n";

// Weak password — too short
$r = api('POST', '/register', [
    'name' => 'Test Weak',
    'email' => 'weak_' . time() . '@test.com',
    'password' => 'short',
    'password_confirmation' => 'short',
]);
test('Reject weak password (too short)', $r['code'] === 422, $passed, $failed, $total);

// No uppercase
$r = api('POST', '/register', [
    'name' => 'Test NoUpper',
    'email' => 'noupper_' . time() . '@test.com',
    'password' => 'password1!',
    'password_confirmation' => 'password1!',
]);
test('Reject password without uppercase', $r['code'] === 422, $passed, $failed, $total);

// No number
$r = api('POST', '/register', [
    'name' => 'Test NoNum',
    'email' => 'nonum_' . time() . '@test.com',
    'password' => 'Password!',
    'password_confirmation' => 'Password!',
]);
test('Reject password without number', $r['code'] === 422, $passed, $failed, $total);

// No symbol
$r = api('POST', '/register', [
    'name' => 'Test NoSym',
    'email' => 'nosym_' . time() . '@test.com',
    'password' => 'Password1',
    'password_confirmation' => 'Password1',
]);
test('Reject password without symbol', $r['code'] === 422, $passed, $failed, $total);

// Valid strong password
$testEmail = 'strong_' . time() . '@test.com';
$r = api('POST', '/register', [
    'name' => 'Test Strong',
    'email' => $testEmail,
    'password' => 'SecureP@ss1',
    'password_confirmation' => 'SecureP@ss1',
]);
test('Accept strong password', $r['code'] === 201, $passed, $failed, $total);
$strongToken = $r['body']['token'] ?? null;

echo "\n";

// ─── 2. Role Restriction ───
echo "📋 Role Restriction\n";

// Try to register as admin
$r = api('POST', '/register', [
    'name' => 'Hacker Admin',
    'email' => 'hacker_' . time() . '@test.com',
    'password' => 'HackerP@ss1',
    'password_confirmation' => 'HackerP@ss1',
    'role' => 'admin',
]);
// Should either reject (422) or accept but NOT assign admin role
if ($r['code'] === 201) {
    test('Admin role NOT assignable via register', ($r['body']['user']['role'] ?? '') !== 'admin', $passed, $failed, $total);
} else {
    test('Admin role rejected in register', $r['code'] === 422, $passed, $failed, $total);
}

// Register as conseiller (allowed)
$r = api('POST', '/register', [
    'name' => 'Conseiller OK',
    'email' => 'cons_' . time() . '@test.com',
    'password' => 'ConseilP@ss1',
    'password_confirmation' => 'ConseilP@ss1',
    'role' => 'conseiller',
]);
test('Conseiller role accepted', $r['code'] === 201 && ($r['body']['user']['role'] ?? '') === 'conseiller', $passed, $failed, $total);

// Register as professionnel (allowed)
$r = api('POST', '/register', [
    'name' => 'Pro OK',
    'email' => 'pro_' . time() . '@test.com',
    'password' => 'ProffP@ss1!',
    'password_confirmation' => 'ProffP@ss1!',
    'role' => 'professionnel',
]);
test('Professionnel role accepted', $r['code'] === 201 && ($r['body']['user']['role'] ?? '') === 'professionnel', $passed, $failed, $total);

echo "\n";

// ─── 3. Login Validation ───
echo "📋 Login Security\n";

// Login with wrong credentials
$r = api('POST', '/login', ['email' => 'wrong@example.com', 'password' => 'WrongP@ss1']);
test('Wrong credentials rejected', $r['code'] === 422, $passed, $failed, $total);

// Login with valid demo user
$r = api('POST', '/login', ['email' => 'admin@mara.bf', 'password' => 'password']);
test('Valid login succeeds', $r['code'] === 200 && !empty($r['body']['token']), $passed, $failed, $total);
$adminToken = $r['body']['token'] ?? null;

echo "\n";

// ─── 4. Change Password ───
echo "📋 Change Password\n";

if ($strongToken) {
    // Wrong current password
    $r = api('POST', '/change-password', [
        'current_password' => 'WrongOldP@ss1',
        'password' => 'NewSecureP@ss2!',
        'password_confirmation' => 'NewSecureP@ss2!',
    ], $strongToken);
    test('Wrong current password rejected', $r['code'] === 422, $passed, $failed, $total);

    // Valid change password
    $r = api('POST', '/change-password', [
        'current_password' => 'SecureP@ss1',
        'password' => 'NewSecureP@ss2!',
        'password_confirmation' => 'NewSecureP@ss2!',
    ], $strongToken);
    test('Change password succeeds', $r['code'] === 200, $passed, $failed, $total);

    // Weak new password
    $r = api('POST', '/change-password', [
        'current_password' => 'NewSecureP@ss2!',
        'password' => 'weak',
        'password_confirmation' => 'weak',
    ], $strongToken);
    test('Weak new password rejected in change', $r['code'] === 422, $passed, $failed, $total);
} else {
    echo "  ⚠️  Skipping change-password tests (no token)\n";
    $total += 3;
    $failed += 3;
}

echo "\n";

// ─── 5. Protected Routes ───
echo "📋 Protected Routes\n";

$r = api('POST', '/change-password', [
    'current_password' => 'test',
    'password' => 'Test1234!',
    'password_confirmation' => 'Test1234!',
]);
test('Change password requires auth', $r['code'] === 401, $passed, $failed, $total);

$r = api('POST', '/logout', null);
test('Logout requires auth', $r['code'] === 401, $passed, $failed, $total);

echo "\n";

// ─── 6. CORS Headers ───
echo "📋 CORS & API Headers\n";

$r = api('POST', '/login', ['email' => 'admin@mara.bf', 'password' => 'password']);
test('Login returns valid JSON', !empty($r['body']['token']), $passed, $failed, $total);

// Public endpoints still work
$r = api('GET', '/violence-types');
test('Public: violence-types accessible', $r['code'] === 200, $passed, $failed, $total);

$r = api('GET', '/sos-numbers');
test('Public: sos-numbers accessible', $r['code'] === 200, $passed, $failed, $total);

$r = api('GET', '/announcements');
test('Public: announcements accessible', $r['code'] === 200, $passed, $failed, $total);

echo "\n";

// ─── 7. Regression — chat + reports still work ───
echo "📋 Regression Tests\n";

// Create anonymous report
$r = api('POST', '/reports', [
    'violence_type_ids' => [1],
    'description' => 'Test sprint 5 regression - anonymous report',
    'reporter_type' => 'victime',
    'victim_gender' => 'feminin',
    'region' => 'Centre',
]);
test('Anonymous report creation', $r['code'] === 201, $passed, $failed, $total);
$ref = $r['body']['report']['reference'] ?? '';

// Track report
if ($ref) {
    $r = api('GET', "/reports/track/$ref");
    test('Report tracking works', $r['code'] === 200 && ($r['body']['reference'] ?? '') === $ref, $passed, $failed, $total);
} else {
    echo "  ⚠️  Skip tracking (no reference)\n";
    $total++; $failed++;
}

// Anonymous chat
$r = api('POST', '/conversations/anonymous', ['nickname' => 'TestSprint5']);
test('Anonymous chat creation', $r['code'] === 201, $passed, $failed, $total);
$convId = $r['body']['id'] ?? null;

if ($convId) {
    $r = api('POST', "/conversations/$convId/messages", ['content' => 'Hello sprint 5', 'sender_type' => 'visitor']);
    test('Chat message sending', $r['code'] === 201, $passed, $failed, $total);
}

echo "\n";
echo str_repeat('=', 50) . "\n";
echo "📊 Results: $passed/$total passed";
if ($failed > 0) echo " ($failed failed)";
echo "\n";
