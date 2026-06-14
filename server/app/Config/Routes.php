<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// Register UUID route placeholder
$routes->addPlaceholder('uuid', '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');

// ─── API v1 ──────────────────────────────────────────────────────────────────
// All API routes have the CORS filter applied so Android / any HTTP client can
// communicate with this server without origin restrictions.
$routes->group('api/v1', ['namespace' => 'App\Controllers\Api', 'filter' => 'cors'], function ($routes) {

    // ── Auth (public) ──────────────────────────────────────────────────────
    $routes->post('auth/register',   'AuthController::register');
    $routes->post('auth/login',      'AuthController::login');
    $routes->post('auth/verify-otp', 'AuthController::verifyOtp');
    $routes->post('auth/resend-otp', 'AuthController::resendOtp');
    $routes->get('auth/me',          'AuthController::me', ['filter' => 'jwt']);

    // ── Sync (requires JWT) ────────────────────────────────────────────────
    $routes->post('sync', 'SyncController::sync', ['filter' => 'jwt']);

    // ── Accounts (requires JWT) ────────────────────────────────────────────
    $routes->group('accounts', ['filter' => 'jwt'], function ($routes) {
        $routes->get('',              'AccountController::index');
        $routes->post('',             'AccountController::create');
        $routes->get('(:uuid)',     'AccountController::show/$1');
        $routes->put('(:uuid)',     'AccountController::update/$1');
        $routes->delete('(:uuid)', 'AccountController::delete/$1');
    });

    // ── Categories (requires JWT) ──────────────────────────────────────────
    $routes->group('categories', ['filter' => 'jwt'], function ($routes) {
        $routes->get('',              'CategoryController::index');
        $routes->post('',             'CategoryController::create');
        $routes->get('(:uuid)',     'CategoryController::show/$1');
        $routes->put('(:uuid)',     'CategoryController::update/$1');
        $routes->delete('(:uuid)', 'CategoryController::delete/$1');
    });

    // ── Transactions (requires JWT) ────────────────────────────────────────
    $routes->group('transactions', ['filter' => 'jwt'], function ($routes) {
        $routes->get('',              'TransactionController::index');
        $routes->post('',             'TransactionController::create');
        $routes->get('(:uuid)',     'TransactionController::show/$1');
        $routes->put('(:uuid)',     'TransactionController::update/$1');
        $routes->delete('(:uuid)', 'TransactionController::delete/$1');
    });
});
