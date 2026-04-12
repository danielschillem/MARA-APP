<?php

namespace Tests\Feature;

use App\Models\ReliefWebReport;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ObservatoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_observatory_stats_empty(): void
    {
        $response = $this->getJson('/api/observatory/stats');

        $response->assertOk()
            ->assertJsonFragment(['total' => 0]);
    }

    public function test_observatory_stats_with_data(): void
    {
        ReliefWebReport::create([
            'rw_id' => 1001,
            'title' => 'Rapport test BFA',
            'url' => 'https://reliefweb.int/report/1001',
            'source' => 'UNICEF',
            'theme' => 'Protection',
            'format' => 'Situation Report',
            'published_at' => now()->subDays(10),
        ]);
        ReliefWebReport::create([
            'rw_id' => 1002,
            'title' => 'Rapport test 2 BFA',
            'url' => 'https://reliefweb.int/report/1002',
            'source' => 'UNHCR',
            'theme' => 'Protection, Gender-Based Violence',
            'format' => 'Analysis',
            'published_at' => now()->subDays(5),
        ]);

        $response = $this->getJson('/api/observatory/stats');

        $response->assertOk()
            ->assertJsonFragment(['total' => 2])
            ->assertJsonStructure([
                'total',
                'sources',
                'themes',
                'by_year',
                'by_month',
                'by_format',
                'date_range',
                'recent',
                'last_sync',
            ]);
    }

    public function test_observatory_reports_paginated(): void
    {
        for ($i = 1; $i <= 25; $i++) {
            ReliefWebReport::create([
                'rw_id' => 2000 + $i,
                'title' => "Rapport paginate {$i}",
                'url' => "https://reliefweb.int/report/" . (2000 + $i),
                'source' => 'OCHA',
                'published_at' => now()->subDays($i),
            ]);
        }

        $response = $this->getJson('/api/observatory/reports');
        $response->assertOk()
            ->assertJsonStructure(['data', 'current_page', 'last_page']);

        $this->assertCount(20, $response->json('data')); // default per_page = 20
    }

    public function test_observatory_reports_search_filter(): void
    {
        ReliefWebReport::create([
            'rw_id' => 3001,
            'title' => 'Violence Gender Report',
            'url' => 'https://reliefweb.int/report/3001',
            'source' => 'UNICEF',
            'published_at' => now(),
        ]);
        ReliefWebReport::create([
            'rw_id' => 3002,
            'title' => 'Food Security Update',
            'url' => 'https://reliefweb.int/report/3002',
            'source' => 'WFP',
            'published_at' => now(),
        ]);

        $response = $this->getJson('/api/observatory/reports?search=Gender');
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertEquals('Violence Gender Report', $response->json('data.0.title'));
    }

    public function test_observatory_reports_source_filter(): void
    {
        ReliefWebReport::create([
            'rw_id' => 4001,
            'title' => 'UNICEF Report',
            'url' => 'https://reliefweb.int/report/4001',
            'source' => 'UNICEF',
            'published_at' => now(),
        ]);
        ReliefWebReport::create([
            'rw_id' => 4002,
            'title' => 'UNHCR Report',
            'url' => 'https://reliefweb.int/report/4002',
            'source' => 'UNHCR',
            'published_at' => now(),
        ]);

        $response = $this->getJson('/api/observatory/reports?source=UNICEF');
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    public function test_observatory_sync_requires_auth(): void
    {
        $response = $this->postJson('/api/observatory/sync');
        $response->assertStatus(401);
    }
}
