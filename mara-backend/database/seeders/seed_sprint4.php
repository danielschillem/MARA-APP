<?php
// Sprint 4 seeder - run: php database/seeders/seed_sprint4.php

require __DIR__ . '/../../vendor/autoload.php';
$app = require_once __DIR__ . '/../../bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Announcement;
use App\Models\ServiceDirectory;
use App\Models\Resource;

// Announcements
if (Announcement::count() === 0) {
    Announcement::insert([
        [
            'title' => 'Journee internationale pour l elimination de la violence a l egard des femmes - 25 novembre 2026',
            'body' => 'Mobilisons-nous contre les violences faites aux femmes.',
            'source' => 'ONU Femmes',
            'is_active' => true,
            'sort_order' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ],
        [
            'title' => 'Nouvelle loi renforçant la protection des victimes de VBG adoptee',
            'body' => 'Le Burkina Faso renforce son arsenal juridique.',
            'source' => 'Ministere de la Justice',
            'is_active' => true,
            'sort_order' => 2,
            'created_at' => now(),
            'updated_at' => now(),
        ],
        [
            'title' => 'Ouverture de 5 nouveaux centres d ecoute dans les regions du Nord et du Sahel',
            'body' => 'Acces aux services d aide renforce.',
            'source' => 'Ministere de la Femme',
            'is_active' => true,
            'sort_order' => 3,
            'created_at' => now(),
            'updated_at' => now(),
        ],
        [
            'title' => 'Formation gratuite sur les droits des femmes - inscriptions ouvertes',
            'body' => 'Programme de sensibilisation communautaire.',
            'source' => 'UNICEF',
            'is_active' => true,
            'sort_order' => 4,
            'created_at' => now(),
            'updated_at' => now(),
        ],
    ]);
    echo "Announcements seeded: " . Announcement::count() . "\n";
} else {
    echo "Announcements already exist: " . Announcement::count() . "\n";
}

