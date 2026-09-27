const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const [firebaseUid, email, name] = process.argv.slice(2);
  if (!firebaseUid || !email || !name) {
    console.error('Usage: node scripts/make-admin.js <firebaseUid> <email> <name>');
    process.exit(1);
  }
  const user = await prisma.user.upsert({
    where: { firebaseUid },
    update: { role: 'ADMIN' },
    create: { firebaseUid, email, name, role: 'ADMIN' },
  });
  console.log('Admin user ready:', user);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
