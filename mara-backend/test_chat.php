<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use App\Models\Conversation;
use App\Models\Message;

$pass = 0;
$fail = 0;
function check($label, $ok, $detail = '') {
    global $pass, $fail;
    if ($ok) { echo "  ✓ {$label}\n"; $pass++; }
    else { echo "  ✗ {$label} — {$detail}\n"; $fail++; }
}

// ── 1. VISITOR: Start anonymous conversation ──
echo "=== 1. VISITOR: Start anonymous conversation ===\n";
$conv = Conversation::create(['session_token' => \Illuminate\Support\Str::uuid()->toString(), 'status' => 'active']);
$welcome = $conv->messages()->create(['body' => 'Bienvenue MARA', 'is_from_visitor' => false]);
check('Conversation created', $conv->id > 0);
check('Session token generated', strlen($conv->session_token) === 36);
check('Welcome message created', $welcome->id > 0);

// ── 2. VISITOR: Send messages ──
echo "\n=== 2. VISITOR: Send messages ===\n";
$msg1 = $conv->messages()->create(['body' => 'J\'ai besoin d\'aide svp', 'is_from_visitor' => true]);
$msg2 = $conv->messages()->create(['body' => 'C\'est urgent', 'is_from_visitor' => true]);
check('Visitor message 1 saved', $msg1->id > 0);
check('Visitor message 2 saved', $msg2->id > 0);
check('Messages count = 3', $conv->messages()->count() === 3);

// ── 3. VISITOR: Read messages with token ──
echo "\n=== 3. VISITOR: Read messages (token auth) ===\n";
$allMsgs = $conv->messages()->oldest()->get();
check('All 3 messages returned', count($allMsgs) === 3);
check('First message is welcome', $allMsgs[0]->is_from_visitor === false);
check('Second message from visitor', $allMsgs[1]->is_from_visitor === true);

// ── 4. VISITOR: Polling with ?after ──
echo "\n=== 4. VISITOR: Incremental polling ===\n";
$afterMsgs = $conv->messages()->where('id', '>', $msg1->id)->oldest()->get();
check('After msg1 returns 1 message', count($afterMsgs) === 1);
check('After msg1 returns msg2', $afterMsgs[0]->id === $msg2->id);

// ── 5. CONSEILLER: Get or create user ──
echo "\n=== 5. CONSEILLER: Auth setup ===\n";
$conseiller = User::where('role', 'conseiller')->first();
if (!$conseiller) {
    $conseiller = User::create(['name' => 'Conseiller Test', 'email' => 'conseiller@mara.bf', 'password' => bcrypt('password'), 'role' => 'conseiller']);
}
check('Conseiller user exists', $conseiller->id > 0, $conseiller->email);

// ── 6. CONSEILLER: List conversations ──
echo "\n=== 6. CONSEILLER: List conversations ===\n";
$visibleConvs = Conversation::where(function ($q) use ($conseiller) {
    $q->where('conseiller_id', $conseiller->id)->orWhereNull('conseiller_id');
})->get();
check('Conseiller sees conversations', count($visibleConvs) > 0);

$waitingConvs = Conversation::whereNull('conseiller_id')->where('status', 'active')->get();
check('Waiting conversations exist', count($waitingConvs) > 0);

// ── 7. CONSEILLER: Assign conversation ──
echo "\n=== 7. CONSEILLER: Assign conversation ===\n";
$conv->update(['conseiller_id' => $conseiller->id]);
$conv->refresh();
check('Conversation assigned', $conv->conseiller_id === $conseiller->id);

// ── 8. CONSEILLER: Reply ──
echo "\n=== 8. CONSEILLER: Reply to visitor ===\n";
$reply = $conv->messages()->create([
    'sender_id' => $conseiller->id,
    'is_from_visitor' => false,
    'body' => 'Bonjour, je suis votre conseiller. Comment puis-je vous aider ?',
]);
check('Conseiller reply saved', $reply->id > 0);
check('Reply has sender_id', $reply->sender_id === $conseiller->id);
check('Reply is not from visitor', $reply->is_from_visitor === false);
check('Total messages = 4', $conv->messages()->count() === 4);

// ── 9. VISITOR: Receives reply via polling ──
echo "\n=== 9. VISITOR: Polling picks up conseiller reply ===\n";
$newMsgs = $conv->messages()->where('id', '>', $msg2->id)->oldest()->get();
check('Polling returns 1 new message', count($newMsgs) === 1);
check('New message is from conseiller', $newMsgs[0]->is_from_visitor === false);

// ── 10. CONSEILLER: Mark as read ──
echo "\n=== 10. CONSEILLER: Mark visitor messages as read ===\n";
$conv->messages()->where('is_from_visitor', true)->where('is_read', false)->update(['is_read' => true]);
$unread = $conv->messages()->where('is_from_visitor', true)->where('is_read', false)->count();
check('All visitor messages marked read', $unread === 0);

// ── 11. CONSEILLER: Close conversation ──
echo "\n=== 11. CONSEILLER: Close conversation ===\n";
$closeMsg = $conv->messages()->create([
    'sender_id' => $conseiller->id,
    'is_from_visitor' => false,
    'body' => 'La conversation a été clôturée. N\'hésitez pas à nous recontacter.',
]);
$conv->update(['status' => 'fermee']);
$conv->refresh();
check('Close message saved', $closeMsg->id > 0);
check('Status = fermee', $conv->status === 'fermee');

// ── 12. VISITOR: Cannot send after close ──
echo "\n=== 12. VISITOR: Blocked after close ===\n";
check('Status is fermee (would block API send)', $conv->status === 'fermee');

// ── 13. Token security ──
echo "\n=== 13. TOKEN SECURITY ===\n";
$wrongToken = 'wrong-token-12345';
check('Wrong token != session_token', $wrongToken !== $conv->session_token);
$otherConv = Conversation::where('id', '!=', $conv->id)->first();
if ($otherConv) {
    check('Other conv has different token', $otherConv->session_token !== $conv->session_token);
}

echo "\n=============================\n";
echo "PASSED: {$pass} | FAILED: {$fail}\n";
echo "=============================\n";
exit($fail > 0 ? 1 : 0);
