const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const email = 'i.meghar.2408@gmail.com';
  const uid = 'kK6oxuxDjvSKwJukkupO5x1lHfi1';
  const name = 'Admin';

  const user = await prisma.user.upsert({
    where: { email },
    update: { 
      role: 'ADMIN',
      firebaseUid: uid,
      name
    },
    create: {
      email,
      firebaseUid: uid,
      name,
      role: 'ADMIN'
    }
  });

  console.log('--- ADMIN RECORD IN DB ---');
  console.log(user);
  console.log('---------------------------');
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
