<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $driver = DB::getDriverName();

        // 1. Add audio_url column (skip if already exists)
        if (!Schema::hasColumn('resources', 'audio_url')) {
            Schema::table('resources', function (Blueprint $table) {
                $table->string('audio_url')->nullable()->after('url');
            });
        }

        // 2. Expand the type constraint to include 'audio'
        if ($driver === 'pgsql') {
            // PostgreSQL: drop and recreate the CHECK constraint
            DB::statement('ALTER TABLE resources DROP CONSTRAINT IF EXISTS resources_type_check');
            DB::statement("ALTER TABLE resources ADD CONSTRAINT resources_type_check CHECK (type = ANY ('{article,video,loi,guide,infographie,formation,audio}'::text[]))");
        } elseif ($driver === 'sqlite') {
            // SQLite: recreate the table (SQLite doesn't support ALTER COLUMN)
            DB::statement("CREATE TABLE resources_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title VARCHAR(255) NOT NULL,
                description TEXT,
                type VARCHAR(255) CHECK(type IN ('article','video','loi','guide','infographie','formation','audio')) NOT NULL,
                category VARCHAR(255),
                icon VARCHAR(255),
                url VARCHAR(255),
                audio_url VARCHAR(255),
                duration VARCHAR(255),
                tag VARCHAR(255),
                is_published BOOLEAN DEFAULT 1,
                created_at TIMESTAMP,
                updated_at TIMESTAMP
            )");
            DB::statement("INSERT INTO resources_new SELECT id, title, description, type, category, icon, url, audio_url, duration, tag, is_published, created_at, updated_at FROM resources");
            DB::statement("DROP TABLE resources");
            DB::statement("ALTER TABLE resources_new RENAME TO resources");
        }
        // MySQL/MariaDB: enum modification not needed here (handled by original schema)
    }

    public function down(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE resources DROP CONSTRAINT IF EXISTS resources_type_check');
            DB::statement("ALTER TABLE resources ADD CONSTRAINT resources_type_check CHECK (type = ANY ('{article,video,loi,guide,infographie,formation}'::text[]))");
        }

        Schema::table('resources', function (Blueprint $table) {
            $table->dropColumn('audio_url');
        });
    }
};
