<?php

namespace Tests\Feature;

use App\Models\Resource;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ResourceTest extends TestCase
{
    use RefreshDatabase;

    public function test_list_published_resources(): void
    {
        Resource::create([
            'title' => 'Guide juridique',
            'type' => 'guide',
            'is_published' => true,
        ]);
        Resource::create([
            'title' => 'Brouillon non publié',
            'type' => 'article',
            'is_published' => false,
        ]);

        $response = $this->getJson('/api/resources');
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Guide juridique', $response->json('data.0.title'));
    }

    public function test_filter_resources_by_type(): void
    {
        Resource::create(['title' => 'Vidéo A', 'type' => 'video', 'is_published' => true]);
        Resource::create(['title' => 'Article B', 'type' => 'article', 'is_published' => true]);

        $response = $this->getJson('/api/resources?type=video');
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Vidéo A', $response->json('data.0.title'));
    }

    public function test_search_resources(): void
    {
        Resource::create(['title' => 'Protection des enfants', 'type' => 'guide', 'is_published' => true]);
        Resource::create(['title' => 'Droit des femmes', 'type' => 'loi', 'is_published' => true]);

        $response = $this->getJson('/api/resources?search=enfants');
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    public function test_create_resource_requires_auth(): void
    {
        $response = $this->postJson('/api/resources', [
            'title' => 'Nouvelle ressource',
            'type' => 'article',
        ]);

        $response->assertStatus(401);
    }

    public function test_create_resource_as_authenticated(): void
    {
        $user = User::create([
            'name' => 'Admin Res',
            'email' => 'admin@res.test',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'admin',
        ]);

        $response = $this->actingAs($user)->postJson('/api/resources', [
            'title' => 'Nouvelle ressource créée',
            'type' => 'article',
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['title' => 'Nouvelle ressource créée']);
    }

    public function test_update_resource(): void
    {
        $user = User::create([
            'name' => 'Admin Update',
            'email' => 'update@res.test',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'admin',
        ]);

        $resource = Resource::create([
            'title' => 'Ancien titre',
            'type' => 'guide',
            'is_published' => true,
        ]);

        $response = $this->actingAs($user)->putJson("/api/resources/{$resource->id}", [
            'title' => 'Nouveau titre',
        ]);

        $response->assertOk()
            ->assertJsonFragment(['title' => 'Nouveau titre']);
    }

    public function test_delete_resource(): void
    {
        $user = User::create([
            'name' => 'Admin Delete',
            'email' => 'delete@res.test',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'admin',
        ]);

        $resource = Resource::create([
            'title' => 'À supprimer',
            'type' => 'article',
            'is_published' => true,
        ]);

        $response = $this->actingAs($user)->deleteJson("/api/resources/{$resource->id}");
        $response->assertOk()
            ->assertJsonFragment(['message' => 'Ressource supprimée']);

        $this->assertDatabaseMissing('resources', ['id' => $resource->id]);
    }
}