// Additional services across regions
$newServices = [
    ['name' => 'Centre d Ecoute Delwende', 'type' => 'ong', 'description' => 'Centre d accueil et d ecoute pour femmes et enfants en detresse', 'address' => 'Secteur 28, Ouagadougou', 'region' => 'Centre', 'phone' => '25 36 07 14', 'hours' => '7h-19h', 'is_free' => true],
    ['name' => 'Hopital de District Do', 'type' => 'medical', 'description' => 'Service de gynecologie et prise en charge des violences sexuelles', 'address' => 'Bobo-Dioulasso', 'region' => 'Hauts-Bassins', 'phone' => '20 97 00 44', 'hours' => '24h/24', 'is_24h' => true],
    ['name' => 'Bureau d Aide Juridictionnelle', 'type' => 'juridique', 'description' => 'Assistance juridique gratuite pour les personnes vulnerables', 'address' => 'Palais de Justice, Ouagadougou', 'region' => 'Centre', 'phone' => '25 30 62 20', 'hours' => '8h-15h30', 'is_free' => true],
    ['name' => 'Centre Social de Koudougou', 'type' => 'ong', 'description' => 'Prise en charge psychosociale des victimes de violences', 'address' => 'Koudougou Centre', 'region' => 'Centre-Ouest', 'phone' => '25 44 01 23', 'hours' => '8h-17h', 'is_free' => true],
    ['name' => 'Gendarmerie Brigade Kaya', 'type' => 'securite', 'description' => 'Unite specialisee dans les plaintes pour VBG', 'address' => 'Kaya', 'region' => 'Centre-Nord', 'phone' => '25 45 30 17', 'hours' => '24h/24', 'is_24h' => true],
    ['name' => 'ABBEF Ouahigouya', 'type' => 'ong', 'description' => 'Association burkinabe pour le bien-etre familial', 'address' => 'Ouahigouya', 'region' => 'Nord', 'phone' => '25 55 01 40', 'hours' => '8h-16h', 'is_free' => true],
    ['name' => 'CMA de Fada N Gourma', 'type' => 'medical', 'description' => 'Centre medical avec service de prise en charge des victimes', 'address' => 'Fada N Gourma', 'region' => 'Est', 'phone' => '25 77 01 18', 'hours' => '24h/24', 'is_24h' => true],
    ['name' => 'Tribunal de Grande Instance de Bobo', 'type' => 'juridique', 'description' => 'Juridiction competente pour les affaires de VBG', 'address' => 'Bobo-Dioulasso', 'region' => 'Hauts-Bassins', 'phone' => '20 97 04 15', 'hours' => '8h-15h'],
    ['name' => 'ONG Promo-Femmes', 'type' => 'ong', 'description' => 'Promotion des droits de la femme et accompagnement juridique', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 36 83 20', 'hours' => '8h-17h', 'is_free' => true],
];
$added = 0;
foreach ($newServices as $s) {
    if (!ServiceDirectory::where('name', $s['name'])->exists()) {
        ServiceDirectory::create($s);
        $added++;
    }
}
echo "Services added: $added, total: " . ServiceDirectory::count() . "\n";

// Additional resources
$newResources = [
    [
        'title' => 'Protocole de prise en charge des victimes de VBG',
        'description' => "Ce guide pratique est destiné aux agents de santé et détaille chaque étape de la prise en charge médico-psychosociale des victimes de VBG.\n\nÉtape 1 – Accueil et triage :\nRecevoir la victime dans un espace confidentiel, évaluer l'urgence médicale, assurer un accueil sans jugement. Prioriser la sécurité immédiate.\n\nÉtape 2 – Examen médical et certificat :\nRéaliser un examen clinique complet, documenter les lésions avec précision, délivrer un certificat médical conforme aux exigences légales. En cas de violence sexuelle, appliquer le protocole de prophylaxie (IST, VIH, grossesse non désirée) dans les 72 heures.\n\nÉtape 3 – Soutien psychologique immédiat :\nUtiliser les techniques de premiers secours psychologiques (PFA) : écoute active, stabilisation émotionnelle, information sur les réactions normales au traumatisme.\n\nÉtape 4 – Orientation et référencement :\nRéférer vers les services complémentaires : aide juridique, hébergement d'urgence, services sociaux. Utiliser les fiches de référencement standardisées.\n\nÉtape 5 – Suivi et documentation :\nProgrammer les consultations de suivi, renseigner le registre VBG, assurer la confidentialité des dossiers selon les normes éthiques.",
        'type' => 'guide',
        'category' => 'Professionnel',
        'duration' => '20 min de lecture',
        'tag' => 'Medical',
    ],
    [
        'title' => 'Code pénal : articles relatifs aux VBG',
        'description' => "Compilation annotée des articles du Code pénal burkinabè sanctionnant les violences basées sur le genre, avec explications accessibles.\n\n• Article 512 – Coups et blessures volontaires :\nTout acte de violence physique entraînant une incapacité de travail est puni de 1 à 5 ans d'emprisonnement. Si la victime est le conjoint, la peine est doublée.\n\n• Article 513 – Violences ayant entraîné la mort :\nPeine de 10 à 20 ans de réclusion criminelle lorsque les violences ont entraîné la mort sans intention de la donner.\n\n• Article 532 – Viol :\nLe viol est puni de 5 à 10 ans d'emprisonnement. La peine est portée de 11 à 20 ans si la victime est mineure ou si l'auteur a autorité sur elle.\n\n• Article 533 – Harcèlement sexuel :\nPuni de 1 à 3 ans d'emprisonnement et d'une amende. Aggravé en milieu professionnel ou scolaire.\n\n• Article 535-1 – Mutilations génitales féminines :\nPuni de 1 à 10 ans d'emprisonnement. Toute personne ayant connaissance de la pratique et ne la signalant pas est passible de sanctions.\n\n• Article 376 – Mariage forcé :\nLe mariage forcé est puni de 6 mois à 2 ans d'emprisonnement.\n\nCes dispositions constituent le socle pénal de la lutte contre les VBG au Burkina Faso.",
        'type' => 'loi',
        'category' => 'Juridique',
        'duration' => '10 min de lecture',
        'tag' => 'Reference',
    ],
    [
        'title' => 'Sécurité numérique pour les victimes',
        'description' => "Dans un contexte où les technologies sont utilisées comme outil de contrôle et de surveillance, ce guide pratique vous aide à protéger votre vie privée numérique.\n\n📱 Sécuriser votre téléphone :\n• Changez tous vos mots de passe régulièrement (utilisez des phrases longues et uniques)\n• Désactivez la géolocalisation dans les paramètres\n• Vérifiez les applications installées : supprimez celles que vous ne reconnaissez pas (logiciels espions)\n• Activez le verrouillage par code PIN ou empreinte digitale\n\n💻 Naviguer en toute sécurité :\n• Utilisez la navigation privée pour vos recherches sensibles\n• Effacez régulièrement l'historique de navigation et les cookies\n• Ne vous connectez pas à vos comptes personnels sur un appareil partagé\n• Utilisez un navigateur sécurisé comme Firefox ou Brave\n\n📧 Protéger vos communications :\n• Créez une adresse e-mail confidentielle que votre agresseur ne connaît pas\n• Utilisez des applications de messagerie chiffrées (Signal, WhatsApp)\n• Ne partagez jamais vos codes d'accès\n\n🚨 En cas de cyberviolence :\n• Faites des captures d'écran comme preuves avant suppression\n• Signalez le contenu aux plateformes concernées\n• Portez plainte auprès des autorités compétentes\n\nVotre sécurité numérique fait partie de votre sécurité globale.",
        'type' => 'guide',
        'category' => 'Securite',
        'duration' => '7 min de lecture',
        'tag' => 'Numerique',
    ],
    [
        'title' => 'Plan de sécurité personnalisé',
        'description' => "Un plan de sécurité est une stratégie personnalisée qui vous aide à vous protéger en cas de danger immédiat ou à préparer un départ en sécurité. Voici les éléments clés à préparer :\n\n🏠 Si vous vivez avec l'agresseur :\n• Identifiez les pièces de la maison avec une issue de secours (évitez la cuisine et la salle de bain)\n• Convenez d'un signal d'alerte avec un voisin ou un proche de confiance\n• Repérez les moments où partir est le plus sûr\n• Gardez votre téléphone chargé et accessible\n\n📋 Documents à préparer (originaux ou copies) :\n• Carte nationale d'identité / passeport\n• Acte de naissance (le vôtre et ceux de vos enfants)\n• Certificats médicaux attestant des violences\n• Livret de famille, acte de mariage\n• Justificatifs de revenus ou de propriété\n\n👜 Sac d'urgence à préparer en secret :\n• Vêtements de rechange, médicaments essentiels\n• Argent en espèces\n• Clé de secours, numéros de téléphone importants notés sur papier\n\n📞 Numéros d'urgence à mémoriser :\n• Ligne Verte MARA : 80 00 11 52\n• Police Secours : 17\n• SAMU : 112\n\n💡 Rappel : un plan de sécurité n'est pas un plan de fuite immédiat, c'est une préparation pour le jour où vous serez prête. Vous seule décidez du bon moment.",
        'type' => 'guide',
        'category' => 'Securite',
        'duration' => '15 min',
        'tag' => 'Essentiel',
    ],
    [
        'title' => 'Webinaire : Reconnaître les signes de violence conjugale',
        'description' => "Ce webinaire de 30 minutes, animé par des psychologues spécialisés en violences conjugales, vous apprend à identifier les schémas récurrents de la violence dans le couple.\n\nContenu du webinaire :\n\n1. Le cycle de la violence conjugale :\n• Phase de tension : irritabilité croissante, reproches, climat de peur\n• Phase d'agression : explosion verbale, physique ou sexuelle\n• Phase de réconciliation : excuses, promesses de changement, cadeaux\n• Phase d'accalmie : retour apparent à la normale avant un nouveau cycle\n\n2. Les signaux à repérer chez un proche :\n• Changement de comportement : retrait social, anxiété, justification des absences\n• Blessures fréquentes avec des explications peu convaincantes\n• Surveillance constante par le partenaire (appels, messages, présence physique)\n• Perte d'autonomie financière progressive\n\n3. Comment aborder le sujet :\n• Posez des questions ouvertes sans forcer la confidence\n• Exprimez votre préoccupation sans juger ni conseiller de partir immédiatement\n• Informez sur les ressources disponibles et respectez le rythme de la personne\n\nCe webinaire est suivi d'une session de questions-réponses avec les intervenants.",
        'type' => 'video',
        'category' => 'Formation',
        'duration' => '30 min',
    ],
    [
        'title' => "Les droits de l'enfant au Burkina Faso",
        'description' => "Les enfants burkinabè sont protégés par un ensemble d'instruments juridiques nationaux et internationaux. Cet article présente le cadre complet de protection de l'enfance.\n\nInstruments internationaux ratifiés par le Burkina Faso :\n• Convention relative aux droits de l'enfant (CDE, 1989) : ratifiée en 1990, elle garantit les droits fondamentaux de tout enfant de moins de 18 ans.\n• Charte africaine des droits et du bien-être de l'enfant (1990) : protection spécifique au contexte africain.\n• Protocole facultatif sur la vente d'enfants, la prostitution et la pornographie mettant en scène des enfants.\n\nLégislation nationale :\n• Code des personnes et de la famille : fixe l'âge minimum du mariage à 17 ans pour les filles et 20 ans pour les garçons.\n• Loi N°015-2014 portant protection de l'enfant : interdit les châtiments corporels, le travail des enfants de moins de 16 ans, et les pires formes de travail.\n• Code pénal : sanctions renforcées pour les infractions commises sur des mineurs (violences, abus sexuels, abandon).\n\nStructures de protection :\n• Direction de la Protection de l'Enfance et de l'Adolescence (DPEA)\n• Comités villageois de protection de l'enfant\n• Ligne d'écoute pour enfants en danger\n\nTout enfant victime de violence a le droit d'être entendu, protégé et accompagné.",
        'type' => 'article',
        'category' => 'Juridique',
        'duration' => '6 min de lecture',
    ],
    [
        'title' => 'Statistiques VBG au Burkina Faso 2025',
        'description' => "Cette infographie présente les données clés sur les violences basées sur le genre au Burkina Faso, issues des enquêtes nationales et des rapports des organisations internationales.\n\n📊 Chiffres clés :\n• 1 femme sur 3 a subi au moins une forme de violence physique ou sexuelle au cours de sa vie (source : INSD)\n• 52% des femmes mariées déclarent avoir subi des violences conjugales\n• Le mariage précoce touche 52% des filles avant 18 ans et 10% avant 15 ans\n• 76% des cas de VBG ne sont jamais signalés aux autorités\n• Les mutilations génitales féminines (MGF) concernent encore 67% des femmes de 15-49 ans\n\n📈 Évolution et progrès :\n• Augmentation de 35% des signalements entre 2020 et 2025 (signe d'une libération progressive de la parole)\n• 12 nouveaux centres d'écoute ouverts dans les régions rurales depuis 2023\n• 85% des plaintes déposées aboutissent à une enquête judiciaire (contre 45% en 2018)\n\n🗺️ Répartition régionale :\n• Régions les plus touchées : Centre, Hauts-Bassins, Boucle du Mouhoun\n• Zones de conflit : augmentation des violences sexuelles liées aux déplacements\n\nCes données soulignent l'urgence de renforcer les mécanismes de prévention et de prise en charge sur l'ensemble du territoire.",
        'type' => 'infographie',
        'category' => 'Donnees',
        'duration' => '4 min',
    ],
    [
        'title' => 'Formation : Accompagnement psychologique des survivantes',
        'description' => "Ce module de formation approfondi est conçu pour les professionnels de santé mentale et les travailleurs sociaux impliqués dans l'accompagnement des survivantes de VBG.\n\nPartie 1 – Comprendre le traumatisme (30 min) :\n• Le stress post-traumatique (ESPT) : symptômes, diagnostic, facteurs de risque\n• Les réactions normales au traumatisme : flashbacks, hypervigilance, évitement, dissociation\n• Impact spécifique des violences répétées : le traumatisme complexe\n• Conséquences sur la santé physique : douleurs chroniques, troubles digestifs, fatigue\n\nPartie 2 – Techniques d'intervention (30 min) :\n• Premiers secours psychologiques (PFA) : stabilisation, normalisation, orientation\n• Thérapie cognitivo-comportementale adaptée au trauma (TCC-T)\n• EMDR (Eye Movement Desensitization and Reprocessing) : principes et application\n• Techniques de grounding et de régulation émotionnelle\n• Groupes de parole : mise en place et animation\n\nPartie 3 – Prendre soin du soignant (30 min) :\n• Le traumatisme vicariant : quand la souffrance des victimes affecte les professionnels\n• Signes d'épuisement professionnel et de fatigue compassionnelle\n• Stratégies d'auto-soin : supervision, débriefing entre pairs, équilibre vie professionnelle/personnelle\n• Ressources de soutien pour les professionnels au Burkina Faso\n\nUne attestation de formation est délivrée aux participants ayant complété les trois modules.",
        'type' => 'formation',
        'category' => 'Professionnel',
        'duration' => '1h30',
    ],
    [
        'title' => 'Comment aider une proche victime de violence',
        'description' => "Quand une personne que vous aimez est victime de violence, savoir comment réagir peut faire toute la différence. Ce guide vous accompagne étape par étape.\n\n🤝 Écouter sans juger :\n• Croyez-la : ne remettez jamais en question sa parole. Les fausses déclarations de VBG sont extrêmement rares.\n• Ne dites jamais : « Pourquoi tu ne le quittes pas ? ». Quitter une situation de violence est un processus complexe et dangereux.\n• Laissez-la parler à son rythme, sans l'interrompre ni poser de questions intrusives.\n\n💬 Que dire :\n• « Je te crois. »\n• « Ce n'est pas ta faute. »\n• « Tu ne mérites pas ça. »\n• « Je suis là pour toi, quoi que tu décides. »\n\n⚠️ Ce qu'il faut éviter :\n• N'allez jamais confronter l'agresseur directement – cela pourrait mettre la victime en danger.\n• Ne prenez pas de décisions à sa place – respectez son autonomie.\n• Ne parlez pas de sa situation à d'autres sans son accord.\n\n📞 Orienter vers les ressources :\n• Proposez (sans imposer) les numéros d'aide : Ligne Verte MARA (80 00 11 52)\n• Accompagnez-la dans ses démarches si elle le souhaite (plainte, hébergement, soin)\n• Informez-vous sur les structures d'aide de votre région via l'annuaire MARA\n\n🔄 Être patient(e) :\nLe chemin vers la sortie de la violence est long et non linéaire. Votre soutien constant, même silencieux, est précieux.",
        'type' => 'article',
        'category' => 'Comprendre',
        'duration' => '5 min de lecture',
        'tag' => 'Essentiel',
    ],
    [
        'title' => 'Décret sur la protection des victimes',
        'description' => "Ce décret portant création et fonctionnement du Fonds national d'indemnisation des victimes de violences constitue un mécanisme essentiel de réparation.\n\nObjectifs du Fonds :\n• Garantir une indemnisation rapide des victimes de VBG, indépendamment de l'issue de la procédure judiciaire\n• Couvrir les frais médicaux, psychologiques et de réinsertion sociale\n• Assurer une prise en charge d'urgence pour les victimes sans ressources\n\nConditions d'éligibilité :\n• Être victime de violences basées sur le genre sur le territoire burkinabè\n• Avoir déposé une plainte ou fait un signalement auprès des autorités compétentes\n• Fournir un certificat médical ou tout document attestant de la violence subie\n\nProcédure de demande :\n1. Déposer un dossier auprès du secrétariat du Fonds (formulaire disponible dans les services sociaux et les juridictions)\n2. Le dossier est examiné par une commission composée de magistrats, travailleurs sociaux et représentants d'ONG\n3. La décision est rendue dans un délai maximum de 30 jours\n4. L'indemnisation est versée directement à la victime ou aux prestataires de soins\n\nMontants indicatifs :\n• Prise en charge médicale : jusqu'à 500 000 FCFA\n• Soutien psychologique : jusqu'à 200 000 FCFA\n• Aide à la réinsertion : jusqu'à 1 000 000 FCFA\n• Préjudice moral : évalué au cas par cas\n\nCe fonds représente une avancée majeure dans la prise en charge globale des victimes au Burkina Faso.",
        'type' => 'loi',
        'category' => 'Juridique',
        'duration' => '8 min de lecture',
    ],
];
$added = 0;
foreach ($newResources as $r) {
    if (!Resource::where('title', $r['title'])->exists()) {
        Resource::create($r);
        $added++;
    }
}
echo "Resources added: $added, total: " . Resource::count() . "\n";
