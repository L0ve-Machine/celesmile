const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Migration script to hash existing plain-text passwords
async function migratePasswords() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    user: process.env.DB_USER || 'celesmile',
    password: process.env.DB_PASSWORD || 'celesmile123',
    database: process.env.DB_NAME || 'celesmile'
  });

  try {
    console.log('🔄 Starting password migration...');

    // Get all providers
    const [providers] = await connection.query('SELECT id, email, password FROM providers');

    console.log(`📊 Found ${providers.length} providers to migrate`);

    let migrated = 0;
    let skipped = 0;

    for (const provider of providers) {
      // Check if password is already hashed (bcrypt hashes start with $2b$)
      if (provider.password && provider.password.startsWith('$2b$')) {
        console.log(`⏭️  Skipping ${provider.email} - already hashed`);
        skipped++;
        continue;
      }

      // Hash the password
      const hashedPassword = await bcrypt.hash(provider.password, 10);

      // Update the database
      await connection.query(
        'UPDATE providers SET password = ? WHERE id = ?',
        [hashedPassword, provider.id]
      );

      console.log(`✅ Migrated password for ${provider.email}`);
      migrated++;
    }

    console.log('\n📈 Migration Summary:');
    console.log(`   ✅ Migrated: ${migrated}`);
    console.log(`   ⏭️  Skipped: ${skipped}`);
    console.log(`   📊 Total: ${providers.length}`);
    console.log('\n✅ Password migration completed successfully!');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await connection.end();
  }
}

// Run migration
migratePasswords().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
