<?php
/**
 * Seed audio resources for illiterate users.
 * Run: php artisan db:seed --class=AudioResourceSeeder
 * Or:  php seed_audio.php
 */

require __DIR__ . '/../../vendor/autoload.php';
$app = require_once __DIR__ . '/../../bootstrap/app.php';
$app->handleRequest(\Illuminate\Http\Request::capture());

use App\Models\Resource;

$audioResources = [
    [
        'title' => 'Comprendre les violences — Version audio',
        'description' => "Écoutez cette ressource pour comprendre les différentes formes de violences faites aux femmes et aux enfants au Burkina Faso. Ce guide audio explique comment identifier les violences physiques, psychologiques, sexuelles et économiques.",
        'type' => 'audio',
        'category' => 'Sensibilisation',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'duration' => '5 min',
        'tag' => 'Accessible',
    ],
    [
        'title' => 'Vos droits en tant que femme — Audio',
        'description' => "Ce guide audio présente les droits fondamentaux des femmes au Burkina Faso : droit à la protection, droit à l'éducation, droit à la santé, et les recours juridiques disponibles en cas de violence.",
        'type' => 'audio',
        'category' => 'Droits',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        'duration' => '7 min',
        'tag' => 'Accessible',
    ],
    [
        'title' => 'Comment signaler une violence — Guide audio',
        'description' => "Apprenez en écoutant comment utiliser la plateforme MARA pour signaler une violence. Ce guide audio vous accompagne étape par étape dans le processus de signalement.",
        'type' => 'audio',
        'category' => 'Guide pratique',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        'duration' => '4 min',
        'tag' => 'Tutoriel',
    ],
    [
        'title' => 'Les numéros d\'urgence — Audio',
        'description' => "Écoutez la liste des numéros d'urgence importants au Burkina Faso : police (17), pompiers (18), SAMU, Ligne Verte MARA (80 00 11 52), et les services de protection des femmes et enfants.",
        'type' => 'audio',
        'category' => 'Urgence',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        'duration' => '3 min',
        'tag' => 'Urgence',
    ],
    [
        'title' => 'Protéger les enfants — Audio',
        'description' => "Ce guide audio explique les signes de maltraitance chez les enfants et les démarches à suivre pour les protéger. Destiné aux parents, enseignants et voisins.",
        'type' => 'audio',
        'category' => 'Protection',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        'duration' => '6 min',
        'tag' => 'Enfants',
    ],
    [
        'title' => 'Témoignage de survivante — Audio',
        'description' => "Écoutez le témoignage inspirant d'une survivante de violence qui a trouvé de l'aide grâce aux services d'accompagnement. Son histoire montre qu'il est possible de s'en sortir.",
        'type' => 'audio',
        'category' => 'Témoignage',
        'icon' => 'volume-2',
        'audio_url' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        'duration' => '8 min',
        'tag' => 'Témoignage',
    ],
];

$added = 0;
foreach ($audioResources as $r) {
    if (!Resource::where('title', $r['title'])->exists()) {
        Resource::create($r);
        $added++;
    }
}

// Also add audio_url to some existing text resources (for dual-mode)
$existingWithAudio = [
    'Comprendre les violences basées sur le genre' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    'Loi n°061-2015 sur les VBG' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    'Guide de premiers secours psychologiques' => 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
];

$updated = 0;
foreach ($existingWithAudio as $title => $audioUrl) {
    $resource = Resource::where('title', 'like', "%{$title}%")->first();
    if ($resource && !$resource->audio_url) {
        $resource->update(['audio_url' => $audioUrl]);
        $updated++;
    }
}

echo "Audio resources added: {$added}, existing updated with audio: {$updated}\n";
echo "Total resources: " . Resource::count() . " (audio: " . Resource::where('type', 'audio')->count() . ")\n";
