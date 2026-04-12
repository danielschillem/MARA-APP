<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_directories', function (Blueprint $table) {
            $table->text('description')->nullable()->after('name');
            $table->string('email')->nullable()->after('phone');
            $table->string('website')->nullable()->after('email');
            $table->decimal('latitude', 10, 7)->nullable()->after('is_24h');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
        });
    }

    public function down(): void
    {
        Schema::table('service_directories', function (Blueprint $table) {
            $table->dropColumn(['description', 'email', 'website', 'latitude', 'longitude']);
        });
    }
};
