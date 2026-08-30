<?php

namespace Database\Seeders;

use App\Models\AuditLog;
use App\Models\Category;
use App\Models\Claim;
use App\Models\ClaimAnswer;
use App\Models\CmsPage;
use App\Models\Conversation;
use App\Models\Hub;
use App\Models\ItemReport;
use App\Models\MatchCandidate;
use App\Models\MediaAsset;
use App\Models\Message;
use App\Models\Organization;
use App\Models\QrTag;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class KenyaDemoSeeder extends Seeder
{
    public function run(): void
    {
        $org = Organization::query()->firstOrCreate(
            ['slug' => 'reunite-network'],
            ['name' => 'Reunite Network'],
        );

        $admin = $this->user('Super Admin', 'admin@reunite.test', 'super_admin', 'Nairobi', '+254700000001');
        $owner = $this->user('Amina Owner', 'owner@reunite.test', 'user', 'Nairobi', '+254700000002');
        $finder = $this->user('Brian Finder', 'finder@reunite.test', 'user', 'Nairobi', '+254700000003');
        $hubUser = $this->user('Hub Desk', 'hub@reunite.test', 'hub_staff', 'Nairobi', '+254700000004');
        $hubUser->assignRole('user');
        $staffAlias = $this->user('Amina Staff', 'staff@reunite.test', 'hub_staff', 'Nairobi', '+254700000005');
        $staffAlias->assignRole('user');

        $wanjiku = $this->user('Wanjiku Mwangi', 'wanjiku@reunite.test', 'user', 'Westlands', '+254711000101');
        $otieno = $this->user('Otieno Okoth', 'otieno@reunite.test', 'user', 'Kisumu', '+254722000202');
        $fatuma = $this->user('Fatuma Ali', 'fatuma@reunite.test', 'user', 'Mombasa', '+254733000303');
        $kipchoge = $this->user('Daniel Kipchoge', 'kipchoge@reunite.test', 'user', 'Eldoret', '+254744000404');
        $hassan = $this->user('Hassan Juma', 'hassan@reunite.test', 'user', 'Nakuru', '+254755000505');
        $mercy = $this->user('Mercy Atieno', 'mercy@reunite.test', 'user', 'Thika', '+254766000606');
        $kamau = $this->user('Peter Kamau', 'kamau@reunite.test', 'user', 'Kilimani', '+254777000707');
        $aisha = $this->user('Aisha Mohamed', 'aisha@reunite.test', 'user', 'Nyali', '+254788000808');

        $categories = $this->categories();
        $hubs = $this->hubs($org, $hubUser);
        $hubs['tworivers']->staff()->syncWithoutDetaching([$staffAlias->id => ['role' => 'hub_staff']]);
        $hubs['mall']->staff()->syncWithoutDetaching([$staffAlias->id => ['role' => 'hub_staff']]);

        $people = compact('owner', 'finder', 'hubUser', 'wanjiku', 'otieno', 'fatuma', 'kipchoge', 'hassan', 'mercy', 'kamau', 'aisha');
        $reports = $this->reports($people, $categories, $hubs);
        $this->matchesAndClaims($owner, $finder, $reports);
        $this->cms();
        $this->settings();
        $this->tags($owner, $finder, $wanjiku);
        $this->audit($admin, $reports[0] ?? null);
    }

    private function user(string $name, string $email, string $role, string $city, string $phone): User
    {
        $user = User::query()->firstOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'display_name' => explode(' ', $name)[0],
                'password' => 'password',
                'phone' => $phone,
                'phone_verified_at' => now(),
                'email_verified_at' => now(),
                'city' => $city,
                'status' => 'active',
                'verification_level' => $role === 'super_admin' ? 4 : 3,
                'trust_score' => 70,
                'reputation_points' => 15,
                'locale' => 'en',
                'id_verification_status' => $role === 'super_admin' ? 'verified' : 'none',
            ],
        );
        $user->assignRole($role);

        return $user;
    }

    /**
     * @return array<string, Category>
     */
    private function categories(): array
    {
        $defs = [
            ['documents-ids', 'Documents & IDs', 'highly_sensitive', 'Hide document numbers and faces.', 30, 'badge'],
            ['wallets-bags', 'Wallets & bags', 'restricted', 'Show the outside only.', 90, 'account_balance_wallet'],
            ['phones-tablets', 'Phones & tablets', 'restricted', 'Do not show lock-screen photos of people.', 90, 'smartphone'],
            ['computers', 'Computers & accessories', 'restricted', 'Avoid serial stickers in public photos.', 90, 'laptop'],
            ['keys', 'Keys', 'public', 'Show the key shape, hide address tags.', 60, 'vpn_key'],
            ['jewelry', 'Jewelry & watches', 'restricted', 'Avoid unique engravings in public teasers.', 120, 'diamond'],
            ['clothing', 'Clothing & uniforms', 'public', 'Show color and logo, hide name tapes if needed.', 45, 'checkroom'],
            ['eyewear', 'Eyewear', 'public', 'Front and side photos help.', 60, 'visibility'],
            ['cards', 'Cards', 'highly_sensitive', 'Never photograph the full card number.', 14, 'credit_card'],
            ['pets', 'Pets & pet items', 'public', 'Include collar color, hide microchip number.', 30, 'pets'],
            ['vehicles', 'Vehicles & plates', 'highly_sensitive', 'Plate photos are admin-only.', 30, 'directions_car'],
            ['earphones-audio', 'Earphones & audio', 'public', 'Show the case color, hide engravings.', 60, 'headphones'],
            ['sports-gear', 'Sports gear', 'public', 'Show the item, hide name tape if needed.', 60, 'sports_tennis'],
            ['books-stationery', 'Books & stationery', 'public', 'Cover can be public. Hide personal notes.', 45, 'menu_book'],
            ['other', 'Other', 'public', 'Avoid identifying documents in frame.', 60, 'category'],
        ];

        $out = [];
        foreach ($defs as $i => [$slug, $name, $sensitivity, $guide, $days, $icon]) {
            $out[$slug] = Category::query()->firstOrCreate(
                ['slug' => $slug],
                [
                    'name' => $name,
                    'sensitivity' => $sensitivity,
                    'photo_guidance' => $guide,
                    'retention_days' => $days,
                    'sort_order' => $i + 1,
                    'schema_json' => ['fields' => ['color', 'brand'], 'icon' => $icon],
                ],
            );
            if ($out[$slug]->categoryAttributes()->count() === 0) {
                $out[$slug]->categoryAttributes()->createMany([
                    ['key' => 'color', 'label' => 'Color', 'type' => 'color', 'visibility' => 'public', 'required' => true, 'sort_order' => 1],
                    ['key' => 'brand', 'label' => 'Brand', 'type' => 'text', 'visibility' => 'public', 'required' => false, 'sort_order' => 2],
                    ['key' => 'mark', 'label' => 'Hidden mark', 'type' => 'text', 'visibility' => 'hidden_challenge', 'required' => false, 'sort_order' => 3],
                ]);
            }
        }

        return $out;
    }

    /**
     * @return array<string, Hub>
     */
    private function hubs(Organization $org, User $staff): array
    {
        $defs = [
            'mall' => ['City Mall Desk', 'mall', 'City Mall, Level 2, Nairobi', -1.2921, 36.8219],
            'campus' => ['Campus Security', 'campus', 'University Way, Nairobi', -1.2800, 36.8160],
            'station' => ['Central Station Lost Property', 'station', 'Haile Selassie Ave, Nairobi', -1.2928, 36.8280],
            'tworivers' => ['Two Rivers Hub', 'mall', 'Two Rivers Mall, Ruaka, Nairobi', -1.2200, 36.8000],
            'jkia' => ['JKIA Lost & Found', 'airport', 'Jomo Kenyatta International Airport, Nairobi', -1.3192, 36.9278],
            'sgr' => ['SGR Nairobi Terminus', 'station', 'Syokimau, Nairobi', -1.3210, 36.8950],
            'trm' => ['Thika Road Mall Desk', 'mall', 'Thika Road Mall, Roysambu', -1.2195, 36.8880],
            'nyali' => ['Nyali Centre Desk', 'mall', 'Nyali Centre, Mombasa', -4.0200, 39.7250],
            'kisumu' => ['Mega Plaza Kisumu', 'mall', 'Oginga Odinga Street, Kisumu', -0.1020, 34.7515],
            'nakuru' => ['Westside Mall Nakuru', 'mall', 'Kenyatta Avenue, Nakuru', -0.3031, 36.0800],
            'eldoret' => ['Zion Mall Eldoret', 'mall', 'Uganda Road, Eldoret', 0.5143, 35.2698],
        ];

        $hubs = [];
        foreach ($defs as $key => [$name, $type, $address, $lat, $lng]) {
            $hub = Hub::query()->firstOrCreate(
                ['name' => $name],
                [
                    'organization_id' => $org->id,
                    'type' => $type,
                    'address' => $address,
                    'lat' => $lat,
                    'lng' => $lng,
                    'hours_json' => ['mon_fri' => '08:00-20:00', 'sat' => '09:00-18:00', 'sun' => '10:00-16:00'],
                    'is_public' => true,
                    'retention_days' => 45,
                    'capacity' => 120,
                    'contact_internal' => 'desk@'.$key.'.reunite.test',
                ],
            );
            if ($hub->storageLocations()->count() === 0) {
                $hub->storageLocations()->createMany([
                    ['code' => strtoupper(substr($key, 0, 1)).'-A1', 'name' => 'Shelf A1'],
                    ['code' => strtoupper(substr($key, 0, 1)).'-B2', 'name' => 'Cage B2'],
                ]);
            }
            $hub->staff()->syncWithoutDetaching([$staff->id => ['role' => 'hub_staff']]);
            $hubs[$key] = $hub;
        }

        return $hubs;
    }

    /**
     * @param  array<string, User>  $people
     * @param  array<string, Category>  $categories
     * @param  array<string, Hub>  $hubs
     * @return array<string, ItemReport>
     */
    private function reports(array $people, array $categories, array $hubs): array
    {
        $rows = [
            ['wallet-lost', 'lost', 'owner', 'Black leather wallet', 'wallets-bags', 'Leather bi-fold last seen at City Mall. Public teaser only.', 'initials JK inside', 'WL-9911', 'black', 'Fossil', 'City Mall, Nairobi', 'Nairobi CBD', -1.2921, 36.8219, 'published', null, null, 'wallet.jpg', 'photo-1627123424574-724758594e93', '0F4C5C'],
            ['wallet-found', 'found', 'finder', 'Black wallet at food court', 'wallets-bags', 'Found near the escalator and taken to the mall desk.', 'JK stamped on lining', 'WL-9911', 'black', 'Fossil', 'City Mall food court, Nairobi', 'Nairobi CBD', -1.2920, 36.8217, 'published', 'mall', 'M-A1', 'wallet.jpg', 'photo-1627123424574-724758594e93', '0F4C5C'],
            ['keys-lost', 'lost', 'owner', 'Blue house keys', 'keys', 'Set of three keys on a blue ring, dropped on University Way.', 'elephant charm', null, 'blue', null, 'University Way, Nairobi', 'Nairobi CBD', -1.2801, 36.8162, 'published', null, null, 'keys.jpg', 'photo-1582139329536-4662235d8137', '0F4C5C'],
            ['keys-found', 'found', 'hubUser', 'Keys with blue ring', 'keys', 'Handed in at campus security this morning.', 'elephant charm', null, 'blue', null, 'Campus gate, University of Nairobi', 'Nairobi CBD', -1.2800, 36.8160, 'published', 'campus', 'C-A1', 'keys.jpg', 'photo-1582139329536-4662235d8137', '0F4C5C'],
            ['glasses-lost', 'lost', 'owner', 'Silver glasses case', 'eyewear', 'Hard case, slightly scuffed, left on a matatu seat.', 'scratch on hinge', null, 'silver', 'Ray-Ban', 'Central Station, Nairobi', 'Nairobi CBD', -1.2928, 36.8280, 'published', null, null, 'glasses.jpg', 'photo-1574258495973-f010dfbb5371', 'C45C42'],
            ['glasses-found', 'found', 'finder', 'Eyeglasses case', 'eyewear', 'Left on a bench at platform 2.', 'scratch on hinge', null, 'silver', 'Ray-Ban', 'Station platform 2, Nairobi', 'Nairobi CBD', -1.2927, 36.8278, 'published', 'station', 'S-A1', 'glasses.jpg', 'photo-1574258495973-f010dfbb5371', 'C45C42'],
            ['id-pouch', 'lost', 'owner', 'National ID pouch', 'documents-ids', 'Small navy pouch. Number stays private.', 'do not publish ID number', 'ID-HIDDEN', 'navy', null, 'City Mall, Nairobi', 'Nairobi CBD', -1.2921, 36.8219, 'under_review', null, null, 'pouch.jpg', 'photo-1590874103328-eac38a683ce7', '0A3540'],
            ['umbrella', 'found', 'hubUser', 'Black compact umbrella', 'other', 'Left at the campus library entrance.', 'yellow stitch repair', null, 'black', null, 'Campus library, Nairobi', 'Nairobi CBD', -1.2795, 36.8155, 'published', 'campus', 'C-B2', 'umbrella.jpg', 'photo-1507679799987-c73779587ccf', '0F4C5C'],
            ['backpack-lost', 'lost', 'wanjiku', 'Red daypack', 'wallets-bags', 'Daypack with a small patch, last seen on Haile Selassie.', 'inside name tape WANJIKU', null, 'red', 'Eastpak', 'Haile Selassie Ave, Nairobi', 'Nairobi CBD', -1.2930, 36.8285, 'published', null, null, 'backpack.jpg', 'photo-1553062407-98eeb64c6a62', 'E36414'],
            ['phone-found', 'found', 'finder', 'Phone in black case', 'phones-tablets', 'Android, screen off. At the City Mall desk.', 'sticker of a cat', 'SN-PHONE-1', 'black', 'Samsung', 'City Mall, Nairobi', 'Nairobi CBD', -1.2922, 36.8220, 'published', 'mall', 'M-B2', 'phone.jpg', 'photo-1511707171634-5f897ff02aa9', '0F4C5C'],
            ['watch-lost', 'lost', 'kamau', 'Silver wristwatch', 'jewelry', 'Lost around Yaya Centre after lunch.', 'tiny scratch on the clasp', null, 'silver', 'Casio', 'Yaya Centre, Kilimani', 'Kilimani', -1.2920, 36.7870, 'published', null, null, 'watch.jpg', 'photo-1523275335684-37898b6baf30', '0F4C5C'],
            ['headphones-found', 'found', 'wanjiku', 'White earbud case', 'earphones-audio', 'Found on a seat at Two Rivers food court.', 'faded W on the lid', null, 'white', 'Sony', 'Two Rivers Mall, Ruaka', 'Ruaka', -1.2200, 36.8000, 'published', 'tworivers', 'T-A1', 'earbuds.jpg', 'photo-1505740420928-5e560c06d30e', 'E8E2D6'],
            ['laptop-lost', 'lost', 'kamau', 'Grey laptop sleeve', 'computers', 'Sleeve only — machine was not inside. Left in a Bolt.', 'blue zipper pull', 'SLEEVE-09', 'grey', 'Incase', 'Westlands Roundabout, Nairobi', 'Westlands', -1.2683, 36.8110, 'published', null, null, 'laptop.jpg', 'photo-1496181133206-80ce9b88a853', '6B7280'],
            ['jacket-found', 'found', 'hubUser', 'Navy rain jacket', 'clothing', 'Handed in at JKIA arrivals.', 'torn inner pocket', null, 'navy', 'Columbia', 'JKIA Terminal 1A, Nairobi', 'JKIA', -1.3192, 36.9278, 'published', 'jkia', 'J-A1', 'jacket.jpg', 'photo-1591047139829-d91aecb6caea', '0F4C5C'],
            ['kiondo-lost', 'lost', 'mercy', 'Sisal kiondo bag', 'wallets-bags', 'Brown sisal bag with leather handles, last seen at TRM.', 'green bead on the handle', null, 'brown', null, 'Thika Road Mall, Roysambu', 'Roysambu', -1.2195, 36.8880, 'published', null, null, 'kiondo.jpg', 'photo-1590874103328-eac38a683ce7', 'BC6C25'],
            ['bottle-found', 'found', 'hassan', 'Green water bottle', 'other', 'Left at Westside Mall after a matatu ride.', 'dent near the base', null, 'green', 'Nalgene', 'Westside Mall, Nakuru', 'Nakuru', -0.3031, 36.0800, 'published', 'nakuru', 'N-A1', 'bottle.jpg', 'photo-1602143407151-011e70d1c4e4', '2D6A4F'],
            ['sneakers-lost', 'lost', 'kipchoge', 'White running shoes', 'sports-gear', 'Left in a gym bag outside Zion Mall.', 'orange lace tips', null, 'white', 'Saucony', 'Zion Mall, Eldoret', 'Eldoret', 0.5143, 35.2698, 'published', null, null, 'shoes.jpg', 'photo-1542291026-7eec264c27ff', 'F7F4EF'],
            ['book-found', 'found', 'otieno', 'Swahili novel', 'books-stationery', 'Paperback left on a bench at Mega Plaza.', 'bus ticket used as bookmark', null, 'yellow', null, 'Mega Plaza, Kisumu', 'Kisumu', -0.1020, 34.7515, 'published', 'kisumu', 'K-A1', 'book.jpg', 'photo-1456735190827-d1262f71b8a1', 'E36414'],
            ['leso-lost', 'lost', 'fatuma', 'Kanga wrap', 'clothing', 'Red and black kanga last seen near Nyali Centre.', 'family motto on the border', null, 'red', null, 'Nyali Centre, Mombasa', 'Nyali', -4.0200, 39.7250, 'published', null, null, 'kanga.jpg', 'photo-1520903920243-00d872a2d1c9', '9B2226'],
            ['camera-found', 'found', 'aisha', 'Black compact camera', 'other', 'Found on a bench facing the ocean road.', 'scratch on the lens ring', 'CAM-2044', 'black', 'Canon', 'Moi Avenue, Mombasa', 'Mombasa CBD', -4.0435, 39.6682, 'published', 'nyali', 'Y-B2', 'camera.jpg', 'photo-1516035069371-29a1b244cc32', '0F4C5C'],
            ['collar-lost', 'lost', 'otieno', 'Red dog collar', 'pets', 'Collar only — the dog is home. Lost near Kisumu CBD.', 'bone-shaped tag, name hidden', null, 'red', null, 'Oginga Odinga Street, Kisumu', 'Kisumu', -0.0917, 34.7680, 'published', null, null, 'collar.jpg', 'photo-1587300003388-59208cc962cb', 'E36414'],
            ['racket-found', 'found', 'mercy', 'Tennis racket', 'sports-gear', 'Left at the court next to Thika Town hall.', 'blue overgrip', null, 'black', 'Wilson', 'Thika Town Hall', 'Thika', -1.0333, 37.0693, 'published', null, null, 'racket.jpg', 'photo-1554068865-24cecd4e34b8', '0F4C5C'],
            ['hat-lost', 'lost', 'hassan', 'Brown safari hat', 'clothing', 'Blown off near Lakeview, Nakuru.', 'sweatband has H.J.', null, 'brown', null, 'Lakeview, Nakuru', 'Nakuru', -0.2833, 36.0667, 'published', null, null, 'hat.jpg', 'photo-1521369909029-2afed882baee', 'BC6C25'],
            ['charger-found', 'found', 'kipchoge', 'Laptop charger', 'computers', 'Left on a seat at SGR Nairobi Terminus.', 'tape on the brick', null, 'black', 'Dell', 'SGR Nairobi Terminus, Syokimau', 'Syokimau', -1.3210, 36.8950, 'published', 'sgr', 'G-A1', 'charger.jpg', 'photo-1583863788434-e58a36330cf0', '111827'],
            ['transit-found', 'found', 'hubUser', 'Blue transit card', 'cards', 'Card handed to the station desk. Number not stored.', 'last4 only if claimed', null, 'blue', null, 'Central Station, Nairobi', 'Nairobi CBD', -1.2928, 36.8280, 'published', 'station', 'S-B2', 'card.jpg', 'photo-1556742049-0cfb4d96bd40', '1D4ED8'],
            ['earring-draft', 'lost', 'owner', 'Gold hoop earring', 'jewelry', 'Single hoop, still a draft.', 'tiny notch', null, 'gold', null, 'Food court, City Mall', 'Nairobi CBD', -1.2920, 36.8216, 'draft', null, null, 'earring.jpg', 'photo-1515562149607-ee1ac185bb7e', 'E36414'],
        ];

        $created = [];
        foreach ($rows as $i => $row) {
            [$key, $type, $who, $title, $cat, $desc, $hidden, $serial, $color, $brand, $place, $area, $lat, $lng, $status, $hubKey, $storage, $file, $photo, $hex] = $row;
            $user = $people[$who];
            $hubId = $hubKey ? $hubs[$hubKey]->id : null;
            $report = ItemReport::query()->firstOrCreate(
                ['title' => $title, 'type' => $type, 'place_name' => $place],
                [
                    'user_id' => $user->id,
                    'category_id' => $categories[$cat]->id,
                    'description' => $desc,
                    'hidden_notes' => $hidden,
                    'serial' => $serial,
                    'attributes_json' => array_filter(['color' => $color, 'brand' => $brand]),
                    'lat' => $lat,
                    'lng' => $lng,
                    'geohash' => 'kzf'.Str::lower(Str::random(3)),
                    'area' => $area,
                    'occurred_at' => now()->subDays(($i % 10) + 1)->subHours($i),
                    'status' => $status,
                    'visibility' => $categories[$cat]->sensitivity === 'highly_sensitive' ? 'private_match_only' : 'public_teaser',
                    'custody' => $type === 'found' ? ($hubId ? 'at_hub' : 'with_finder') : null,
                    'hub_id' => $hubId,
                    'storage_code' => $storage,
                    'condition' => $type === 'found' ? 'good' : null,
                ],
            );
            $this->attachPhoto($report, $file, $photo, $title, $hex);
            $created[$key] = $report;
        }

        return $created;
    }

    private function attachPhoto(ItemReport $report, string $filename, string $unsplashId, string $label, string $hex): void
    {
        if ($report->media()->where('visibility', 'public')->exists()) {
            return;
        }

        $path = DemoPhoto::store($filename, $unsplashId, $label, $hex);
        MediaAsset::query()->create([
            'report_id' => $report->id,
            'path' => $path,
            'variant' => 'original',
            'visibility' => 'public',
            'mime' => str_ends_with($path, '.png') ? 'image/png' : 'image/jpeg',
            'size' => \Illuminate\Support\Facades\Storage::disk('public')->size($path),
        ]);
    }

    /**
     * @param  array<string, ItemReport>  $reports
     */
    private function matchesAndClaims(User $owner, User $finder, array $reports): void
    {
        $pairs = [
            ['wallet-lost', 'wallet-found', 90],
            ['keys-lost', 'keys-found', 80],
            ['glasses-lost', 'glasses-found', 75],
        ];

        foreach ($pairs as [$lostKey, $foundKey, $score]) {
            if (! isset($reports[$lostKey], $reports[$foundKey])) {
                continue;
            }
            MatchCandidate::query()->firstOrCreate(
                ['lost_id' => $reports[$lostKey]->id, 'found_id' => $reports[$foundKey]->id],
                ['score' => $score, 'reasons_json' => ['same_category', 'color', 'nearby'], 'status' => 'notified'],
            );
        }

        $foundWallet = $reports['wallet-found'];
        if (! Claim::query()->where('item_report_id', $foundWallet->id)->exists()) {
            $claim1 = Claim::query()->create([
                'item_report_id' => $foundWallet->id,
                'claimant_id' => $owner->id,
                'status' => 'in_review',
                'attempts' => 1,
            ]);
            ClaimAnswer::query()->create([
                'claim_id' => $claim1->id,
                'question_key' => 'mark',
                'question' => 'What initials are inside the wallet?',
                'answer' => 'JK',
            ]);
            $conversation = Conversation::query()->create([
                'claim_id' => $claim1->id,
                'item_report_id' => $foundWallet->id,
                'status' => 'open',
                'flagged' => true,
                'escalated_at' => now(),
            ]);
            $conversation->participants()->sync([$owner->id, $finder->id]);
            Message::query()->create(['conversation_id' => $conversation->id, 'user_id' => $owner->id, 'body' => 'Hi, I think that wallet is mine. I can describe the lining.']);
            Message::query()->create(['conversation_id' => $conversation->id, 'user_id' => $finder->id, 'body' => 'Please wait for the claim review. We will meet at the mall hub.']);
            $foundWallet->update(['status' => 'claim_in_progress']);
        }

        if (isset($reports['keys-found']) && ! Claim::query()->where('item_report_id', $reports['keys-found']->id)->exists()) {
            Claim::query()->create([
                'item_report_id' => $reports['keys-found']->id,
                'claimant_id' => $owner->id,
                'status' => 'submitted',
                'attempts' => 0,
            ]);
        }

        \App\Models\Dispute::query()->firstOrCreate(
            ['item_report_id' => $foundWallet->id, 'type' => 'two_owners'],
            ['notes' => 'Sample dispute for admin review.', 'status' => 'open'],
        );
        \App\Models\Flag::query()->firstOrCreate(
            ['user_id' => $finder->id, 'target_type' => 'item_report', 'target_id' => $reports['wallet-lost']->id],
            ['reason' => 'spam', 'details' => 'Sample flag', 'status' => 'open'],
        );
    }

    private function cms(): void
    {
        $pages = [
            ['terms', 'Terms of use', "Reunite helps people recover lost items. We do not guarantee a return.\nUsers must act in good faith and follow hub rules."],
            ['privacy', 'Privacy policy', "We store report details to match items and verify ownership.\nPublic teasers omit serials, hidden notes, exact coordinates, and contact details."],
            ['guidelines', 'Community guidelines', "No scams, no off-platform payment requests, no missing-person posts.\nThis platform is for items only."],
            ['faq', 'FAQ', "How claiming works: you answer hidden questions, a finder or hub reviews, then handover is arranged.\nNever share your full ID number in chat."],
            ['safety', 'Safety tips', "Prefer hub pickup. Meet in public if you must. Tell a friend. Do not go to private residences."],
        ];

        foreach ($pages as [$slug, $title, $body]) {
            CmsPage::query()->firstOrCreate(['slug' => $slug], ['title' => $title, 'body' => $body, 'published' => true]);
        }
    }

    private function settings(): void
    {
        Setting::setValue('registration_open', true);
        Setting::setValue('guest_browse', true);
        Setting::setValue('match_score_threshold', 60);
        Setting::setValue('claim_attempt_limit', 3);
        Setting::setValue('read_only', false);
        Setting::setValue('maintenance_banner', ['enabled' => false, 'text' => '']);
        Setting::setValue('sso', ['enabled' => false, 'provider' => 'saml', 'note' => 'Phase 3 stub']);
        Setting::setValue('feature_flags', [
            'qr_tags' => true,
            'tips' => true,
            'public_web' => true,
            'id_verification' => true,
            'sso' => false,
            'meilisearch' => false,
        ]);
    }

    private function tags(User $owner, User $finder, User $wanjiku): void
    {
        foreach ([
            ['RNT-BAG-001', $owner->id, 'Red backpack'],
            ['RNT-KEYS-002', $owner->id, 'House keys'],
            ['RNT-CASE-003', $finder->id, 'Laptop sleeve'],
            ['RNT-KIONDO-004', $wanjiku->id, 'Sisal kiondo'],
        ] as [$code, $userId, $label]) {
            QrTag::query()->firstOrCreate(['code' => $code], ['user_id' => $userId, 'item_label' => $label, 'status' => 'active']);
        }
    }

    private function audit(User $admin, ?ItemReport $report): void
    {
        AuditLog::query()->firstOrCreate(
            ['actor_id' => $admin->id, 'action' => 'seed.complete'],
            [
                'subject_type' => $report ? ItemReport::class : null,
                'subject_id' => $report?->id,
                'properties' => ['note' => 'Kenya demo seed'],
                'ip_address' => '127.0.0.1',
                'user_agent' => 'seeder',
            ],
        );
    }
}
