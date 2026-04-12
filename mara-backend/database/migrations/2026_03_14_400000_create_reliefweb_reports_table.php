<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reliefweb_reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('rw_id')->unique();
            $table->string('title', 500);
            $table->text('body')->nullable();
            $table->string('url', 500)->nullable();
            $table->string('source')->nullable();
            $table->string('country')->nullable();
            $table->string('theme')->nullable();
            $table->string('disaster_type')->nullable();
            $table->string('format')->nullable();
            $table->string('language')->nullable();
            $table->date('published_at')->nullable();
            $table->timestamps();

            $table->index('published_at');
            $table->index('source');
            $table->index('theme');
            $table->index('country');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reliefweb_reports');
    }
};
