import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { initFirebaseAdmin } from './common/firebase-admin';

async function bootstrap() {
  initFirebaseAdmin();
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: '*' }); // tighten this before production
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`PetCare backend running on :${port}`);
}
bootstrap();
