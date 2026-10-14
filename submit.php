<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, false, 'Only POST requests are accepted.');
}

$name = clean($_POST['name'] ?? '');
$phone = clean($_POST['phone'] ?? '');
$email = filter_var(trim((string)($_POST['email'] ?? '')), FILTER_SANITIZE_EMAIL);
$intent = clean($_POST['intent'] ?? '');
$property = clean($_POST['property'] ?? 'General enquiry');
$message = clean($_POST['message'] ?? '');
$honeypot = trim((string)($_POST['company'] ?? ''));

// Quietly ignore simple bots that fill the hidden field.
if ($honeypot !== '') {
    respond(200, true, 'Thank you. Your enquiry has been received.');
}

if (mb_strlen($name) < 2 || mb_strlen($name) > 100) {
    respond(422, false, 'Please enter your full name.');
}
if (mb_strlen($phone) < 7 || mb_strlen($phone) > 30) {
    respond(422, false, 'Please enter a valid phone number.');
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    respond(422, false, 'Please enter a valid email address.');
}
$allowedIntents = ['buy', 'rent', 'sell', 'invest'];
if (!in_array($intent, $allowedIntents, true)) {
    respond(422, false, 'Please choose how we can help.');
}
if (mb_strlen($message) > 2000) {
    respond(422, false, 'Please keep your message under 2,000 characters.');
}

$dataDir = __DIR__ . DIRECTORY_SEPARATOR . 'data';
if (!is_dir($dataDir) && !mkdir($dataDir, 0750, true) && !is_dir($dataDir)) {
    respond(500, false, 'The enquiry could not be saved right now.');
}

$file = $dataDir . DIRECTORY_SEPARATOR . 'inquiries.csv';
$isNew = !file_exists($file) || filesize($file) === 0;
$handle = fopen($file, 'ab');
if ($handle === false) {
    respond(500, false, 'The enquiry could not be saved right now.');
}

if (!flock($handle, LOCK_EX)) {
    fclose($handle);
    respond(500, false, 'The enquiry could not be saved right now.');
}

if ($isNew) {
    fputcsv($handle, ['submitted_at', 'name', 'phone', 'email', 'intent', 'property', 'message', 'ip']);
}
fputcsv($handle, [date('c'), $name, $phone, $email, $intent, $property, $message, $_SERVER['REMOTE_ADDR'] ?? '']);
flock($handle, LOCK_UN);
fclose($handle);

respond(200, true, 'Thanks — your enquiry is in. A Prime Estate advisor will contact you within one business day.');

function clean(mixed $value): string
{
    $value = trim((string)$value);
    return preg_replace('/[\x00-\x1F\x7F]/u', '', $value) ?? '';
}

function respond(int $status, bool $success, string $message): never
{
    http_response_code($status);
    echo json_encode(['success' => $success, 'message' => $message], JSON_UNESCAPED_UNICODE);
    exit;
}
