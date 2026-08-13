<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::where('role', 'merchant')->first();
if (!$user) {
    echo "No merchant user found\n";
    exit;
}
echo "User: " . $user->id . "\n";

$request = Illuminate\Http\Request::create('/api/dashboard', 'GET');
$request->setUserResolver(function() use ($user) { return $user; });

$start = microtime(true);
$response = app()->handle($request);
$time = microtime(true) - $start;

echo "Time: " . $time . "s\n";
echo "Response: " . $response->getContent() . "\n";
