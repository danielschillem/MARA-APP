<?php

namespace Tests\Feature;

use App\Models\ServiceDirectory;
use App\Models\SosNumber;
use App\Models\ViolenceType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DirectoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_get_violence_types(): void
    {
        ViolenceType::create([
            'slug' => 'violence-physique',
            'label_fr' => 'Violence physique',
            'label_en' => 'Physical violence',
            'icon' => 'fist',
        ]);
        ViolenceType::create([
            'slug' => 'violence-psychologique',
            'label_fr' => 'Violence psychologique',
            'label_en' => 'Psychological violence',
            'icon' => 'brain',
        ]);

        $response = $this->getJson('/api/violence-types');
        $response->assertOk();
        $this->assertCount(2, $response->json());
    }

    public function test_get_sos_numbers(): void
    {
        SosNumber::create([
            'label' => 'Ligne d\'urgence',
            'number' => '80 00 11 22',
            'description' => 'Numéro gratuit',
            'sort_order' => 1,
        ]);

        $response = $this->getJson('/api/sos-numbers');
        $response->assertOk();
        $this->assertCount(1, $response->json());
        $this->assertEquals('80 00 11 22', $response->json()[0]['number']);
    }

    public function test_get_services(): void
    {
        ServiceDirectory::create([
            'name' => 'Centre Test',
            'type' => 'ong',
            'region' => 'Centre',
            'address' => '123 rue test',
            'phone' => '25 30 00 00',
        ]);

        $response = $this->getJson('/api/services');
        $response->assertOk();
        $this->assertCount(1, $response->json());
    }

    public function test_filter_services_by_type(): void
    {
        ServiceDirectory::create([
            'name' => 'Centre A',
            'type' => 'ong',
            'region' => 'Centre',
        ]);
        ServiceDirectory::create([
            'name' => 'Hôpital B',
            'type' => 'medical',
            'region' => 'Centre',
        ]);

        $response = $this->getJson('/api/services?type=medical');
        $response->assertOk();
        $this->assertCount(1, $response->json());
        $this->assertEquals('Hôpital B', $response->json()[0]['name']);
    }

    public function test_filter_services_by_search(): void
    {
        ServiceDirectory::create([
            'name' => 'Centre Alpha',
            'type' => 'ong',
            'region' => 'Centre',
        ]);
        ServiceDirectory::create([
            'name' => 'Clinique Beta',
            'type' => 'medical',
            'region' => 'Hauts-Bassins',
        ]);

        $response = $this->getJson('/api/services?search=Alpha');
        $response->assertOk();
        $this->assertCount(1, $response->json());
        $this->assertEquals('Centre Alpha', $response->json()[0]['name']);
    }

    public function test_filter_services_by_region(): void
    {
        ServiceDirectory::create([
            'name' => 'Centre Ouaga',
            'type' => 'securite',
            'region' => 'Centre',
        ]);
        ServiceDirectory::create([
            'name' => 'Centre Bobo',
            'type' => 'securite',
            'region' => 'Hauts-Bassins',
        ]);

        $response = $this->getJson('/api/services?region=Centre');
        $response->assertOk();
        $this->assertCount(1, $response->json());
        $this->assertEquals('Centre Ouaga', $response->json()[0]['name']);
    }
}
