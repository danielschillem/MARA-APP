<?php

namespace Tests\Feature;

use App\Models\Report;
use App\Models\User;
use App\Models\ViolenceType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    private ViolenceType $violenceType;

    protected function setUp(): void
    {
        parent::setUp();
        $this->violenceType = ViolenceType::create([
            'slug' => 'violence-physique',
            'label_fr' => 'Violence physique',
            'label_en' => 'Physical violence',
            'icon' => 'fist',
        ]);
    }

    public function test_create_anonymous_report(): void
    {
        $response = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Description détaillée du signalement anonyme',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
            'region' => 'Centre',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('message', 'Signalement enregistré avec succès')
            ->assertJsonStructure(['report' => ['id', 'reference']]);
    }

    public function test_report_gets_reference(): void
    {
        $response = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Un signalement test avec référence',
            'reporter_type' => 'temoin',
            'victim_gender' => 'masculin',
        ]);

        $response->assertStatus(201);
        $ref = $response->json('report.reference');
        $this->assertStringStartsWith('MARA-', $ref);
    }

    public function test_danger_immediat_auto_escalates(): void
    {
        $response = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Situation de danger immédiat',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
            'victim_status' => 'danger_immediat',
            'region' => 'Centre',
        ]);

        $response->assertStatus(201);
        $this->assertEquals('critique', $response->json('report.priority'));
        $this->assertEquals('urgent', $response->json('report.status'));
    }

    public function test_track_report_by_reference(): void
    {
        $createResponse = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Signalement pour suivi',
            'reporter_type' => 'proche',
            'victim_gender' => 'feminin',
        ]);

        $ref = $createResponse->json('report.reference');

        $response = $this->getJson("/api/reports/track/{$ref}");
        $response->assertOk()
            ->assertJsonFragment(['reference' => $ref]);
    }

    public function test_track_unknown_reference_returns_404(): void
    {
        $response = $this->getJson('/api/reports/track/MARA-9999-9999');
        $response->assertStatus(404);
    }

    public function test_report_validation_rejects_short_description(): void
    {
        $response = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'court',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('description');
    }

    public function test_report_validation_requires_violence_type(): void
    {
        $response = $this->postJson('/api/reports', [
            'description' => 'Description valide pour test',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('violence_type_ids');
    }

    public function test_list_reports_requires_auth(): void
    {
        $response = $this->getJson('/api/reports');
        $response->assertStatus(401);
    }

    public function test_list_reports_as_professional(): void
    {
        $user = User::create([
            'name' => 'Pro Test',
            'email' => 'pro@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'professionnel',
        ]);

        // Create a report
        $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Signalement visible par les pros',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
        ]);

        $response = $this->actingAs($user)->getJson('/api/reports');
        $response->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_update_report_status(): void
    {
        $user = User::create([
            'name' => 'Pro Update',
            'email' => 'update@test.com',
            'password' => bcrypt('Passw0rd!'),
            'role' => 'professionnel',
        ]);

        $created = $this->postJson('/api/reports', [
            'violence_type_ids' => [$this->violenceType->id],
            'description' => 'Signalement à mettre à jour',
            'reporter_type' => 'victime',
            'victim_gender' => 'feminin',
        ]);

        $reportId = $created->json('report.id');

        $response = $this->actingAs($user)->putJson("/api/reports/{$reportId}", [
            'status' => 'en_cours',
            'priority' => 'haute',
        ]);

        $response->assertOk()
            ->assertJsonFragment(['status' => 'en_cours', 'priority' => 'haute']);
    }

    public function test_update_report_requires_auth(): void
    {
        $response = $this->putJson('/api/reports/1', ['status' => 'en_cours']);
        $response->assertStatus(401);
    }
}
