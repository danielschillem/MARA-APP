<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\ViolenceType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        ViolenceType::create(['slug' => 'physique', 'label_fr' => 'Physique', 'label_en' => 'Physical', 'icon' => 'fist']);
    }

    public function test_register_with_strong_password(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'Passw0rd!',
            'password_confirmation' => 'Passw0rd!',
            'role' => 'conseiller',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['user', 'token']);

        $this->assertDatabaseHas('users', ['email' => 'test@example.com', 'role' => 'conseiller']);
    }

    public function test_register_rejects_weak_password(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test',
            'email' => 'weak@example.com',
            'password' => 'simple',
            'password_confirmation' => 'simple',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    public function test_register_rejects_password_without_uppercase(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test',
            'email' => 'weak@example.com',
            'password' => 'passw0rd!',
            'password_confirmation' => 'passw0rd!',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    public function test_register_rejects_password_without_symbol(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Test',
            'email' => 'weak@example.com',
            'password' => 'Passw0rdX',
            'password_confirmation' => 'Passw0rdX',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('password');
    }

    public function test_register_cannot_assign_admin_role(): void
    {
        $response = $this->postJson('/api/register', [
            'name' => 'Hacker',
            'email' => 'hacker@example.com',
            'password' => 'Passw0rd!',
            'password_confirmation' => 'Passw0rd!',
            'role' => 'admin',
        ]);

        // Should be rejected by validation (admin not in allowed roles)
        $response->assertStatus(422);
    }

    public function test_login_with_valid_credentials(): void
    {
        User::create([
            'name' => 'Login Test',
            'email' => 'login@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'login@test.com',
            'password' => 'Passw0rd!',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['user', 'token']);
    }

    public function test_login_with_wrong_password(): void
    {
        User::create([
            'name' => 'Login Test',
            'email' => 'login@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'conseiller',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'login@test.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(422);
    }

    public function test_logout_requires_auth(): void
    {
        $response = $this->postJson('/api/logout');
        $response->assertStatus(401);
    }

    public function test_logout_works_when_authenticated(): void
    {
        $user = User::create([
            'name' => 'Logout Test',
            'email' => 'logout@test.com',
            'password' => bcrypt('Passw0rd!Test'),
            'role' => 'conseiller',
        ]);

        // Login first to get a real token
        $login = $this->postJson('/api/login', [
            'email' => 'logout@test.com',
            'password' => 'Passw0rd!Test',
        ]);

        $token = $login->json('token');

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$token}",
        ])->postJson('/api/logout');

        $response->assertOk();
    }

    public function test_me_returns_current_user(): void
    {
        $user = User::create([
            'name' => 'Me Test',
            'email' => 'me@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'professionnel',
        ]);

        $response = $this->actingAs($user)->getJson('/api/me');
        $response->assertOk()
            ->assertJsonFragment(['email' => 'me@test.com']);
    }

    public function test_change_password_requires_correct_current(): void
    {
        $user = User::create([
            'name' => 'Change Pwd',
            'email' => 'pwd@test.com',
            'password' => bcrypt('OldPassw0rd!'),
            'role' => 'conseiller',
        ]);

        $response = $this->actingAs($user)->postJson('/api/change-password', [
            'current_password' => 'WrongPassword1!',
            'password' => 'NewPassw0rd!',
            'password_confirmation' => 'NewPassw0rd!',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('current_password');
    }

    public function test_change_password_succeeds(): void
    {
        $user = User::create([
            'name' => 'Change Pwd',
            'email' => 'pwd@test.com',
            'password' => bcrypt('OldPassw0rd!'),
            'role' => 'conseiller',
        ]);

        $response = $this->actingAs($user)->postJson('/api/change-password', [
            'current_password' => 'OldPassw0rd!',
            'password' => 'NewPassw0rd!',
            'password_confirmation' => 'NewPassw0rd!',
        ]);

        $response->assertOk();
    }
}
