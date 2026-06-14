<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateOtpCodesTable extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id'         => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'email'      => ['type' => 'VARCHAR', 'constraint' => 255, 'null' => false],
            'code'       => ['type' => 'CHAR',    'constraint' => 6,   'null' => false],
            'expires_at' => ['type' => 'DATETIME', 'null' => false],
            'used'       => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 0],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addKey('email');
        $this->forge->createTable('otp_codes', true);
    }

    public function down()
    {
        $this->forge->dropTable('otp_codes', true);
    }
}
