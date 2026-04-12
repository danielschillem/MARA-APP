<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ConversationTest extends TestCase
{
    use RefreshDatabase;

    public function test_start_anonymous_conversation(): void
    {
        $response = $this->postJson('/api/conversations/anonymous', [
            'initial_message' => 'Bonjour, j\'ai besoin d\'aide',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['conversation_id', 'session_token']);
    }

    public function test_anonymous_conversation_creates_welcome_message(): void
    {
        $response = $this->postJson('/api/conversations/anonymous');
        $convId = $response->json('conversation_id');
        $token = $response->json('session_token');

        $msgs = $this->getJson("/api/conversations/{$convId}/messages?token={$token}");
        $msgs->assertOk();

        $messages = $msgs->json();
        $this->assertCount(1, $messages);
        $this->assertFalse($messages[0]['is_from_visitor']);
    }

    public function test_anonymous_with_initial_message(): void
    {
        $response = $this->postJson('/api/conversations/anonymous', [
            'initial_message' => 'Je suis en danger',
        ]);

        $convId = $response->json('conversation_id');
        $token = $response->json('session_token');

        $msgs = $this->getJson("/api/conversations/{$convId}/messages?token={$token}");
        $messages = $msgs->json();

        $this->assertCount(2, $messages);
        $this->assertFalse($messages[0]['is_from_visitor']);
        $this->assertTrue($messages[1]['is_from_visitor']);
        $this->assertEquals('Je suis en danger', $messages[1]['body']);
    }

    public function test_send_message_as_anonymous(): void
    {
        $resp = $this->postJson('/api/conversations/anonymous');
        $convId = $resp->json('conversation_id');
        $token = $resp->json('session_token');

        $msgResp = $this->postJson("/api/conversations/{$convId}/messages?token={$token}", [
            'body' => 'Mon message anonyme',
        ]);

        $msgResp->assertStatus(201)
            ->assertJsonFragment(['body' => 'Mon message anonyme', 'is_from_visitor' => true]);
    }

    public function test_send_message_on_closed_conversation(): void
    {
        $conseiller = User::create([
            'name' => 'Conseiller',
            'email' => 'cons@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        $resp = $this->postJson('/api/conversations/anonymous');
        $convId = $resp->json('conversation_id');
        $token = $resp->json('session_token');

        // Close it
        $this->actingAs($conseiller)->postJson("/api/conversations/{$convId}/close");

        // Try sending
        $msgResp = $this->postJson("/api/conversations/{$convId}/messages?token={$token}", [
            'body' => 'Message après fermeture',
        ]);

        $msgResp->assertStatus(403);
    }

    public function test_assign_conversation(): void
    {
        $conseiller = User::create([
            'name' => 'Conseiller Assign',
            'email' => 'assign@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        $resp = $this->postJson('/api/conversations/anonymous');
        $convId = $resp->json('conversation_id');

        $assignResp = $this->actingAs($conseiller)
            ->postJson("/api/conversations/{$convId}/assign");

        $assignResp->assertOk()
            ->assertJsonFragment(['message' => 'Conversation prise en charge']);
    }

    public function test_close_conversation(): void
    {
        $conseiller = User::create([
            'name' => 'Conseiller Close',
            'email' => 'close@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        $resp = $this->postJson('/api/conversations/anonymous');
        $convId = $resp->json('conversation_id');

        $closeResp = $this->actingAs($conseiller)
            ->postJson("/api/conversations/{$convId}/close");

        $closeResp->assertOk()
            ->assertJsonFragment(['message' => 'Conversation fermée']);

        $this->assertDatabaseHas('conversations', [
            'id' => $convId,
            'status' => 'fermee',
        ]);
    }

    public function test_list_conversations_requires_auth(): void
    {
        $response = $this->getJson('/api/conversations');
        $response->assertStatus(401);
    }

    public function test_list_conversations_as_conseiller(): void
    {
        $conseiller = User::create([
            'name' => 'Conseiller List',
            'email' => 'list@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        // Create a conversation
        $this->postJson('/api/conversations/anonymous');

        $response = $this->actingAs($conseiller)->getJson('/api/conversations');
        $response->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_polling_messages_with_after(): void
    {
        $resp = $this->postJson('/api/conversations/anonymous', [
            'initial_message' => 'Premier message',
        ]);

        $convId = $resp->json('conversation_id');
        $token = $resp->json('session_token');

        // Get all messages
        $all = $this->getJson("/api/conversations/{$convId}/messages?token={$token}");
        $lastId = collect($all->json())->last()['id'];

        // Send another
        $this->postJson("/api/conversations/{$convId}/messages?token={$token}", [
            'body' => 'Nouveau message',
        ]);

        // Poll only after last id
        $polled = $this->getJson("/api/conversations/{$convId}/messages?token={$token}&after={$lastId}");
        $polled->assertOk();
        $this->assertCount(1, $polled->json());
        $this->assertEquals('Nouveau message', $polled->json()[0]['body']);
    }

    public function test_unauthorized_token_rejected(): void
    {
        $resp = $this->postJson('/api/conversations/anonymous');
        $convId = $resp->json('conversation_id');

        $response = $this->getJson("/api/conversations/{$convId}/messages?token=wrong-token");
        $response->assertStatus(403);
    }
}
