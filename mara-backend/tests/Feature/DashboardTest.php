<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use App\Models\ViolenceType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_requires_auth(): void
    {
        $response = $this->getJson('/api/dashboard');
        $response->assertStatus(401);
    }

    public function test_dashboard_returns_stats(): void
    {
        $user = User::create([
            'name' => 'Admin Dashboard',
            'email' => 'admin@dashboard.test',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'admin',
        ]);

        $response = $this->actingAs($user)->getJson('/api/dashboard');

        $response->assertOk()
            ->assertJsonStructure([
                'reports_total',
                'reports_urgent',
                'reports_new',
                'reports_resolved',
                'conversations_active',
                'conversations_waiting',
                'professionals_online',
                'resources_count',
                'reports_by_status',
                'reports_by_region',
                'reports_by_priority',
                'reports_by_month',
                'reports_by_violence_type',
                'recent_reports',
            ]);
    }

    public function test_dashboard_counts_reports(): void
    {
        $user = User::create([
            'name' => 'Pro Dashboard',
            'email' => 'pro@dashboard.test',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'professionnel',
        ]);

        $vt = ViolenceType::create([
            'slug' => 'violence-economique',
            'label_fr' => 'Violence économique',
            'label_en' => 'Economic violence',
            'icon' => 'wallet',
        ]);

        // Create reports via API
        $this->postJson('/api/reports', [
            'violence_type_ids' => [$vt->id],
            'description' => 'Premier signalement test dashboard',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
        ]);

        $this->postJson('/api/reports', [
            'violence_type_ids' => [$vt->id],
            'description' => 'Deuxième signalement test dashboard',
            'reporter_type' => 'temoin',
            'victim_gender' => 'masculin',
        ]);

        $response = $this->actingAs($user)->getJson('/api/dashboard');
        $response->assertOk();
        $this->assertEquals(2, $response->json('reports_total'));
    }

    public function test_report_stats_requires_auth(): void
    {
        $response = $this->getJson('/api/reports/stats');
        $response->assertStatus(401);
    }
}
