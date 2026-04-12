<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('resources', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('type', ['article', 'video', 'loi', 'guide', 'infographie', 'formation']);
            $table->string('category')->nullable();
            $table->string('icon')->nullable();
            $table->string('url')->nullable();
            $table->string('duration')->nullable(); // "8 min de lecture", "5 min"
            $table->string('tag')->nullable();
            $table->boolean('is_published')->default(true);
            $table->timestamps();
        });

        Schema::create('service_directories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['securite', 'ong', 'institutionnel', 'medical', 'urgence', 'juridique']);
            $table->string('address')->nullable();
            $table->string('region')->nullable();
            $table->string('phone')->nullable();
            $table->string('hours')->nullable();
            $table->boolean('is_free')->default(false);
            $table->boolean('is_24h')->default(false);
            $table->timestamps();
        });

        Schema::create('sos_numbers', function (Blueprint $table) {
            $table->id();
            $table->string('label');
            $table->string('description')->nullable();
            $table->string('number');
            $table->string('icon')->nullable();
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sos_numbers');
        Schema::dropIfExists('service_directories');
        Schema::dropIfExists('resources');
    }
};
