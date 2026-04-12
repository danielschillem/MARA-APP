<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->string('audio_path')->nullable()->after('body');
            $table->string('audio_mime')->nullable()->after('audio_path');
            $table->unsignedInteger('audio_duration')->nullable()->after('audio_mime');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropColumn(['audio_path', 'audio_mime', 'audio_duration']);
        });
    }
};
