<?php

namespace Database\Seeders;

use App\Models\Resource;
use App\Models\ServiceDirectory;
use App\Models\SosNumber;
use App\Models\User;
use App\Models\ViolenceType;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // Admin user
        User::create([
            'name' => 'Admin MARA',
            'email' => 'admin@mara.bf',
            'password' => Hash::make('password'),
            'role' => 'admin',
        ]);

        // Professionnels
        User::create([
            'name' => 'Dr. Aminata Ouédraogo',
            'email' => 'aminata@mara.bf',
            'password' => Hash::make('password'),
            'role' => 'professionnel',
            'titre' => 'Dr.',
            'specialite' => 'Psychologue',
            'organisation' => 'CHU Yalgado',
            'is_online' => true,
        ]);

        User::create([
            'name' => 'Me. Fatou Compaoré',
            'email' => 'fatou@mara.bf',
            'password' => Hash::make('password'),
            'role' => 'professionnel',
            'titre' => 'Me.',
            'specialite' => 'Juriste',
            'organisation' => 'Association Droits des Femmes',
            'is_online' => true,
        ]);

        User::create([
            'name' => 'Mariam Sawadogo',
            'email' => 'mariam@mara.bf',
            'password' => Hash::make('password'),
            'role' => 'conseiller',
            'specialite' => 'Assistante sociale',
            'organisation' => 'MARA',
            'is_online' => true,
        ]);

        // Types de violence
        $violenceTypes = [
            ['slug' => 'physique', 'label_fr' => 'Violence physique', 'icon' => 'hand-fist'],
            ['slug' => 'sexuelle', 'label_fr' => 'Violence sexuelle', 'icon' => 'alert-triangle'],
            ['slug' => 'psychologique', 'label_fr' => 'Violence psychologique', 'icon' => 'brain'],
            ['slug' => 'economique', 'label_fr' => 'Violence économique', 'icon' => 'wallet'],
            ['slug' => 'verbale', 'label_fr' => 'Violence verbale', 'icon' => 'megaphone'],
            ['slug' => 'numerique', 'label_fr' => 'Cyberviolence', 'icon' => 'smartphone'],
            ['slug' => 'negligence', 'label_fr' => 'Négligence', 'icon' => 'shield-off'],
            ['slug' => 'mariage_force', 'label_fr' => 'Mariage forcé', 'icon' => 'lock'],
            ['slug' => 'mutilation', 'label_fr' => 'Mutilation génitale', 'icon' => 'scissors'],
            ['slug' => 'traite', 'label_fr' => 'Traite des personnes', 'icon' => 'link-2'],
        ];
        foreach ($violenceTypes as $vt) {
            ViolenceType::create($vt);
        }

        // Numéros SOS
        $sosNumbers = [
            ['label' => 'Ligne Verte MARA', 'description' => 'Assistance 24h/24', 'number' => '80 00 11 52', 'icon' => 'phone-call', 'sort_order' => 1],
            ['label' => 'Police Secours', 'description' => 'Urgences sécuritaires', 'number' => '17', 'icon' => 'shield-alert', 'sort_order' => 2],
            ['label' => 'SAMU', 'description' => 'Urgences médicales', 'number' => '112', 'icon' => 'ambulance', 'sort_order' => 3],
            ['label' => 'Pompiers', 'description' => "Secours d'urgence", 'number' => '18', 'icon' => 'flame', 'sort_order' => 4],
            ['label' => 'Action Sociale', 'description' => 'Assistance sociale', 'number' => '80 00 11 30', 'icon' => 'hand-helping', 'sort_order' => 5],
        ];
        foreach ($sosNumbers as $sos) {
            SosNumber::create($sos);
        }

        // Service directories
        $services = [
            ['name' => 'Commissariat Central', 'type' => 'securite', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 30 69 15', 'hours' => '24h/24', 'is_24h' => true],
            ['name' => 'Association Voix de Femmes', 'type' => 'ong', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 36 40 40', 'hours' => '8h-17h', 'is_free' => true],
            ['name' => 'CHU Yalgado Ouédraogo', 'type' => 'medical', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 30 66 41', 'hours' => '24h/24', 'is_24h' => true],
            ['name' => 'Tribunal de Grande Instance', 'type' => 'juridique', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 30 62 15', 'hours' => '8h-15h'],
            ['name' => 'SOS Violences Femmes', 'type' => 'urgence', 'address' => 'Bobo-Dioulasso', 'region' => 'Hauts-Bassins', 'phone' => '20 97 10 00', 'hours' => '24h/24', 'is_24h' => true, 'is_free' => true],
            ['name' => 'Ministère de la Femme', 'type' => 'institutionnel', 'address' => 'Ouagadougou', 'region' => 'Centre', 'phone' => '25 32 67 89', 'hours' => '8h-16h'],
        ];
        foreach ($services as $s) {
            ServiceDirectory::create($s);
        }

        // Resources
        $resources = [
            [
                'title' => 'Comprendre les violences basées sur le genre',
                'description' => "Les violences basées sur le genre (VBG) englobent tout acte nuisible perpétré contre la volonté d'une personne en raison de son genre. Ce guide détaillé vous aide à identifier les différentes formes de violence :\n\n• Violence physique : coups, brûlures, bousculades, séquestration, privation de nourriture ou de soins.\n• Violence sexuelle : viol, attouchements forcés, harcèlement sexuel, mariage forcé, mutilations génitales féminines.\n• Violence psychologique : humiliations répétées, menaces, isolement social, chantage affectif, contrôle permanent.\n• Violence économique : confiscation des revenus, interdiction de travailler, contrôle financier abusif.\n• Cyberviolence : harcèlement en ligne, diffusion non consentie d'images intimes, surveillance numérique.\n\nChaque forme de violence laisse des séquelles profondes. Savoir les reconnaître est le premier pas vers la protection et l'accompagnement des victimes. Si vous ou une personne de votre entourage êtes concernée, n'hésitez pas à contacter les services d'aide disponibles sur MARA.",
                'type' => 'guide',
                'category' => 'Comprendre',
                'duration' => '12 min de lecture',
                'tag' => 'Essentiel',
            ],
            [
                'title' => 'Vos droits en tant que victime',
                'description' => "Au Burkina Faso, les victimes de violences basées sur le genre bénéficient de protections légales importantes. Voici ce que vous devez savoir :\n\n• Droit de porter plainte : toute victime peut déposer une plainte auprès de la police, de la gendarmerie ou directement au tribunal. Le dépôt de plainte est gratuit.\n• Protection judiciaire : le juge peut ordonner des mesures de protection immédiate, notamment l'éloignement de l'agresseur du domicile conjugal et l'interdiction de contact.\n• Aide juridictionnelle : les personnes sans ressources peuvent bénéficier d'un avocat commis d'office gratuitement.\n• Certificat médical : il est essentiel de faire constater les blessures par un médecin. Ce document constitue une preuve fondamentale devant le tribunal.\n• Confidentialité : les procédures liées aux VBG sont confidentielles pour protéger la dignité de la victime.\n• Indemnisation : la loi prévoit la réparation du préjudice subi, incluant les frais médicaux, le préjudice moral et les pertes de revenus.\n\nVous n'êtes pas seule. Les associations partenaires de MARA peuvent vous accompagner gratuitement dans toutes vos démarches juridiques.",
                'type' => 'article',
                'category' => 'Juridique',
                'duration' => '8 min de lecture',
                'tag' => 'Juridique',
            ],
            [
                'title' => 'Loi N°061-2015 sur les VBG',
                'description' => "La loi N°061-2015/CNT du 6 septembre 2015 portant prévention, répression et réparation des violences à l'égard des femmes et des filles constitue le cadre juridique principal de lutte contre les VBG au Burkina Faso.\n\nPoints clés de la loi :\n\n• Définition élargie des VBG : la loi couvre les violences physiques, sexuelles, psychologiques, économiques et patrimoniales.\n• Sanctions renforcées : les peines vont de 1 à 5 ans d'emprisonnement pour les violences physiques, et de 5 à 10 ans pour les violences sexuelles. Les circonstances aggravantes (lien conjugal, minorité de la victime) alourdissent les peines.\n• Mesures de protection : le juge peut prendre des ordonnances de protection en urgence dans un délai de 24 à 72 heures.\n• Prise en charge médicale gratuite : les frais de soins médicaux des victimes sont à la charge de l'État.\n• Interdiction de la médiation pénale : les infractions de VBG ne peuvent pas faire l'objet de règlement à l'amiable.\n• Fonds d'indemnisation : création d'un fonds national pour la réparation des victimes.\n\nCette loi marque un tournant décisif dans la protection des droits des femmes et des filles au Burkina Faso.",
                'type' => 'loi',
                'category' => 'Juridique',
                'duration' => '15 min de lecture',
            ],
            [
                'title' => 'Comment accompagner une victime',
                'description' => "Cette formation destinée aux professionnels (travailleurs sociaux, agents de santé, forces de l'ordre, juristes) couvre les fondamentaux de la prise en charge des victimes de VBG.\n\nModule 1 – L'écoute active et bienveillante :\nApprenez à accueillir la parole de la victime sans jugement, à créer un espace de confiance et à respecter son rythme. L'écoute est la première forme d'aide.\n\nModule 2 – Évaluation de la situation et des risques :\nIdentifiez le niveau de danger immédiat, les besoins prioritaires (médicaux, sécuritaires, juridiques) et les facteurs de vulnérabilité.\n\nModule 3 – Orientation vers les services compétents :\nMaîtrisez le réseau de prise en charge : services médicaux, aide juridique, hébergement d'urgence, soutien psychologique. Sachez quand et comment référer.\n\nModule 4 – Accompagnement dans la durée :\nSuivi post-crise, soutien à la reconstruction, prévention de la revictimisation. Techniques de gestion du stress pour les professionnels.\n\nModule 5 – Cadre éthique et déontologique :\nRespect de la confidentialité, consentement éclairé, principe de non-discrimination et approche centrée sur la survivante.",
                'type' => 'formation',
                'category' => 'Professionnel',
                'duration' => '45 min',
            ],
            [
                'title' => 'Témoignage : Briser le silence',
                'description' => "Dans cette vidéo poignante, trois survivantes de violences basées sur le genre au Burkina Faso partagent avec courage leur parcours de résilience.\n\nAïssata, 28 ans, raconte comment elle a trouvé la force de quitter une relation abusive après des années de violence conjugale, grâce au soutien d'une association locale.\n\nFatima, 35 ans, mère de quatre enfants, témoigne de son combat pour retrouver son indépendance économique après avoir été privée de ses revenus pendant 10 ans.\n\nMariame, 22 ans, étudiante, explique comment elle a porté plainte pour harcèlement sexuel et les étapes de la procédure judiciaire qui ont abouti à la condamnation de son agresseur.\n\nCes témoignages rappellent que briser le silence est un acte de courage, mais jamais un acte solitaire. Chaque survivante souligne l'importance de l'entourage, des services d'aide et de la solidarité communautaire dans leur reconstruction.\n\n⚠️ Si vous êtes en situation de violence, vous n'êtes pas seule. Appelez la Ligne Verte MARA : 80 00 11 52.",
                'type' => 'video',
                'category' => 'Témoignages',
                'duration' => '5 min',
            ],
            [
                'title' => 'Les signes de violence psychologique',
                'description' => "La violence psychologique est souvent invisible mais ses conséquences sont profondes et durables. Cette infographie illustrée vous aide à repérer les signaux d'alerte :\n\n🔴 Signes chez la victime :\n• Perte de confiance en soi, sentiment permanent de culpabilité\n• Isolement progressif : rupture avec la famille, les amis, le travail\n• Anxiété chronique, troubles du sommeil, état dépressif\n• Comportement de soumission, peur constante du partenaire\n• Difficulté à prendre la moindre décision seule\n\n🔴 Comportements de l'agresseur :\n• Humiliations répétées en privé ou en public\n• Critiques systématiques, dénigrement, moqueries blessantes\n• Contrôle permanent des déplacements, des communications, de l'habillement\n• Menaces voilées ou directes envers la victime ou ses proches\n• Alternance entre phases de tendresse et phases de terreur (cycle de la violence)\n• Inversion des rôles : l'agresseur se pose en victime\n\n💡 Que faire ? Parlez-en à une personne de confiance. La violence psychologique est punie par la loi au Burkina Faso. Les services de MARA sont là pour vous écouter et vous orienter.",
                'type' => 'infographie',
                'category' => 'Comprendre',
                'duration' => '3 min',
            ],
        ];
        foreach ($resources as $r) {
            Resource::create($r);
        }
    }
}
