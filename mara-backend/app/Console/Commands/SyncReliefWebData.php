<?php

namespace App\Console\Commands;

use App\Services\ReliefWebService;
use Illuminate\Console\Command;

class SyncReliefWebData extends Command
{
    protected $signature = 'reliefweb:sync {--pages=5 : Number of pages to fetch (200 reports per page)}';
    protected $description = 'Fetch and sync ReliefWeb reports about violence / protection in Burkina Faso';

    public function handle(ReliefWebService $service): int
    {
        $pages = (int) $this->option('pages');
        $this->info("Syncing ReliefWeb data ({$pages} pages max)...");

        $count = $service->sync($pages);

        $this->info("Done! {$count} reports synced.");
        return self::SUCCESS;
    }
}
