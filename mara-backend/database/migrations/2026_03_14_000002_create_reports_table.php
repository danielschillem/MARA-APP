<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique(); // MARA-2026-XXXX
            $table->enum('reporter_type', ['victime', 'temoin', 'proche', 'professionnel'])->default('victime');
            $table->enum('victim_gender', ['feminin', 'masculin', 'autre'])->default('feminin');
            $table->string('victim_age_range')->nullable();
            $table->string('perpetrator_relation')->nullable();

            // Location
            $table->string('region')->nullable();
            $table->string('province')->nullable();
            $table->string('lieu_description')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            // Incident
            $table->date('incident_date')->nullable();
            $table->text('description');
            $table->enum('victim_status', ['en_securite', 'danger_immediat', 'hospitalisee', 'disparue', 'inconnu'])->default('inconnu');

            // Contact (optional)
            $table->string('contact_phone')->nullable();
            $table->string('contact_time_pref')->nullable();

            // Processing
            $table->enum('status', ['nouveau', 'en_cours', 'resolu', 'urgent', 'cloture'])->default('nouveau');
            $table->enum('priority', ['basse', 'moyenne', 'haute', 'critique'])->default('moyenne');
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
        });

        Schema::create('report_violence_type', function (Blueprint $table) {
            $table->foreignId('report_id')->constrained()->cascadeOnDelete();
            $table->foreignId('violence_type_id')->constrained()->cascadeOnDelete();
            $table->primary(['report_id', 'violence_type_id']);
        });

        Schema::create('report_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained()->cascadeOnDelete();
            $table->string('filename');
            $table->string('path');
            $table->string('mime_type');
            $table->unsignedBigInteger('size'); // bytes
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_attachments');
        Schema::dropIfExists('report_violence_type');
        Schema::dropIfExists('reports');
    }
};
